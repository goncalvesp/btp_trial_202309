"deferred definition of local test class ('ltc_travel_rw7n')
"so it can be used in the 'friends' addition of lhc_travel (see below)
class ltc_travel_rw7n definition deferred for testing.

"local behavior handler for the 'Travel' entity
class lhc_travel definition inheriting from cl_abap_behavior_handler
  "additionally, set local test class ('ltc_travel_rw7n') as friend of local handler ('lhc_travel')
  "so that the private methods from the local handler can be used in the local test class
  friends ltc_travel_rw7n.
  private section.
    constants:
      begin of travel_status,
        open     type c length 1 value 'O', "Open
        accepted type c length 1 value 'A', "Accepted
        rejected type c length 1 value 'X', "Rejected
      end of travel_status.

    methods:
      get_global_authorizations for global authorization
        importing
        request requested_authorizations for Travel
        result result,

      "Set primary key value instantly after the modify request for the CREATE is executed (i.e.: 'TravelID' is derived on creation)
      createEarlyNumbering for numbering
        importing entities for create Travel, "includes all entities for which keys must be assigned
      "(implicit) changing parameters
      "mapped - used to provide the consumer with ID mapping information
      "failed - used for identifying the data set where an error occurred
      "reported - used to return messages in case of failure

      "Set value of 'Overall Status' when CREATE is executed
      setStatusToOpen for determine on modify
        importing keys for Travel~setStatusToOpen,

      "Instance-bound factory action used to create a new RAP BO entity instance (from an existing entry)
      copyTravel for modify
        importing keys for action Travel~copyTravel,

      "Instance-bound non-factory action used to modify a travel instance's Overall Status to 'Accepted'
      acceptTravel for modify
        importing keys for action Travel~acceptTravel result result,

      "Instance-bound non-factory action used to modify a travel instance's Overall Status to 'Rejected'
      rejectTravel for modify
        importing keys for action Travel~rejectTravel result result,

      "Instance-based dynamic feature control
      get_instance_features for instance features
        "FOR INSTANCE FEATURES after the method name indicates that this method provides the implementation of an instance-based dynamic feature control
        importing keys request requested_features for Travel result result,

      "Instance-bound non-factory action to deduct discount from booking fee, with parameter 'discount_percentage'
      deductDiscount for modify
        importing keys for action Travel~deductDiscount result result,
      "(implicit) changing parameters
      "result - used to store the result of the performed action.

      "Validate Customer ID
      validateCustomer for validate on save
        importing keys for Travel~validateCustomer,

      "Validate Agency ID
      validateAgency for validate on save
        importing keys for Travel~validateAgency,

      "Validate Overall Status
      validateTravelStatus for validate on save
        importing keys for Travel~validateStatus,

      "Validate Begin and End Dates
      validateDates for validate on save
        importing keys for Travel~validateDates.
endclass.

class lhc_travel implementation.
  method get_global_authorizations.
  endmethod.
  "Set primary key value instantly after the modify request for the CREATE is executed (i.e.: 'TravelID' is derived on creation)
  method createEarlyNumbering.
    data:
      entity        type structure for create ZRAP100_R_TravelTP_RW7,
      travel_id_max type /dmo/travel_id.

    "Ensure Travel ID is not set yet (idempotent)- must be checked when BO is draft-enabled
    loop at entities into entity where travel_id is not initial.
      append corresponding #( entity ) to mapped-travel.
    endloop.

    data(entities_wo_travelid) = entities.
    "Remove the entries with an existing Travel ID
    delete entities_wo_travelid where travel_id is not initial.

    "determine the first free travel ID without number range
    "Get max travel ID from active table
    select single from zrap100_atravrw7 fields max( travel_id ) into @travel_id_max. "as TravelID
    "Get max travel ID from draft table
    select single from zrap100_drw7 fields max( travel_id ) into @data(max_travelid_draft).
    if max_travelid_draft > travel_id_max.
      travel_id_max = max_travelid_draft.
    endif.

    "Set Travel ID for new instances w/o ID
    loop at entities_wo_travelid into entity.
      travel_id_max += 1.
      entity-travel_id = travel_id_max.

      append value #( %cid      = entity-%cid
                      %key      = entity-%key
                      %is_draft = entity-%is_draft ) to mapped-travel.
    endloop.
  endmethod.

  "Set value of 'Overall Status' when CREATE is executed
  method setStatusToOpen.
    "read travel instances of the transferred keys
    read entities of ZRAP100_R_TravelTP_RW7
      in local mode "used to exclude feature controls and authorization checks
      entity Travel
        fields ( overall_status )
        with corresponding #( keys )
      result data(travels)
      failed data(read_failed).

    "if overall travel status is already set, do nothing, i.e. remove such instances
    delete travels where overall_status is not initial.
    check travels is not initial.

    "else set overall travel status to open ('O')
    modify entities of ZRAP100_R_TravelTP_RW7 in local mode
      entity travel
        update set fields with value #( for travel in travels ( %tky    = travel-%tky
                                                         overall_status = travel_status-open ) ) reported data(update_reported).

    "set the changing parameter
    reported = corresponding #( deep update_reported ).
  endmethod.

  "Instance-bound factory action used to create a new RAP BO entity instance (from an existing entry)
  method copyTravel.
    data travels type table for create zrap100_r_traveltp_RW7\\travel.

    "remove travel instances with initial %cid (i.e., not set by caller API)
*    read table keys with key %cid = '' into data(key_with_inital_cid).
*    assert key_with_inital_cid is initial.

    "read the data from the travel instances to be copied
    read entities of zrap100_r_traveltp_RW7
      in local mode "used to exclude feature controls and authorization checks
      entity travel
      all fields with corresponding #( keys )
    result data(travel_read_result)
    failed failed.

    loop at travel_read_result assigning field-symbol(<travel>).
      "fill in travel container for creating new travel instance
      append value #( %cid      = keys[ key entity %key = <travel>-%key ]-%cid
                     %is_draft = keys[ key entity %key = <travel>-%key ]-%param-%is_draft
                     %data     = corresponding #( <travel> except travel_id ) ) to travels assigning field-symbol(<new_travel>).

      "adjust the copied travel instance data
      "'begin_date must be on or after system date'
      <new_travel>-begin_date     = cl_abap_context_info=>get_system_date( ).
      "'end_date must be after begin_date'
      <new_travel>-end_date       = cl_abap_context_info=>get_system_date( ) + 30.
      "'overall_status of new instances must be set to open ('O')'
      <new_travel>-overall_status = travel_status-open.
    endloop.

    "create new BO instance
    modify entities of zrap100_r_traveltp_RW7 in local mode
       entity travel
       create fields ( agency_id customer_id begin_date end_date booking_fee
                         total_price currency_code overall_status description )
          with travels
       mapped data(mapped_create).

    "set the new BO instances
    mapped-travel   =  mapped_create-travel .
  endmethod.

  "Instance-bound non-factory action used to modify a travel instance's Overall Status to 'Accepted'
  method acceptTravel.
    "modify travel instance
    modify entities of zrap100_r_traveltp_RW7 in local mode
       entity Travel
       update fields ( overall_status )
       with value #( for key in keys ( %tky          = key-%tky
                                      overall_status = travel_status-accepted ) )  " 'A'
    failed failed
    reported reported.

    "read changed data for action result
    read entities of zrap100_r_traveltp_RW7
       in local mode "used to exclude feature controls and authorization checks
       entity Travel
       all fields with
       corresponding #( keys )
       result data(travels).

    "set the action result parameter
    result = value #( for travel in travels ( %tky   = travel-%tky
                                             %param = travel ) ).
  endmethod.

  "Instance-bound non-factory action used to modify a travel instance's Overall Status to 'Rejected'
  method rejectTravel.
    "modify travel instance(s)
    modify entities of zrap100_r_traveltp_RW7 in local mode
       entity Travel
       update fields ( overall_status )
       with value #( for key in keys ( %tky          = key-%tky
                                      overall_status = travel_status-rejected ) )  " 'X'
    failed failed
    reported reported.

    "read changed data for action result
    read entities of zrap100_r_traveltp_RW7
       in local mode "used to exclude feature controls and authorization checks
       entity Travel
       all fields with
       corresponding #( keys )
       result data(travels).

    "set the action result parameter
    result = value #( for travel in travels ( %tky   = travel-%tky
                                             %param = travel ) ).
  endmethod.

  "Instance-based dynamic feature control
  "Condition: if a travel instance has the overall status 'Accepted' ('A') or Rejected ('X'), then the standard operations update and delete, and the actions Edit and deductDiscount must be disabled for the given instance.
  method get_instance_features.
    "read relevant travel instance data
    read entities of ZRAP100_R_TravelTP_RW7
      in local mode "used to exclude feature controls and authorization checks
      entity travel
        fields ( travel_id overall_status )
        with corresponding #( keys )
      result data(travels)
      failed failed.

    "evaluate the conditions, set the operation state, and set result parameter
    result = value #( for travel in travels
                      ( %tky                   = travel-%tky
*                       "enable buttons and actions if the overall status is Open (O)
                        %action-acceptTravel   = cond #( when travel-overall_status = travel_status-open
                                                           then if_abap_behv=>fc-o-enabled else if_abap_behv=>fc-o-disabled   )
                        %action-rejectTravel   = cond #( when travel-overall_status = travel_status-open
                                                           then if_abap_behv=>fc-o-enabled else if_abap_behv=>fc-o-disabled   )
                        %action-deductDiscount = cond #( when travel-overall_status = travel_status-open
                                                           then if_abap_behv=>fc-o-enabled else if_abap_behv=>fc-o-disabled   )
                        %action-Edit           = cond #( when travel-overall_status = travel_status-open
                                                           then if_abap_behv=>fc-o-enabled else if_abap_behv=>fc-o-disabled   )
                        %delete                = cond #( when travel-overall_status = travel_status-open
                                                           then if_abap_behv=>fc-o-enabled else if_abap_behv=>fc-o-disabled   )
                        %update                = cond #( when travel-overall_status = travel_status-open
                                                           then if_abap_behv=>fc-o-enabled else if_abap_behv=>fc-o-disabled   )
                        "enable 'Accept Travel' if Overall Status is 'Rejected'
*                       %action-acceptTravel   = cond #( when travel-overall_status = travel_status-rejected
*                                                           then if_abap_behv=>fc-o-enabled else if_abap_behv=>fc-o-disabled   )
*                       "enable 'Reject Travel' if Overall Status is 'Accepted'
*                       %action-rejectTravel   = cond #( when travel-overall_status = travel_status-accepted
*                                                          then if_abap_behv=>fc-o-enabled else if_abap_behv=>fc-o-disabled   )

                     ) ).
  endmethod.

  "Instance-bound non-factory action to deduct discount from booking fee, with parameter 'discount_percentage'
  method deductDiscount.

    data travels_for_update type table for update ZRAP100_R_TravelTP_RW7.
    data(keys_with_valid_discount) = keys.

    "check and handle invalid discount values
    loop at keys_with_valid_discount assigning field-symbol(<key_with_valid_discount>)
      where %param-discount_percent is initial or %param-discount_percent > 100 or %param-discount_percent <= 0.

      "report invalid discount value appropriately
      append value #( %tky                       = <key_with_valid_discount>-%tky ) to failed-travel.

      append value #( %tky                       = <key_with_valid_discount>-%tky
                      %msg                       = new /dmo/cm_flight_messages(
                                                     textid = /dmo/cm_flight_messages=>discount_invalid
                                                     severity = if_abap_behv_message=>severity-error )
                      %element-total_price        = if_abap_behv=>mk-on
                      %op-%action-deductDiscount = if_abap_behv=>mk-on ) to reported-travel.

      "remove invalid discount value
      delete keys_with_valid_discount.
    endloop.

    "check and go ahead with valid discount values
    check keys_with_valid_discount is not initial.

    "read relevant travel instance data (only booking fee)
    read entities of ZRAP100_R_TravelTP_RW7
      in local mode "used to exclude feature controls and authorization checks
      entity Travel
        fields ( booking_fee )
        with corresponding #( keys_with_valid_discount )
      result data(travels).

    loop at travels assigning field-symbol(<travel>).
      data percentage type decfloat16.
      data(discount_percent) = keys_with_valid_discount[ key draft %tky = <travel>-%tky ]-%param-discount_percent.
      percentage =  discount_percent / 100 .
      data(reduced_fee) = <travel>-booking_fee * ( 1 - percentage ) .

      append value #( %tky       = <travel>-%tky
                      booking_fee = reduced_fee ) to travels_for_update.
    endloop.

    "update data with reduced fee
    modify entities of ZRAP100_R_TravelTP_RW7 in local mode
      entity Travel
        update fields ( booking_fee )
        with travels_for_update.

    "read changed data for action result
    read entities of ZRAP100_R_TravelTP_RW7 in local mode
      entity Travel
        all fields with
        corresponding #( travels )
      result data(travels_with_discount).

    "set action result
    result = value #( for travel in travels_with_discount ( %tky   = travel-%tky
                                                            %param = travel ) ).
  endmethod.

  method validateCustomer.
    "read relevant travel instance data
    read entities of ZRAP100_R_TravelTP_RW7
    in local mode "used to exclude feature controls and authorization checks
    entity Travel
      fields ( customer_id )
      with corresponding #( keys )
    result data(travels).

    data customers type sorted table of /dmo/customer with unique key customer_id.

    "optimization of DB select: extract distinct non-initial customer IDs
    customers = corresponding #( travels discarding duplicates mapping customer_id = customer_id except * ).
    delete customers where customer_id is initial.

    if customers is not initial.
      "check if Customer ID exists in CDS View ('/dmo/i_customer')
      select from /dmo/i_customer fields CustomerID
        for all entries in @customers
        where CustomerID = @customers-customer_id
        into table @data(valid_customers).
    endif.

*    "clear REPORTED and FAILED tables not working --> multiple error messages if the same wrong input is provided?
*    clear reported-travel.
*    clear failed-travel.

    "raise message for non existing and initial customer id
    loop at travels into data(travel).
*      append value #(  %tky                 = travel-%tky
*                       "state-messages are used for reporting problems
*                       %state_area          = 'VALIDATE_CUSTOMER' ) to reported-travel.

      if travel-customer_id is  initial.
        append value #( %tky = travel-%tky ) to failed-travel.
        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = new /dmo/cm_flight_messages(
                                                textid   = /dmo/cm_flight_messages=>enter_customer_id "show consumer the message 'Enter a Customer ID'
                                                severity = if_abap_behv_message=>severity-error )
                        %element-customer_id = if_abap_behv=>mk-on ) to reported-travel.

      elseif travel-customer_id is not initial and not line_exists( valid_customers[ CustomerID = travel-customer_id ] ).
        append value #(  %tky = travel-%tky ) to failed-travel.
        append value #(  %tky                = travel-%tky
                         %state_area         = 'VALIDATE_CUSTOMER'
                         %msg                = new /dmo/cm_flight_messages(
                                                 customer_id = travel-customer_id
                                                 textid      = /dmo/cm_flight_messages=>customer_unkown "show consumer the message 'Customer X is unknown'
                                                 severity    = if_abap_behv_message=>severity-error )
                         %element-customer_id = if_abap_behv=>mk-on ) to reported-travel.
      endif.
    endloop.
  endmethod.

  method validateAgency.

    "read relevant travel instance data
    read entities of ZRAP100_R_TravelTP_RW7
    in local mode "used to exclude feature controls and authorization checks
    entity travel
     fields ( agency_id )
     with corresponding #(  keys )
    result data(travels).

    data agencies type sorted table of /dmo/agency with unique key agency_id.

    "optimization of DB select: extract distinct non-initial  agency IDs
    agencies = corresponding #(  travels discarding duplicates mapping agency_id = agency_id except * ).
    delete agencies where agency_id is initial.
    if  agencies is not initial.

      "check if agency ID exist
      select from /dmo/i_agency fields AgencyID
        for all entries in @agencies
        where AgencyID = @agencies-agency_id
        into table @data(valid_agencies).
    endif.

    "raise message for non existing and initial agency id
    loop at travels into data(travel).
*      append value #(  %tky                 = travel-%tky
*                       "state-messages are used for reporting problems
*                       %state_area          = 'VALIDATE_AGENCY' ) to reported-travel.

      if travel-agency_id is  initial.
        append value #( %tky = travel-%tky ) to failed-travel.
        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = new /dmo/cm_flight_messages(
                                                textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                severity = if_abap_behv_message=>severity-error )
                        %element-agency_id = if_abap_behv=>mk-on ) to reported-travel.

      elseif travel-agency_id is not initial and not line_exists( valid_agencies[ AgencyID = travel-agency_id ] ).
        append value #(  %tky = travel-%tky ) to failed-travel.
        append value #(  %tky                = travel-%tky
                         %state_area         = 'VALIDATE_AGENCY'
                         %msg                = new /dmo/cm_flight_messages(
                                                 agency_id   = travel-agency_id
                                                 textid      = /dmo/cm_flight_messages=>agency_unkown
                                                 severity    = if_abap_behv_message=>severity-error )
                         %element-agency_id = if_abap_behv=>mk-on ) to reported-travel.
      endif.
    endloop.

  endmethod.

  method validateTravelStatus.
    read entities of ZRAP100_R_TravelTP_RW7
      in local mode "used to exclude feature controls and authorization checks
      entity travel
        fields ( overall_status )
        with corresponding #( keys )
      result data(travels).

    loop at travels into data(travel).
      case travel-overall_status.
        when 'O'.  " Open
        when 'X'.  " Cancelled
        when 'A'.  " Accepted

        when others.
          append value #(  %tky = travel-%tky ) to failed-travel.
          append value #(  %tky                = travel-%tky
                           %state_area         = 'VALIDATE_STATUS'
                           %msg                = new /dmo/cm_flight_messages(
                                                   textid      = /dmo/cm_flight_messages=>status_invalid
                                                   severity    = if_abap_behv_message=>severity-error
                                                   status      = travel-overall_status )
                           %element-overall_status = if_abap_behv=>mk-on ) to reported-travel.
      endcase.

    endloop.
  endmethod.

  method validateDates.
    read entities of ZRAP100_R_TravelTP_RW7
      in local mode "used to exclude feature controls and authorization checks
      entity Travel
        fields (  begin_date end_date travel_id )
        with corresponding #( keys )
      result data(travels).

    loop at travels into data(travel).
*      append value #(  %tky               = travel-%tky
*                       %state_area        = 'VALIDATE_DATES' ) to reported-travel.

      if travel-begin_date is initial.
        append value #( %tky = travel-%tky ) to failed-travel.
        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = new /dmo/cm_flight_messages(
                                               textid   = /dmo/cm_flight_messages=>enter_begin_date
                                               severity = if_abap_behv_message=>severity-error )
                      %element-begin_date = if_abap_behv=>mk-on ) to reported-travel.
      endif.

      if travel-begin_date < cl_abap_context_info=>get_system_date( ) and travel-begin_date is not initial.
        append value #( %tky               = travel-%tky ) to failed-travel.
        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = new /dmo/cm_flight_messages(
                                               begin_date = travel-begin_date
                                               textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                               severity   = if_abap_behv_message=>severity-error )
                        %element-begin_date = if_abap_behv=>mk-on ) to reported-travel.
      endif.

      if travel-end_date is initial.
        append value #( %tky = travel-%tky ) to failed-travel.
        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg                = new /dmo/cm_flight_messages(
                                                 textid   = /dmo/cm_flight_messages=>enter_end_date
                                                 severity = if_abap_behv_message=>severity-error )
                        %element-end_date   = if_abap_behv=>mk-on ) to reported-travel.
      endif.

      if travel-end_date < travel-begin_date and travel-begin_date is not initial and travel-end_date is not initial.
        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = new /dmo/cm_flight_messages(
                                               textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                               begin_date = travel-begin_date
                                               end_date   = travel-end_date
                                               severity   = if_abap_behv_message=>severity-error )
                        %element-begin_date = if_abap_behv=>mk-on
                        %element-end_date   = if_abap_behv=>mk-on ) to reported-travel.
      endif.
    endloop.
  endmethod.
endclass.
