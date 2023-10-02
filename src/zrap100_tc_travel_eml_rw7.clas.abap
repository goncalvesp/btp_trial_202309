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
      customer_mock_data   type standard table of /dmo/customer.

    constants cid         type abp_behv_cid    value 'ROOT1'.
    constants cid_node    type abp_behv_cid    value 'NODE1'.
    constants cid_subnode type abp_behv_cid    value 'SUBNODE1'.

    class-methods:
      class_setup,    "setup test double framework (executed once before all tests of the class)
      class_teardown. "stop test doubles (executed once after all tests of the test class are executed)
    methods:
      "! <p class="shorttext synchronized"lang="en"></p>
      "!
      setup,          "reset test doubles (executed before each individual test or before each execution of a test method)
      teardown.       "rollback any changes (executed after each individual test or after each execution of a test method)

    methods:
      "CUT (Code Under Test): create with validation of Begin/End dates with invalid input
      create_validation_negative for testing raising cx_static_check,
      "CUT (Code Under Test): create with action call and commit
      create_with_action_accept for testing raising cx_static_check.

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

  method create_validation_negative.
    "The code under test (CUT) will create a Travel instance and validate the field 'Begin Date'.

    data: invalid_begin type /dmo/begin_date,
          invalid_end   type /dmo/end_date.

    "valid date values must start on the current date or the future
    invalid_begin = cl_abap_context_info=>get_system_date( ) - 10. "invalid 'Begin Date' because it is before the current system date
    invalid_end   = cl_abap_context_info=>get_system_date( ) - 30. "invalid 'End Date' because it is before 'Begin Date'

    "create a Travel with invalid begin_date
    modify entities of ZRAP100_R_TravelTP_RW7
      entity travel
        create fields ( agency_id customer_id begin_date end_date description booking_fee currency_code )
          with value #( (  %cid = cid
                           agency_id      = agency_mock_data[ 1 ]-agency_id
                           customer_id    = customer_mock_data[ 1 ]-customer_id
                           begin_date     = invalid_begin
                           end_date       = invalid_end
                           description    = 'TestTravel 1'
                           booking_fee    = '10'
                           currency_code  = 'EUR' ) )
     mapped data(mapped_create)
     failed data(failed_create)
     reported data(reported_create).

    "check successful creation of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( mapped_create-travel ) ).
    "check key values of new Travel entry
    cl_abap_unit_assert=>assert_equals( exp = cid act = mapped_create-travel[ 1 ]-%cid ).
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
    "check expected content of 'failed' parameter (expected to have 2 lines)
    cl_abap_unit_assert=>assert_equals( act = lines( failed_commit-travel ) exp = 2 ).
    "check expected content of the TravelID value within the 'failed' parameter (expected to have a new TravelID)
    cl_abap_unit_assert=>assert_not_initial( act = failed_commit-travel[ 1 ]-travel_id ).
    "check expected content of the TravelID value within the 'failed' parameter (expected to have the same value in both entries)
    cl_abap_unit_assert=>assert_equals( act = failed_commit-travel[ 2 ]-travel_id exp = failed_commit-travel[ 1 ]-travel_id ).

    "check expected content of 'reported' parameter (expected to have 2 lines)
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

  method create_with_action_accept.
    "The code under test (CUT) will create a Travel instance and execute the action acceptTravel on it.
    "This scenario will include CREATE, EXECUTE and COMMIT EML statements.

    data: valid_begin type /dmo/begin_date,
          valid_end   type /dmo/end_date.

    valid_begin = cl_abap_context_info=>get_system_date( ).
    valid_end   = cl_abap_context_info=>get_system_date( ) + 14.

    "create a complete Travel instance
    modify entities of ZRAP100_R_TravelTP_RW7
      entity Travel
        create fields ( agency_id customer_id begin_date end_date description total_price booking_fee currency_code )
          with value #( (  %cid = 'ROOT1'
                           agency_id      = agency_mock_data[ 1 ]-agency_id
                           customer_id    = customer_mock_data[ 1 ]-customer_id
                           begin_date     = valid_begin
                           end_date       = valid_end
                           description    = 'TestTravel 1'
                           total_price    = '1100'
                           booking_fee    = '20'
                           currency_code  = 'EUR'
                        ) )

      "execute action 'acceptTravel'
      entity Travel
        execute acceptTravel
          from value #( ( %cid_ref = 'ROOT1' ) )

      "execute action 'deductDiscount' with 20% discount
      entity Travel
        execute deductDiscount
          from value #( ( %cid_ref = 'ROOT1'
                          %param-discount_percent = '20' ) )

      "result parameters
      mapped   data(mapped)
      failed   data(failed)
      reported data(reported).

    "CL_ABAP_UNIT_ASSERT is used in test method implementations to check/assert the test assumptions.
    "It offers various static methods for the purposes - e.g. assert_equals(), assert_initial(), assert_not_initial(), and assert_differs().

    "expect no failures and messages (i.e.: return parameters 'failed' and 'reported' are initial)
    cl_abap_unit_assert=>assert_initial( msg = 'failed'   act = failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'reported' act = reported ).

    "expect a newly created record in mapped tables (i.e.: 'mapped' contains the values for the new entry)
    cl_abap_unit_assert=>assert_not_initial( msg = 'mapped-travel'  act = mapped-travel ).

    "persist changes into the database (commit using the test doubles)
    commit entities responses
      failed   data(commit_failed)
      reported data(commit_reported).

    "expect no failures and messages (i.e.: return parameters 'commit_failed' and 'commit_reported'  are initial)
    cl_abap_unit_assert=>assert_initial( msg = 'commit_failed'   act = commit_failed ).
    cl_abap_unit_assert=>assert_initial( msg = 'commit_reported' act = commit_reported ).

    "read the data from the persisted travel entity (using the test doubles)
    select * from ZRAP100_R_TravelTP_RW7 into table @data(lt_travel). "#EC CI_NOWHERE

    "assert the existence of the persisted travel entity
    cl_abap_unit_assert=>assert_not_initial( msg = 'travel from db' act = lt_travel ).
    "assert the generation of a travel ID (key) at creation
    cl_abap_unit_assert=>assert_not_initial( msg = 'travel-id' act = lt_travel[ 1 ]-travel_id ).
    "assert that the action has changed the overall status (from 'O' to 'A')
    cl_abap_unit_assert=>assert_equals( msg = 'overall status' exp = 'A' act = lt_travel[ 1 ]-overall_status ).
    "assert the discounted booking_fee (from '20' to '16')
    cl_abap_unit_assert=>assert_equals( msg = 'discounted booking_fee' exp = '16' act = lt_travel[ 1 ]-booking_fee ).
  endmethod.

endclass.
