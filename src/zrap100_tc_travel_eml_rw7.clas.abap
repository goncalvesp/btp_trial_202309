**********************************************************************************************************************
* Integration Tests
* Whereas unit tests operate within a BO to validate each functional unit of a particular RAP artefact,
* integration tests work outside of BOs and validate consumption use cases via EML (Entity Manipulation Language)
* and OData, where multiple functional units are involved.
*
* Reading/creating instances from outside, make use of the whole RAP application and involve dependent operations, such as determinations and validations.
* Integration tests validate the consumption result and show whether the interaction between the involved functional units works as expected.
**********************************************************************************************************************

"the special ABAP Doc comment below means that every ABAP Unit tests implemented in this test class
"can be executed from the behavior definition ZRAP100_R_TravelTP_RW7
"(by selecting "Run As ABAP Unit Test" in Project Explorer -> ZRAP100_R_TravelTP_RW7)
"! @testing BDEF:ZRAP100_R_TravelTP_RW7
class zrap100_tc_travel_eml_rw7 definition public final create public
  for testing risk level harmless duration short.

  public section.

  protected section.

  private section.
    class-data:
      "'cds_test_environment' is the reference object for the CDS TDF (if_cds_test_environment) which is used to provide test doubles for the travel CDS entity of the base BO view
      "the CDS test doubles will be used for read operations.
      cds_test_environment type ref to if_cds_test_environment,
      "'sql_test_environment' is the reference object for the ABAP SQL TDF (if_osql_test_environment) is used for stubbing the additional needed database tables.
      "The database test doubles will be used for write operations.
      sql_test_environment type ref to if_osql_test_environment,
      agency_mock_data     type standard table of /dmo/agency,
      customer_mock_data   type standard table of /dmo/customer,
      lv_begin_date        type /dmo/begin_date,
      lv_end_date          type /dmo/end_date.

    constants: c_id          type abp_behv_cid          value 'ROOT1',
               "cid_node     type abp_behv_cid          value 'NODE1',
               "cid_subnode  type abp_behv_cid          value 'SUBNODE1',
               c_description type /dmo/description      value 'Test Travel',
               c_totalprice  type /dmo/total_price      value 1100,
               c_bookingfee  type /dmo/booking_fee      value 10,
               c_discount    type zrap100_rw7n_discount value 20,
               c_currcode    type /dmo/currency_code    value 'EUR'.

    class-methods:
      class_setup,    "setup test double framework (executed once before all tests of the class)
      class_teardown. "stop test doubles (executed once after all tests of the test class are executed)
    methods:
      setup,          "reset test doubles (executed before each individual test or before each execution of a test method)
      teardown.       "rollback any changes (executed after each individual test or after each execution of a test method)

    methods:
      "create a complete Travel instance passing all validations
      create_valid for testing raising cx_static_check,
      "create a complete Travel instance with actions 'Accept Travel' and 'Deduct Discount'
      createActions_acpt_ddct for testing raising cx_static_check,
      "create a complete Travel instance with actions 'Accept Travel' and 'Deduct Discount'
      createActions_rjct_ddct for testing raising cx_static_check,


      "create with validation of Begin/End dates with invalid input
      createValidateDates_invalid for testing raising cx_static_check.

endclass.

class zrap100_tc_travel_eml_rw7 implementation.
  method class_setup.

*    "create the test doubles for the underlying CDS entity
*    cds_test_environment = cl_cds_test_environment=>create( i_for_entity = 'ZRAP100_R_TravelTP_RW7' ).

    "create the test doubles for the underlying CDS entities
    cds_test_environment = cl_cds_test_environment=>create_for_multiple_cds(
                                                      i_for_entities = value #(
                                                        ( i_for_entity = 'ZRAP100_R_TravelTP_RW7' ) ) ).

    "create test doubles for additional used tables
    sql_test_environment = cl_osql_test_environment=>create(
      i_dependency_list = value #( ( '/DMO/AGENCY' )
                                   ( '/DMO/CUSTOMER' ) ) ).

    agency_mock_data   = value #( ( agency_id = '070041' name = 'Agency 070041' ) ).
    customer_mock_data = value #( ( customer_id = '000093' last_name = 'Customer 000093' ) ).
  endmethod.

  method class_teardown.
    "remove test doubles
    cds_test_environment->destroy(  ).
    sql_test_environment->destroy(  ).
  endmethod.

  method setup.
    "clear the test doubles per test
    cds_test_environment->clear_doubles(  ).
    sql_test_environment->clear_doubles(  ).
    "insert test data into test doubles
    sql_test_environment->insert_test_data( agency_mock_data   ).
    sql_test_environment->insert_test_data( customer_mock_data ).
  endmethod.

  method teardown.
    "clean up any involved entity
    rollback entities.
  endmethod.

  method create_valid.
    "This integration test will create a complete Travel instance, which will trigger and test the following:
    "1. Early numbering (handled by the method 'createEarlyNumbering')
    "2. Determination for field 'Overall Status' (handled by the method 'setStatusToOpen')
    "3. Validations for the fields:
    "'Begin Date' and 'End Date' (by triggering validation 'validateDates')
    "'Customer ID' (by triggering validation 'validateCustomer')
    "'Agency ID' (by triggering validation 'validateAgency')
    "'Overall Status' (by triggering validation 'validateStatus')

    "set valid 'Begin Date' and 'End Date' values
    lv_begin_date = cl_abap_context_info=>get_system_date( ) + 1.
    lv_end_date = lv_begin_date + 15.

    "create a Travel
    modify entities of ZRAP100_R_TravelTP_RW7
      entity travel
        create fields ( agency_id customer_id begin_date end_date description total_price booking_fee currency_code )
          with value #( (  %cid = c_id
                           agency_id      = agency_mock_data[ 1 ]-agency_id
                           customer_id    = customer_mock_data[ 1 ]-customer_id
                           begin_date     = lv_begin_date
                           end_date       = lv_end_date
                           description    = c_description
                           total_price    = c_totalprice
                           booking_fee    = c_bookingfee
                           currency_code  = c_currcode ) )
     mapped data(mapped)
     failed data(failed_create)
     reported data(reported_create).

    "CL_ABAP_UNIT_ASSERT is used in test method implementations to check/assert the test assumptions.
    "It offers various static methods for the purposes - e.g. assert_equals(), assert_initial(), assert_not_initial(), and assert_differs().

    "check successful creation of new Travel entry (also checks that early numbering was triggered and executed successfully)
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( mapped-travel ) ).
    "check key values of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = c_id act = mapped-travel[ 1 ]-%cid ).
    cl_abap_unit_assert=>assert_not_initial( act = mapped-travel[ 1 ]-travel_id ).
    "check return parameters 'failed' and 'reported' (expected to be empty)
    cl_abap_unit_assert=>assert_initial( act = failed_create ).
    cl_abap_unit_assert=>assert_initial( act = reported_create ).

    "trigger Travel instance's own validations
    commit entities
      response of ZRAP100_R_TravelTP_RW7
      failed data(failed_commit)
      reported data(reported_commit).

    "check that commit executed successfully
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).
    "check expected content of 'failed' parameter (expected to be empty)
    cl_abap_unit_assert=>assert_equals( act = lines( failed_commit-travel ) exp = 0 ).
    "check expected content of 'reported' parameter (expected to be empty)
    cl_abap_unit_assert=>assert_equals( act = lines( reported_commit-travel ) exp = 0 ).
  endmethod.

  method createActions_acpt_ddct.
    "This test will create a Travel instance and execute actions 'acceptTravel' and 'deductDiscount'

    "set valid 'Begin Date' and 'End Date' values
    lv_begin_date = cl_abap_context_info=>get_system_date( ) + 1.
    lv_end_date = lv_begin_date + 15.

    "create a complete Travel instance
    modify entities of ZRAP100_R_TravelTP_RW7
      entity Travel
        create fields ( agency_id customer_id begin_date end_date description total_price booking_fee currency_code )
          with value #( (  %cid = c_id
                           agency_id      = agency_mock_data[ 1 ]-agency_id
                           customer_id    = customer_mock_data[ 1 ]-customer_id
                           begin_date     = lv_begin_date
                           end_date       = lv_end_date
                           description    = c_description
                           total_price    = c_totalprice
                           booking_fee    = c_bookingfee
                           currency_code  = c_currcode
                        ) )

      "execute action 'acceptTravel'
      entity Travel
        execute acceptTravel
          from value #( ( %cid_ref = c_id ) )

      "execute action 'deductDiscount' with input parameter 'discount_percent'
      entity Travel
        execute deductDiscount
          from value #( ( %cid_ref = c_id
                          %param-discount_percent = c_discount ) )

    "result parameters
    mapped   data(mapped_create)
    failed   data(failed_create)
    reported data(reported_create).

    "read action result
    read entities of ZRAP100_R_TravelTP_RW7
     entity travel
       fields ( overall_status booking_fee )
       with value #( ( travel_id = mapped_create-travel[ 1 ]-%tky-travel_id ) )
      result data(result)
      failed data(failed_read).

    "check successful creation of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( mapped_create-travel ) ).
    "check key values of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = c_id act = mapped_create-travel[ 1 ]-%cid ).
    cl_abap_unit_assert=>assert_not_initial( act = mapped_create-travel[ 1 ]-travel_id ).
    "check return parameters 'failed' and 'reported' from the modify 'entities' EML statement (expected to be empty)
    cl_abap_unit_assert=>assert_initial( act = failed_create ).
    cl_abap_unit_assert=>assert_initial( act = reported_create ).

    "check 'read' EML statement was executed successfully (expected to be empty)
    cl_abap_unit_assert=>assert_initial( failed_read ).
    "check actions 'Accepted Travel' and 'Deduct Discount' were executed successfully
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( result ) ).               "result parameter contains the new Travel entry
    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-overall_status exp = 'A'  ). "Overall Status set to 'Accepted'
    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-booking_fee exp = '8'  ).    "Booking Fee discounted from '10' to '8'.

    "persist changes into the database (commit using the test doubles)
    "and trigger Travel instance's own validations
    commit entities responses
      failed   data(commit_failed)
      reported data(commit_reported).

    "expect no failures and messages (i.e.: return parameters 'commit_failed' and 'commit_reported'  are initial)
    cl_abap_unit_assert=>assert_initial( msg = 'commit_failed'   act = commit_failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'commit_reported' act = commit_reported ).
  endmethod.

  method createActions_rjct_ddct.
    "This test will create a Travel instance and execute actions 'Reject Travel' and 'Deduct Discount'

    "set valid 'Begin Date' and 'End Date' values
    lv_begin_date = cl_abap_context_info=>get_system_date( ) + 1.
    lv_end_date = lv_begin_date + 15.

    "create a complete Travel instance
    modify entities of ZRAP100_R_TravelTP_RW7
      entity Travel
        create fields ( agency_id customer_id begin_date end_date description total_price booking_fee currency_code )
          with value #( (  %cid = c_id
                           agency_id      = agency_mock_data[ 1 ]-agency_id
                           customer_id    = customer_mock_data[ 1 ]-customer_id
                           begin_date     = lv_begin_date
                           end_date       = lv_end_date
                           description    = c_description
                           total_price    = '1100'
                           booking_fee    = c_bookingfee
                           currency_code  = c_currcode
                        ) )

      "execute action 'acceptTravel'
      entity Travel
        execute rejectTravel
          from value #( ( %cid_ref = c_id ) )

      "execute action 'deductDiscount' with 20% discount
      entity Travel
        execute deductDiscount
          from value #( ( %cid_ref = c_id
                          %param-discount_percent = c_discount ) )

    "result parameters
    mapped   data(mapped_create)
    failed   data(failed_create)
    reported data(reported_create).

    "read action result
    read entities of ZRAP100_R_TravelTP_RW7
      entity travel
        fields ( overall_status booking_fee )
        with value #( ( travel_id = mapped_create-travel[ 1 ]-%tky-travel_id ) )
    result data(result)
    failed data(failed_read).

    "check successful creation of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( mapped_create-travel ) ).
    "check key values of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = c_id act = mapped_create-travel[ 1 ]-%cid ).
    cl_abap_unit_assert=>assert_not_initial( act = mapped_create-travel[ 1 ]-travel_id ).
    "check return parameters 'failed' and 'reported' from the modify 'entities' EML statement (expected to be empty)
    cl_abap_unit_assert=>assert_initial( act = failed_create ).
    cl_abap_unit_assert=>assert_initial( act = reported_create ).

    "check 'read' EML statement was executed successfully (expected to be empty)
    cl_abap_unit_assert=>assert_initial( failed_read ).
    "check actions 'Accepted Travel' and 'Deduct Discount' were executed successfully
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( result ) ).               "result parameter contains the new Travel entry
    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-overall_status exp = 'X'  ). "Overall Status set to 'Rejected'
    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-booking_fee exp = '8'  ).    "Booking Fee discounted from '10' to '8'.

    "persist changes into the database (commit using the test doubles)
    "and trigger Travel instance's own validations
    commit entities responses
      failed   data(commit_failed)
      reported data(commit_reported).

    "expect no failures and messages (i.e.: return parameters 'commit_failed' and 'commit_reported'  are initial)
    cl_abap_unit_assert=>assert_initial( msg = 'commit_failed'   act = commit_failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'commit_reported' act = commit_reported ).
  endmethod.

  method createValidateDates_invalid.
    "This test creates a Travel instance and validates invalid values for the fields 'Begin Date' and 'End Date'

    "set invalid 'Begin Date' and 'End Date' values
    lv_begin_date = cl_abap_context_info=>get_system_date( ) - 10. "invalid 'Begin Date' because it is before the current system date
    lv_end_date   = cl_abap_context_info=>get_system_date( ) - 30. "invalid 'End Date' because it is before 'Begin Date'

    "create a Travel with invalid begin_date
    modify entities of ZRAP100_R_TravelTP_RW7
      entity travel
        create fields ( agency_id customer_id begin_date end_date description booking_fee currency_code )
          with value #( (  %cid = c_id
                           agency_id      = agency_mock_data[ 1 ]-agency_id
                           customer_id    = customer_mock_data[ 1 ]-customer_id
                           begin_date     = lv_begin_date
                           end_date       = lv_end_date
                           description    = c_description
                           booking_fee    = c_bookingfee
                           currency_code  = c_currcode ) )
     mapped data(mapped_create)
     failed data(failed_create)
     reported data(reported_create).

    "check successful creation of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( mapped_create-travel ) ).
    "check key values of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = c_id act = mapped_create-travel[ 1 ]-%cid ).
    cl_abap_unit_assert=>assert_not_initial( act = mapped_create-travel[ 1 ]-travel_id ).

    cl_abap_unit_assert=>assert_initial( act = failed_create ).
    cl_abap_unit_assert=>assert_initial( act = reported_create ).

    "trigger Travel instance's own validations
    commit entities
      response of ZRAP100_R_TravelTP_RW7
      failed data(failed_commit)
      reported data(reported_commit).

    "commit failed as begin_date and end_date values are invalid
    cl_abap_unit_assert=>assert_subrc( exp = 4 ).
    "check expected content of 'failed' parameter (expected to have 2 lines, one for each invalid date field)
    cl_abap_unit_assert=>assert_equals( act = lines( failed_commit-travel ) exp = 2 ).
    "check expected content of the TravelID value within the 'failed' parameter (expected to have a new TravelID)
    cl_abap_unit_assert=>assert_not_initial( act = failed_commit-travel[ 1 ]-travel_id ).
    "check expected content of the TravelID value within the 'failed' parameter (expected to have the same value in both entries)
    cl_abap_unit_assert=>assert_equals( act = failed_commit-travel[ 2 ]-travel_id exp = failed_commit-travel[ 1 ]-travel_id ).

    "check expected content of 'reported' parameter (expected to have 2 lines, one for each invalid date field)
    cl_abap_unit_assert=>assert_equals( act = lines( reported_commit-travel ) exp = 2 ).
    "check expected content of the TravelID value within the 'reported' parameter (expected to have the new TravelID)
    cl_abap_unit_assert=>assert_not_initial( act = reported_commit-travel[ 1 ]-travel_id ).
    "check expected content of the TravelID value within the 'reported' parameter (expected to have the same value in both entries)
    cl_abap_unit_assert=>assert_equals( act = reported_commit-travel[ 2 ]-travel_id exp = reported_commit-travel[ 1 ]-travel_id ).
    "check error element in reported-travel (expected to be field 'begin_date')
    cl_abap_unit_assert=>assert_equals( act = reported_commit-travel[ 1 ]-%element-begin_date  exp = if_abap_behv=>mk-on ).
    "check error element in reported-travel (expected to be field 'end_date')
    cl_abap_unit_assert=>assert_equals( act = reported_commit-travel[ 2 ]-%element-end_date  exp = if_abap_behv=>mk-on ).

    "check the error message class matches the one used in the validation ('/DMO/CM_FLIGHT')
    cl_abap_unit_assert=>assert_equals( exp = '/DMO/CM_FLIGHT' act = reported_commit-travel[ 1 ]-%msg->if_t100_message~t100key-msgid ).
    "check the error messages match the correct error entries ('Begin Date must be after system date')
    cl_abap_unit_assert=>assert_equals( exp = 004 act = reported_commit-travel[ 1 ]-%msg->if_t100_message~t100key-msgno ).
    "check the error messages match the correct error entries ('End Date must be after Begin Date')
    cl_abap_unit_assert=>assert_equals( exp = 003 act = reported_commit-travel[ 2 ]-%msg->if_t100_message~t100key-msgno ).
  endmethod.



endclass.
