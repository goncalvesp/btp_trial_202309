# RAP100 + Extras
<img width="952" alt="image" src="https://github.com/goncalvesp/btp_trial_202309/assets/38356040/4d8fa67d-bbbc-4077-8239-63eb842b204f">

Some of the extras include:
- Correction of CDS Views and corresponding Behavior Definitions (and handlers) from RAP 100  
- Comments across multiple objects (behavior definitions, handlers, test classes, etc.) to better explain and document said objects, properties, actions, etc. (see <a href="https://github.com/goncalvesp/btp_trial_202309/blob/main/src/zrap100_r_traveltp_rw7.bdef.asbdef">Root BDEF</a> as an example)
- Annotation/UI changes (for example, see "Travel Status" and its criticality on the picture above), behavior handling changes that resemble more realistic uses (for example, removed possibility of user being able to change from "Accepted" to "Rejected" and vice-versa)
- <a href="https://github.com/goncalvesp/btp_trial_202309/blob/main/src/zrap100_bp_traveltp_rw7.clas.testclasses.abap">Local</a> and <a href="https://github.com/goncalvesp/btp_trial_202309/blob/main/src/zrap100_tc_travel_eml_rw7.clas.abap">Global</a> Test Classes with even more tests and examples

## Sources
- <a href="https://developers.sap.com/tutorials/abap-environment-trial-onboarding.html">Create an SAP BTP ABAP Environment Trial User</a>
- <a href="https://developers.sap.com/mission.sap-fiori-abap-rap100.html"><strong>Build an SAP Fiori App Using the ABAP RESTful Application Programming Model [RAP100]</strong></a>
- <a href="https://help.sap.com/docs/abap-cloud/abap-rap/unit-tests"><strong>Additional unit and integration tests</strong></a>

## Getting started
- (Optional) Complete <a href="https://developers.sap.com/tutorials/abap-environment-trial-onboarding.html">Create an SAP BTP ABAP Environment Trial User</a>
- Complete <a href="https://developers.sap.com/mission.sap-fiori-abap-rap100.html"><strong>RAP100</strong></a>

### Prerequisites
- SAP BTP ABAP Environment system
- Subaccount and dev space in BTP
- ABAP Development Tools (<a href="https://tools.hana.ondemand.com/#abap">ADT</a>)
- (Optional) github.com / gitlab.com account
- (Optional) abapGit (for more information see <a href="https://help.sap.com/docs/btp/sap-business-technology-platform/working-with-abapgit">Working with <strong>abapGit</strong></a>)

### List from ADT (in alphabetical order):
Business Services
- Service Bindings
  -  ZRAP100_UI_TRAVEL_O4_RW7 
- Service Definitions
  - ZRAP100_UI_TRAVEL_RW7  
  
Cloud Communication Management
- COM Inbound Services
  - ZRAP100_UI_TRAVEL_O4_RW7_0001_G4BA --> not in the repo <img width="298" alt="image" src="https://github.com/goncalvesp/btp_trial_202309/assets/38356040/26769c38-2bd3-43ab-bed2-b9b1951bae4f">  
  
Cloud Identity and Access Management
- IAM Apps
  - ZRAP100_UI_TRAVEL_O4_RW7__00001_IBS

Core Data Services
- Behavior Definitions
  - ZRAP100_C_TRAVELTP_RW7
  - ZRAP100_R_TRAVELTP_RW7
- Data Definitions
  - ZRAP100_A_TRAVELDISCOUNT
  - ZRAP100_C_TRAVELTP_RW7
  - ZRAP100_R_TRAVELTP_RW7
- Metadata Extension
  - ZRAP100_C_TRAVELTP_RW7

Dictionary
- Data Elements
  - ZRAP100_RW7N_DISCOUNT
- Database Tables
  - ZRAP100_ATRAVRW7
  - ZRAP100_DRW7
- Domains
  - ZRAP100_RW7N_DISCOUNT
    
Source Code Library
- Classes
  - ZCL_RAP100_GEN_DATA_RW7N
  - ZCL_VIRTUAL_RW7N
  - ZRAP100_BP_TRAVELTP_RW7
  - ZRAP100_TC_TRAVEL_EML_RW7

## Sources
- <a href="https://developers.sap.com/mission.sap-fiori-abap-rap100.html"><strong>RAP 100</strong></a>
- <a href="https://help.sap.com/docs/abap-cloud/abap-rap/unit-tests"><strong>Additional unit and integration tests</strong></a>
