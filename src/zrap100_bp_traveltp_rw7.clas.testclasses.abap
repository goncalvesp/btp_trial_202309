**********************************************************************************************************************
* Unit Tests for Behavior Implementation
*
* Unit tests test the smallest functional units of an application.
* When accessing a business object from a consumer's perspective, e.g. via EML (Entity Manipulation Language),
* a series of methods can be called by the framework.
* For instance, an EML MODIFY CREATE statement does not only trigger the create method,
* but also all determinations, validations, feature control and authorization implementations.
*
* Therefore, in order to limit the scope of a test to single method, unit tests will not act from a consumer's
* perspective, but they will instantiate the class under test (CUT) and then call the methods to be tested directly.
* This prevents the impact from other methods (like validations) and allows focus on the one really want to test.
***********************************************************************************************************************

"The tested methods are private methods (of 'lhc_travel').
"Since you will want to call the methods in order to test them, you need to set the test class ltc_managed as a friend of the local handler class lhc_travel

"local test class ('ltc_travel_rw7n') is set as friend of local handler ('lhc_travel') of 'zrap100_bp_traveltp_rw7'
"so that the private methods from the local handler can be used in the local test class
class zrap100_bp_traveltp_rw7 definition local friends ltc_travel_rw7n.

"the special ABAP Doc comment below means that every ABAP Unit tests implemented in this local test class
"can be executed from the behavior definition ZRAP100_R_TravelTP_RW7
"(by selecting "Run As ABAP Unit Test" in Project Explorer -> ZRAP100_R_TravelTP_RW7)

"! @testing BDEF:ZRAP100_R_TravelTP_RW7
class ltc_travel_rw7n definition final
  for testing duration short risk level harmless.

  private section.
    class-data: class_under_test     type ref to lhc_travel,
                cds_test_environment type ref to if_cds_test_environment,
                sql_test_environment type ref to if_osql_test_environment.

    class-methods:
      "! Instantiate class under test and setup test double frameworks
      class_setup,

      "! Destroy test environments and test doubles
      class_teardown.

    methods:
      "! Reset test doubles
      setup,

      "! Reset transactional buffer
      teardown,

      "! Check creation's early numbering with a single empty entry
      createNumbering_empty   for testing,
      "! Check creation's early numbering with multiple empty entries
      createNumbering_multipleEmpty   for testing,
      "! Check creation with valid Travel ID
      createNumbering_existing   for testing,
      "! Check creation with both an empty and a valid Travel ID
      createNumbering_mixed   for testing,

      "! Check determination 'setStatusToOpen' on create (with a valid Travel ID)
      determineStatus_create for testing, "not implemented, 'reported' is not changed

      "! Check instance with valid Customer ID
      validateCustomer_valid   for testing,
      "! Check instance with initial Customer ID
      validateCustomer_initial for testing,
      "! Check instance with invalid Customer ID
      validateCustomer_invalid for testing,

      "! Check instance with Overall Status 'Open'
      validateTravelStatus_open for testing,
      "! Check instance with Overall Status 'Accepted'
      validateTravelStatus_accepted for testing,
      "! Check instance with Overall Status 'Rejected'
      validateTravelStatus_rejected for testing,
      "! Check instance with invalid Overall Status
      validateTravelStatus_invalid for testing,

      "! Check instance with a valid Agency ID
      validateAgency_valid   for testing,
      "! Check instance with an initial value for Agency ID
      validateAgency_initial   for testing,
      "! Check instance with an invalid Agency ID
      validateAgency_invalid   for testing,

      "! Check instance with a valid pair of Begin and End Dates
      validateDates_valid for testing,
      "! Check instance with an initial values for Begin and End Date
      validatedates_initial for testing,
      "! Check instance with invalid values for Begin and End Date
      validatedates_invalid for testing,

      "! Check returned features for instance with Overall Status 'Open'
      checkFeatures_open for testing,
      "! Check returned features for instance with Overall Status 'Accepted'
      checkFeatures_accepted      for testing,
      "! Check returned features for instance with Overall Status 'Rejected'
      checkFeatures_rejected      for testing,
      "! Check returned features for instance with invalid Overall Status
      checkFeatures_invalidstatus for testing,
      "! Check returned features for instance with invalid key
      checkFeatures_invalidkey    for testing,

*      "! Check acceptTravel action
*      checkCopy for testing, "not possible without EML?
      "! Check acceptTravel action
      checkAccept for testing,
      "! Check rejectTravel action
      checkReject for testing,
      "! Check deductDiscount action
      checkDeduct_valid for testing.

endclass.


class ltc_travel_rw7n implementation.

  method class_setup.
    create object class_under_test for testing.
    "create the test doubles for the underlying CDS entity
    cds_test_environment = cl_cds_test_environment=>create( i_for_entity = 'ZRAP100_R_TravelTP_RW7' ).
    "create test doubles for additional used tables.
*    sql_test_environment = cl_osql_test_environment=>create( i_dependency_list = value #( ( '/DMO/CUSTOMER' ) ) ).
    sql_test_environment = cl_osql_test_environment=>create(
      i_dependency_list = value #( ( '/DMO/AGENCY' )
                                   ( '/DMO/CUSTOMER' ) ) ).
*                                   ( '/DMO/CARRIER' )
*                                   ( '/DMO/FLIGHT' ) ) ).
  endmethod.

  method setup.
    cds_test_environment->clear_doubles( ).
    sql_test_environment->clear_doubles( ).
  endmethod.

  method teardown.
    rollback entities.
  endmethod.

  method class_teardown.
    cds_test_environment->destroy( ).
    sql_test_environment->destroy( ).
  endmethod.

  method createNumbering_empty.
    "If the travel ID is not available in the test double, then one must be derived and assigned.

    "create travel instance with a single empty entry
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed early ZRAP100_R_TravelTP_RW7.
    data mapped type response for mapped early ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->createEarlyNumbering( "derive TravelID for empty entry
      exporting
        entities = corresponding #( travel_mock_data )
      changing
        mapped   = mapped
        failed   = failed
    ).

    "check number of returned instances in failed-travel (expected to be empty)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 0 ).
    "check number of returned instances in mapped-travel (expected to have 1 line, for the created travel instance)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in mapped-travel' act = lines( mapped-travel ) exp = 1 ).
    "check value of returned instance in mapped-travel (expected to have one travel instance with derived TravelID)
    cl_abap_unit_assert=>assert_not_initial( msg = 'travel-id in mapped-travel' act = mapped-travel[ 1 ]-travel_id ).
  endmethod.

  method createNumbering_multipleEmpty.
    "If the travel IDs are not available in the test doubles, then they must be derived and assigned separately.

    "create travel instance with multiple empty entries
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '' ) ( travel_id = '' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed early ZRAP100_R_TravelTP_RW7.
    data mapped type response for mapped early ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->createEarlyNumbering( "derive unique TravelIDs for empty entries
      exporting
        entities = corresponding #( travel_mock_data )
      changing
        mapped   = mapped
        failed   = failed
    ).

    "check number of returned instances in failed-travel (expected to be empty)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 0 ).
    "check number of returned instances in mapped-travel (expected to have 1 line, for the created travel instance)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in mapped-travel' act = lines( mapped-travel ) exp = 2 ).
    "check value of returned instance in mapped-travel (expected to have one travel instance with derived TravelID)
    cl_abap_unit_assert=>assert_not_initial( msg = 'travel-id in mapped-travel' act = mapped-travel[ 1 ]-travel_id ).
    "check value of returned instance in mapped-travel (expected to have one travel instance with derived TravelID)
    cl_abap_unit_assert=>assert_not_initial( msg = 'travel-id in mapped-travel' act = mapped-travel[ 2 ]-travel_id ).
    "compare the TravelID values from each created instance and check if they differ
    "( mapped-travel[ 2 ]-travel_id should be one value higher than mapped-travel[ 1 ]-travel_id )
    cl_abap_unit_assert=>assert_differs( msg = 'different travel-id values in mapped-travel' act = mapped-travel[ 1 ]-travel_id  exp = mapped-travel[ 2 ]-travel_id  ).
  endmethod.

  method createNumbering_existing.
    "If a fitting travel ID is passed in the test double, then nothing needs to be derived and assigned

    "create travel instance with an entry with a valid TravelID already assigned
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed early ZRAP100_R_TravelTP_RW7.
    data mapped type response for mapped early ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->createEarlyNumbering( "derive TravelID for empty entry
      exporting
        entities = corresponding #( travel_mock_data )
      changing
        mapped   = mapped
        failed   = failed
    ).

    "check number of returned instances in failed-travel (expected to be empty)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 0 ).
    "check number of returned instances in mapped-travel (expected to have 1 line, for the created travel instance)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in mapped-travel' act = lines( mapped-travel ) exp = 1 ).
    "check value of returned instance in mapped-travel (expected to have one travel instance with untouched TravelID, meaning equal to the one in mock data)
    cl_abap_unit_assert=>assert_equals( msg = 'travel-id in mapped-travel' act = mapped-travel[ 1 ]-travel_id exp = travel_mock_data[ 1 ]-travel_id ).
  endmethod.

  method createNumbering_mixed.
    "If a fitting travel ID is passed in the test double, then nothing needs to be derived and assigned

    "create travel instance with an entry with a valid TravelID already assigned
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' ) ( travel_id = '' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed early ZRAP100_R_TravelTP_RW7.
    data mapped type response for mapped early ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->createEarlyNumbering( "derive TravelID for empty entry
      exporting
        entities = corresponding #( travel_mock_data )
      changing
        mapped   = mapped
        failed   = failed
    ).

    "check number of returned instances in failed-travel (expected to be empty)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 0 ).
    "check number of returned instances in mapped-travel (expected to have 1 line, for the created travel instance)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in mapped-travel' act = lines( mapped-travel ) exp = 2 ).
    "check value of the first returned instance in mapped-travel (expected to have the travel instance with TravelID assigned from mock data)
    cl_abap_unit_assert=>assert_equals( msg = 'travel-id in mapped-travel' act = mapped-travel[ 1 ]-travel_id exp = travel_mock_data[ 1 ]-travel_id ).
    "check value of returned instance in mapped-travel (expected to have one travel instance with derived TravelID)
    cl_abap_unit_assert=>assert_not_initial( msg = 'travel-id in mapped-travel' act = mapped-travel[ 2 ]-travel_id ).
    "compare the TravelID values from each created instance and check if they differ
    "( mapped-travel[ 2 ]-travel_id should be diffent from mapped-travel[ 1 ]-travel_id )
    cl_abap_unit_assert=>assert_differs( msg = 'different travel-id values in mapped-travel' act = mapped-travel[ 1 ]-travel_id  exp = mapped-travel[ 2 ]-travel_id  ).
  endmethod.

  method determineStatus_create.
*    "create travel instance without Overall Status in the test double.
*    data travel_mock_data type standard table of zrap100_atravrw7.
*    travel_mock_data = value #( ( travel_id = '99' ) ).
*    cds_test_environment->insert_test_data( travel_mock_data ).
*
*    "declare required structure for return parameter 'reported'
*    data reported type response for reported late ZRAP100_R_TravelTP_RW7.
*
*    "call private method of CUT to be tested
*    class_under_test->setStatusToOpen(
*      exporting
*        keys     = corresponding #( travel_mock_data )
*      changing
*        reported = reported "not getting filled (neither from the test class execution nor the test app)
*    ).
*
*    "check expected content of 'reported' structure (expected to contain one entry)
*    cl_abap_unit_assert=>assert_equals( msg = 'lines in reported-travel' act = lines( reported-travel ) exp = 1 ).
*    "check travel status value in reported-travel (expected to be 'O' for 'Open')
*    cl_abap_unit_assert=>assert_equals( msg = 'travel status in reported-travel' act = reported-travel[ 1 ]-%element-overall_status exp = 'O' ).

  endmethod.

  method validateCustomer_valid.
    "create travel instance with CustomerID '665' (which exists with name 'Madeira')
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' customer_id = '665' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "create test doubles for additional 'Customer' table
    data customer_mock_data type standard table of /dmo/customer.
    customer_mock_data = value #(  (  customer_id = '665' ) ).
    sql_test_environment->insert_test_data( customer_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateCustomer(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "CL_ABAP_UNIT_ASSERT is used in test method implementations to check/assert the test assumptions.
    "It offers various static methods for those purposes - e.g. assert_equals(), assert_initial(), assert_not_initial(), etc.

    "check expected content of 'failed' and 'reported' structures (expected to be empty/initial)
    cl_abap_unit_assert=>assert_initial( msg = 'failed'   act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).
  endmethod.

  method validateCustomer_initial.
    "create travel instance with CustomerID '' (initial)
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' customer_id = '' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "no need to create test doubles for additional 'Customer' table
*    data customer_mock_data type standard table of /dmo/customer.
*    customer_mock_data = value #(  (  customer_id = '' ) ).
*    sql_test_environment->insert_test_data( customer_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateCustomer(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check number of returned instances in failed-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 1 ).
    "check travel id in failed-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in failed-travel' act = failed-travel[ 1 ]-travel_id exp = '99' ).


    "check number of returned instances in reported-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in reported-travel' act = lines( reported-travel ) exp = 1 ).
    "check travel id in reported-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in reported-travel' act = reported-travel[ 1 ]-travel_id  exp = '99' ).
    "check error element in reported-travel (expected to be field 'customer_id')
    cl_abap_unit_assert=>assert_equals( msg = 'field customer id in reported-travel' act = reported-travel[ 1 ]-%element-customer_id  exp = if_abap_behv=>mk-on ).
    "check for a message reference in reported-travel
    cl_abap_unit_assert=>assert_bound(  msg = 'message reference in reported-travel' act = reported-travel[ 1 ]-%msg ).

  endmethod.

  method validateCustomer_invalid.
    "create travel instance with CustomerID '999' (which does not exist, at the moment)
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' customer_id = '999' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "create test doubles for additional 'Customer' table
    data customer_mock_data type standard table of /dmo/customer.
    customer_mock_data = value #(  (  customer_id = '999' ) ).
    sql_test_environment->insert_test_data( customer_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateCustomer(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check number of returned instances in failed-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 1 ).
    "check travel id in failed-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in failed-travel' act = failed-travel[ 1 ]-travel_id exp = '99' ).


    "check number of returned instances in reported-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in reported-travel' act = lines( reported-travel ) exp = 1 ).
    "check travel id in reported-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in reported-travel' act = reported-travel[ 1 ]-travel_id  exp = '99' ).
    "check error element in reported-travel (expected to be field 'customer_id')
    cl_abap_unit_assert=>assert_equals( msg = 'field customer id in reported-travel' act = reported-travel[ 1 ]-%element-customer_id  exp = if_abap_behv=>mk-on ).
    "check for a message reference in reported-travel
    cl_abap_unit_assert=>assert_bound(  msg = 'message reference in reported-travel' act = reported-travel[ 1 ]-%msg ).
  endmethod.

  method validateTravelStatus_open.
    "create travel instance with Overall Status 'O' (meaning 'Open') for the overall status to the test double.
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'O' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late  ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateTravelStatus(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check expected content of 'failed' and 'reported' structures (expected to be empty)
    cl_abap_unit_assert=>assert_initial( msg = 'failed' act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).
  endmethod.

  method validateTravelStatus_accepted.
    "create travel instance with Overall Status 'A' (meaning 'Accepted') for the overall status to the test double.
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'A' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateTravelStatus(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check expected content of 'failed' and 'reported' structures (expected to be empty)
    cl_abap_unit_assert=>assert_initial( msg = 'failed' act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).
  endmethod.

  method validateTravelStatus_rejected.
    "create travel instance with Overall Status 'X' (meaning 'Rejected') for the overall status to the test double.
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'X' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateTravelStatus(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check expected content of 'failed' and 'reported' structures (expected to be empty)
    cl_abap_unit_assert=>assert_initial( msg = 'failed' act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).
  endmethod.

  method validateTravelStatus_invalid.
    "create travel instance with Overall Status 'Z' (which does not match any of the valid options)
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'Z' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late  ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateTravelStatus(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check number of returned instances in failed-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 1 ).
    "check travel id in failed-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in failed-travel' act = failed-travel[ 1 ]-travel_id exp = '99' ).


    "check number of returned instances in reported-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in reported-travel' act = lines( reported-travel ) exp = 1 ).
    "check travel id in reported-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in reported-travel' act = reported-travel[ 1 ]-travel_id  exp = '99' ).
    "check error element in reported-travel (expected to be field 'overall_status')
    cl_abap_unit_assert=>assert_equals( msg = 'field customer id in reported-travel' act = reported-travel[ 1 ]-%element-overall_status  exp = if_abap_behv=>mk-on ).
    "check for a message reference in reported-travel
    cl_abap_unit_assert=>assert_bound(  msg = 'message reference in reported-travel' act = reported-travel[ 1 ]-%msg ).
  endmethod.

  method validateAgency_valid.
    "create travel instance with AgencyID '70026' (which exists with name 'No Name')
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' agency_id = '70026' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "create test doubles for additional 'Customer' table
    data agency_mock_data type standard table of /dmo/agency.
    agency_mock_data = value #(  (  agency_id = '70026' ) ).
    sql_test_environment->insert_test_data( agency_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateAgency(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check expected content of 'failed' and 'reported' structures (expected to be empty/initial)
    cl_abap_unit_assert=>assert_initial( msg = 'failed'   act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).
  endmethod.

  method validateAgency_initial.
    "create travel instance with an empty AgencyID value
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' agency_id = '' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

*    "create test doubles for additional 'Customer' table
*    data agency_mock_data type standard table of /dmo/agency.
*    agency_mock_data = value #(  (  agency_id = '' ) ).
*    sql_test_environment->insert_test_data( agency_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateAgency(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check number of returned instances in failed-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 1 ).
    "check travel id in failed-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in failed-travel' act = failed-travel[ 1 ]-travel_id exp = '99' ).


    "check number of returned instances in reported-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in reported-travel' act = lines( reported-travel ) exp = 1 ).
    "check travel id in reported-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in reported-travel' act = reported-travel[ 1 ]-travel_id  exp = '99' ).
    "check error element in reported-travel (expected to be field 'agency_id')
    cl_abap_unit_assert=>assert_equals( msg = 'field agency id in reported-travel' act = reported-travel[ 1 ]-%element-agency_id  exp = if_abap_behv=>mk-on ).
    "check for a message reference in reported-travel
    cl_abap_unit_assert=>assert_bound(  msg = 'message reference in reported-travel' act = reported-travel[ 1 ]-%msg ).
  endmethod.

  method validateAgency_invalid.
    "create travel instance with an invalid AgencyID '99999'
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' agency_id = '99999' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "create test doubles for additional 'Customer' table
    data agency_mock_data type standard table of /dmo/agency.
    agency_mock_data = value #(  (  agency_id = '99999' ) ).
    sql_test_environment->insert_test_data( agency_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateAgency(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check number of returned instances in failed-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 1 ).
    "check travel id in failed-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in failed-travel' act = failed-travel[ 1 ]-travel_id exp = '99' ).


    "check number of returned instances in reported-travel (expected to be 1 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in reported-travel' act = lines( reported-travel ) exp = 1 ).
    "check travel id in reported-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in reported-travel' act = reported-travel[ 1 ]-travel_id  exp = '99' ).
    "check error element in reported-travel (expected to be field 'agency_id')
    cl_abap_unit_assert=>assert_equals( msg = 'field agency id in reported-travel' act = reported-travel[ 1 ]-%element-agency_id  exp = if_abap_behv=>mk-on ).
    "check for a message reference in reported-travel
    cl_abap_unit_assert=>assert_bound(  msg = 'message reference in reported-travel' act = reported-travel[ 1 ]-%msg ).
  endmethod.

  method validatedates_valid.
    "Test validation for valid values on both 'Begin Date' and 'End Date'

    data: valid_begin type /dmo/begin_date,
          valid_end type /dmo/end_date.

    valid_begin = cl_abap_context_info=>get_system_date( ).      "valid 'Begin Date' values start on the current date or the future
    valid_end   = cl_abap_context_info=>get_system_date( ) + 14. "valid 'End Date' values start on the current date or the future

    "create travel instance with valid 'Begin Date' and 'End Date' values
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' begin_date = valid_begin end_date = valid_end ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateDates(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check expected content of 'failed' and 'reported' structures (expected to be empty/initial)
    cl_abap_unit_assert=>assert_initial( msg = 'failed'   act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).
  endmethod.

  method validatedates_initial.
    "Test initial values for both 'Begin Date' and 'End Date'

    "create travel instance with initial values on 'Begin Date' and 'End Date'
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' begin_date = '00000000' end_date = '00000000' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateDates(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check number of returned instances in failed-travel (expected to be 2 lines)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 2 ).
    "check travel id in failed-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in failed-travel' act = failed-travel[ 1 ]-travel_id exp = '99' ).

    "check number of returned instances in reported-travel (expected to be 2 line)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in reported-travel' act = lines( reported-travel ) exp = 2 ).
    "check travel id in reported-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in reported-travel' act = reported-travel[ 1 ]-travel_id  exp = '99' ).
    "check error element in reported-travel (expected to be field 'begin_date')
    cl_abap_unit_assert=>assert_equals( msg = 'field begin date in reported-travel' act = reported-travel[ 1 ]-%element-begin_date  exp = if_abap_behv=>mk-on ).
    "check error element in reported-travel (expected to be field 'end_date')
    cl_abap_unit_assert=>assert_equals( msg = 'field end date in reported-travel' act = reported-travel[ 2 ]-%element-end_date  exp = if_abap_behv=>mk-on ).

    "check the error message class matches the one used in the validation ('/DMO/CM_FLIGHT')
    cl_abap_unit_assert=>assert_equals( msg = 'message class used in reported-travel' exp = '/DMO/CM_FLIGHT' act = reported-travel[ 1 ]-%msg->if_t100_message~t100key-msgid ).
    "check the error messages match the correct error entries ('Enter Begin Date')
    cl_abap_unit_assert=>assert_equals( msg = 'message number in reported-travel for begin_date' exp = 007 act = reported-travel[ 1 ]-%msg->if_t100_message~t100key-msgno ).
    "check the error messages match the correct error entries ('Enter End Date')
    cl_abap_unit_assert=>assert_equals( msg = 'message number in reported-travel for end_date' exp = 008 act = reported-travel[ 2 ]-%msg->if_t100_message~t100key-msgno ).
  endmethod.

  method validatedates_invalid.
    "Test invalid values for both 'Begin Date' and 'End Date'

    "variables with invalid values for this application
    data: invalid_begin type /dmo/begin_date,
          invalid_end type /dmo/end_date.

    invalid_begin = cl_abap_context_info=>get_system_date( ) - 10.
    invalid_end   = cl_abap_context_info=>get_system_date( ) - 30.

    "create travel instance with valid Begin and End Dates
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' begin_date = invalid_begin end_date = invalid_end ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data failed type response for failed late ZRAP100_R_TravelTP_RW7.
    data reported type response for reported late ZRAP100_R_TravelTP_RW7.

    "call private method of CUT to be tested
    class_under_test->validateDates(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        failed   = failed
        reported = reported
    ).

    "check number of returned instances in failed-travel (expected to be 2 lines)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 2 ).
    "check travel id in failed-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in failed-travel' act = failed-travel[ 1 ]-travel_id exp = '99' ).


    "check number of returned instances in reported-travel (expected to be 2 lines)
    cl_abap_unit_assert=>assert_equals( msg = 'lines in reported-travel' act = lines( reported-travel ) exp = 2 ).
    "check travel id in reported-travel (expected to be ID = '99')
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in reported-travel' act = reported-travel[ 1 ]-travel_id  exp = '99' ).
    "check error element in reported-travel (expected to be field 'begin_date')
    cl_abap_unit_assert=>assert_equals( msg = 'field begin date in reported-travel' act = reported-travel[ 1 ]-%element-begin_date  exp = if_abap_behv=>mk-on ).
    "check error element in reported-travel (expected to be field 'end_date')
    cl_abap_unit_assert=>assert_equals( msg = 'field end date in reported-travel' act = reported-travel[ 2 ]-%element-end_date  exp = if_abap_behv=>mk-on ).

    "check the error message class matches the one used in the validation ('/DMO/CM_FLIGHT')
    cl_abap_unit_assert=>assert_equals( msg = 'message class used in reported-travel' exp = '/DMO/CM_FLIGHT' act = reported-travel[ 1 ]-%msg->if_t100_message~t100key-msgid ).
    "check the error messages match the correct error entries ('Begin Date must be after system date')
    cl_abap_unit_assert=>assert_equals( msg = 'message number in reported-travel for begin_date' exp = 004 act = reported-travel[ 1 ]-%msg->if_t100_message~t100key-msgno ).
    "check the error messages match the correct error entries ('Begin Date must be after End Date')
    cl_abap_unit_assert=>assert_equals( msg = 'message number in reported-travel for end_date' exp = 003 act = reported-travel[ 2 ]-%msg->if_t100_message~t100key-msgno ).
  endmethod.

  "Instance-based dynamic feature control
  method checkFeatures_open.
    "If a travel instance has Overall Status 'Open', then all standard operations (update and delete)
    "as well as the actions 'deductDiscount', 'acceptTravel' and 'rejectTravel' must be enabled for the given instance.

    "create travel instance with Overall Status 'O' (meaning 'Open') for the test double
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'O' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data:
      failed   type response for failed early ZRAP100_R_TravelTP_RW7,
      reported type response for reported early ZRAP100_R_TravelTP_RW7,
      result   type table for instance features result ZRAP100_R_TravelTP_RW7\\Travel.

    "call private method of CUT to be tested
    class_under_test->get_instance_features(
      exporting
        keys               = corresponding #( travel_mock_data )
        requested_features = value #(  %action-acceptTravel     = if_abap_behv=>mk-on
                                       %action-rejectTravel     = if_abap_behv=>mk-on
                                       %action-deductDiscount   = if_abap_behv=>mk-on
                                       %action-Edit             = if_abap_behv=>mk-on
                                       %delete                  = if_abap_behv=>mk-on
                                       %update                  = if_abap_behv=>mk-on )
*       %assoc-_Booking    = if_abap_behv=>mk-on )
      changing
        result             = result
        failed             = failed
        reported           = reported
    ).

    "check result
    data expected like result.
    expected  = value #( ( travel_id              = '99'
                           %action-acceptTravel   = if_abap_behv=>fc-o-enabled
                           %action-rejectTravel   = if_abap_behv=>fc-o-enabled
                           %action-Edit           = if_abap_behv=>fc-o-enabled
                           %features-%update      = if_abap_behv=>fc-o-enabled
                           %features-%delete      = if_abap_behv=>fc-o-enabled ) ).

    cl_abap_unit_assert=>assert_equals( msg = 'result' exp = expected act = result ).
  endmethod.

  method checkFeatures_accepted.
    "If a travel instance has Overall Status 'Accepted', then all standard operations (update and delete)
    "as well as the actions 'deductDiscount', 'acceptTravel' and 'rejectTravel' must be disabled for the given instance.

    "create travel instance with the overall_status = 'A' (meaning 'Accepted') for the test double
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'A' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data:
      failed   type response for failed early ZRAP100_R_TravelTP_RW7,
      reported type response for reported early ZRAP100_R_TravelTP_RW7,
      result   type table for instance features result ZRAP100_R_TravelTP_RW7\\Travel.

    "call private method of CUT to be tested
    class_under_test->get_instance_features(
      exporting
        keys               = corresponding #( travel_mock_data )
        requested_features = value #(  %action-acceptTravel     = if_abap_behv=>mk-on
                                       %action-rejectTravel     = if_abap_behv=>mk-on
                                       %action-deductDiscount   = if_abap_behv=>mk-on
                                       %action-Edit             = if_abap_behv=>mk-on
                                       %delete                  = if_abap_behv=>mk-on
                                       %update                  = if_abap_behv=>mk-on )
      changing
        result             = result
        failed             = failed
        reported           = reported
    ).

    "check result
    data expected like result.
    expected  = value #( ( travel_id              = '99'
                           %action-acceptTravel   = if_abap_behv=>fc-o-disabled
                           %action-rejectTravel   = if_abap_behv=>fc-o-disabled
                           %action-deductDiscount = if_abap_behv=>fc-o-disabled
                           %action-Edit           = if_abap_behv=>fc-o-disabled
                           %features-%delete      = if_abap_behv=>fc-o-disabled
                           %features-%update      = if_abap_behv=>fc-o-disabled ) ).

    cl_abap_unit_assert=>assert_equals( msg = 'result' exp = expected act = result ).
  endmethod.

  method checkFeatures_invalidstatus.
    "If a travel instance has an invalid Overall Status, then all standard operations (update and delete)
    "as well as the actions 'deductDiscount', 'acceptTravel' and 'rejectTravel' must be disabled for the given instance.

    "create travel instance with the overall_status = 'A' (meaning 'Accepted') for the test double
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'Z' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data:
      failed   type response for failed early ZRAP100_R_TravelTP_RW7,
      reported type response for reported early ZRAP100_R_TravelTP_RW7,
      result   type table for instance features result ZRAP100_R_TravelTP_RW7\\Travel.

    "call private method of CUT to be tested
    class_under_test->get_instance_features(
      exporting
        keys               = corresponding #( travel_mock_data )
        requested_features = value #(  %update                  = if_abap_behv=>mk-on
                                       %delete                  = if_abap_behv=>mk-on
                                       %action-Edit             = if_abap_behv=>mk-on
                                       %action-deductDiscount   = if_abap_behv=>mk-on
                                       %action-acceptTravel     = if_abap_behv=>mk-on
                                       %action-rejectTravel     = if_abap_behv=>mk-on )
      changing
        result             = result
        failed             = failed
        reported           = reported
    ).

    "check result
    data expected like result.
    expected  = value #( ( travel_id              = '99'
                           %features-%update      = if_abap_behv=>fc-o-disabled
                           %features-%delete      = if_abap_behv=>fc-o-disabled
                           %action-Edit           = if_abap_behv=>fc-o-disabled
                           %action-deductDiscount = if_abap_behv=>fc-o-disabled
                           %action-acceptTravel   = if_abap_behv=>fc-o-disabled
                           %action-rejectTravel   = if_abap_behv=>fc-o-disabled ) ).

    cl_abap_unit_assert=>assert_equals( msg = 'result' exp = expected act = result ).
  endmethod.

  method checkFeatures_rejected.
    "If a travel instance has Overall Status 'X' (meaning 'Rejected'), then all standard operations (update and delete)
    "as well as the actions 'deductDiscount', 'acceptTravel' and 'rejectTravel' must be disabled for the given instance.

    "create travel instance with the overall_status = 'X' (meaning 'Rejected') for the test double
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'X' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters 'failed' and 'reported'
    data:
      failed   type response for failed early ZRAP100_R_TravelTP_RW7,
      reported type response for reported early ZRAP100_R_TravelTP_RW7,
      result   type table for instance features result ZRAP100_R_TravelTP_RW7\\Travel.

    "call private method of CUT to be tested
    class_under_test->get_instance_features(
      exporting
        keys               = corresponding #( travel_mock_data )
        requested_features = value #(  %update                  = if_abap_behv=>mk-on
                                       %delete                  = if_abap_behv=>mk-on
                                       %action-Edit             = if_abap_behv=>mk-on
                                       %action-deductDiscount   = if_abap_behv=>mk-on
                                       %action-acceptTravel     = if_abap_behv=>mk-on
                                       %action-rejectTravel     = if_abap_behv=>mk-on )
      changing
        result             = result
        failed             = failed
        reported           = reported
    ).

    "check result
    data expected like result.
    expected  = value #( ( travel_id              = '99'
                           %features-%update      = if_abap_behv=>fc-o-disabled
                           %features-%delete      = if_abap_behv=>fc-o-disabled
                           %action-Edit           = if_abap_behv=>fc-o-disabled
                           %action-deductDiscount = if_abap_behv=>fc-o-disabled
                           %action-acceptTravel   = if_abap_behv=>fc-o-disabled
                           %action-rejectTravel   = if_abap_behv=>fc-o-disabled ) ).

    cl_abap_unit_assert=>assert_equals( msg = 'result' exp = expected act = result ).
  endmethod.

  method checkFeatures_invalidkey.
    "If the travel ID is not available in the test double, then all standard operations (update and delete)
    "as well as the actions 'deductDiscount', 'acceptTravel' and 'rejectTravel' must be disabled for the given instance.

    "declare required structures for return parameters 'failed' and 'reported'
    data:
      failed   type response for failed early ZRAP100_R_TravelTP_RW7,
      reported type response for reported early ZRAP100_R_TravelTP_RW7,
      result   type table for instance features result ZRAP100_R_TravelTP_RW7\\Travel.

    "call private method of CUT to be tested (without  keys)
    class_under_test->get_instance_features(
      exporting
        keys               = value #( ( travel_id = '99' ) )
        requested_features = value #(  %update                  = if_abap_behv=>mk-on
                                       %delete                  = if_abap_behv=>mk-on
                                       %action-Edit             = if_abap_behv=>mk-on
                                       %action-deductDiscount   = if_abap_behv=>mk-on
                                       %action-acceptTravel     = if_abap_behv=>mk-on
                                       %action-rejectTravel     = if_abap_behv=>mk-on )
      changing
        result             = result
        failed             = failed
        reported           = reported
    ).

    "check number of returned instances in failed-travel
    cl_abap_unit_assert=>assert_equals( msg = 'lines in failed-travel' act = lines( failed-travel ) exp = 1 ).
    "check travel id in failed-travel
    cl_abap_unit_assert=>assert_equals( msg = 'travel id in failed-travel' act = failed-travel[ 1 ]-travel_id exp = '99' ).
    "check fail-cause in failed-travel
    cl_abap_unit_assert=>assert_equals( msg = 'fail-cause in failed-travel' act = failed-travel[ 1 ]-%fail-cause exp = if_abap_behv=>cause-not_found ).
  endmethod.

  method checkAccept.
    "Test the 'acceptTravel' method, with 5 travel instances, with various Overall Statuses.

    "add 5 travel instance to the test double
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '91' overall_status = 'O' )
                                ( travel_id = '92' overall_status = 'A' )
                                ( travel_id = '93' overall_status = 'X' )
                                ( travel_id = '94' overall_status = 'Z' )
                                ( travel_id = '95' overall_status = '' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters
    data:
      failed   type response for failed early ZRAP100_R_TravelTP_RW7,
      reported type response for reported early ZRAP100_R_TravelTP_RW7,
      mapped   type response for mapped early ZRAP100_R_TravelTP_RW7,
      result   type table for action result ZRAP100_R_TravelTP_RW7\\Travel~acceptTravel.

    "call the method to be tested
    class_under_test->acceptTravel(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        result   = result
        mapped   = mapped
        failed   = failed
        reported = reported
    ).

    "check for content in mapped, failed and reported
    cl_abap_unit_assert=>assert_initial( msg = 'mapped'   act = mapped ).
    cl_abap_unit_assert=>assert_initial( msg = 'failed'   act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).

    "check action result for fields of interest: travel_id, %param-travel_id, %param-overall_status.
    data exp like result.
    exp = value #(  ( travel_id = 91 %param-travel_id = '91' %param-overall_status = 'A' )
                    ( travel_id = 92 %param-travel_id = '92' %param-overall_status = 'A' )
                    ( travel_id = 93 %param-travel_id = '93' %param-overall_status = 'A' )
                    ( travel_id = 94 %param-travel_id = '94' %param-overall_status = 'A' )
                    ( travel_id = 95 %param-travel_id = '95' %param-overall_status = 'A' ) ).

    data act like result.
    act = corresponding #( result mapping travel_id = travel_id
                                       (  %param = %param mapping travel_id = travel_id
                                                                  overall_status = overall_status
                                                                  except * )
                                          except * ).
    cl_abap_unit_assert=>assert_equals( msg = 'action result' exp = exp act = act ).


    " Additionally check modified instances
    read entity zrap100_r_traveltp_RW7
      fields ( travel_id overall_status ) with corresponding #( travel_mock_data )
      result data(read_result).

    act = value #( for t in read_result ( travel_id = t-travel_id
                                          %param-travel_id = t-travel_id
                                          %param-overall_status = t-overall_status ) ).
    cl_abap_unit_assert=>assert_equals( msg = 'read result' exp = exp act = act ).
  endmethod.

  method checkReject.
    "Test the 'rejectTravel' method, with 5 travel instances, with various Overall Statuses.
    "This test is performed without feature control checks, so it can effect changes to all statuses (not just 'Open')

    "add 5 travel instance to the test double
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '91' overall_status = 'O' )
                                ( travel_id = '92' overall_status = 'A' )
                                ( travel_id = '93' overall_status = 'X' )
                                ( travel_id = '94' overall_status = 'Z' )
                                ( travel_id = '95' overall_status = '' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters
    data:
      failed   type response for failed early ZRAP100_R_TravelTP_RW7,
      reported type response for reported early ZRAP100_R_TravelTP_RW7,
      mapped   type response for mapped early ZRAP100_R_TravelTP_RW7,
      result   type table for action result ZRAP100_R_TravelTP_RW7\\Travel~rejectTravel.

    "call the method to be tested
    class_under_test->rejectTravel(
      exporting
        keys     = corresponding #( travel_mock_data )
      changing
        result   = result
        mapped   = mapped
        failed   = failed
        reported = reported
    ).

    "check for content in mapped, failed and reported
    cl_abap_unit_assert=>assert_initial( msg = 'mapped'   act = mapped ).
    cl_abap_unit_assert=>assert_initial( msg = 'failed'   act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).

    "check action result for fields of interest: travel_id, %param-travel_id, %param-overall_status.
    data exp like result.
    exp = value #(  ( travel_id = 91 %param-travel_id = '91' %param-overall_status = 'X' )
                    ( travel_id = 92 %param-travel_id = '92' %param-overall_status = 'X' )
                    ( travel_id = 93 %param-travel_id = '93' %param-overall_status = 'X' )
                    ( travel_id = 94 %param-travel_id = '94' %param-overall_status = 'X' )
                    ( travel_id = 95 %param-travel_id = '95' %param-overall_status = 'X' ) ).

    data act like result.
    act = corresponding #( result mapping travel_id = travel_id
                                       (  %param = %param mapping travel_id = travel_id
                                                                  overall_status = overall_status
                                                                  except * )
                                          except * ).
    cl_abap_unit_assert=>assert_equals( msg = 'action result' exp = exp act = act ).


    " Additionally check modified instances
    read entity zrap100_r_traveltp_RW7
      fields ( travel_id overall_status ) with corresponding #( travel_mock_data )
      result data(read_result).

    act = value #( for t in read_result ( travel_id = t-travel_id
                                          %param-travel_id = t-travel_id
                                          %param-overall_status = t-overall_status ) ).
    cl_abap_unit_assert=>assert_equals( msg = 'read result' exp = exp act = act ).
  endmethod.

  method checkDeduct_valid.
    "Test the 'deductDiscount' method, with a valid input for the discount (10%).

    "add a travel instance to the test double
    data travel_mock_data type standard table of zrap100_atravrw7.
    travel_mock_data = value #( ( travel_id = '99' overall_status = 'O' booking_fee = '10' ) ).
    cds_test_environment->insert_test_data( travel_mock_data ).

    "declare required structures for return parameters
    data:
      keys     type table for action import zrap100_r_traveltp_rw7\\travel~deductdiscount,
      failed   type response for failed early ZRAP100_R_TravelTP_RW7,
      reported type response for reported early ZRAP100_R_TravelTP_RW7,
      mapped   type response for mapped early ZRAP100_R_TravelTP_RW7,
      result   type table for action result ZRAP100_R_TravelTP_RW7\\Travel~deductDiscount.

    keys = value #( ( travel_id = '99' %param-discount_percent = 10 ) ).

    "call the method to be tested
    class_under_test->deductDiscount(
      exporting
        keys     = corresponding #( keys )
      changing
        result   = result
        mapped   = mapped
        failed   = failed
        reported = reported
    ).

    "check for content in mapped, failed and reported
    cl_abap_unit_assert=>assert_initial( msg = 'mapped'   act = mapped ).
    cl_abap_unit_assert=>assert_initial( msg = 'failed'   act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).

    "check action result for fields of interest: travel_id, %param-travel_id, %param-overall_status.
    data exp like result.
    exp = value #(  ( travel_id = 99 %param-travel_id = '99' %param-overall_status = 'O' %param-booking_fee = 9 ) ).

    data act like result.
    act = corresponding #( result mapping travel_id = travel_id
                                       (  %param = %param mapping travel_id = travel_id
                                                                  overall_status = overall_status
                                                                  booking_fee = booking_fee
                                                                  except * )
                                          except * ).
    cl_abap_unit_assert=>assert_equals( msg = 'action result' exp = exp act = act ).


    " Additionally check modified instances
    read entity zrap100_r_traveltp_RW7
      fields ( travel_id overall_status ) with corresponding #( travel_mock_data )
      result data(read_result).

    act = value #( for t in read_result ( travel_id = t-travel_id
                                          %param-travel_id = t-travel_id
                                          %param-overall_status = t-overall_status
                                          %param-booking_fee = t-booking_fee ) ).
    cl_abap_unit_assert=>assert_equals( msg = 'read result' exp = exp act = act ).
  endmethod.

*  method checkcopy.
**    "Test the 'copyTravel' method, with an existing travel instance
*     "(not possible without EML?)
*  endmethod.

endclass.
