@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Travel App RW7N'
@Search.searchable: true
@ObjectModel.semanticKey: [ 'TravelID' ]

define root view entity ZRAP100_C_TRAVELTP_RW7
  provider contract transactional_query
  as projection on ZRAP100_R_TRAVELTP_RW7 {
      
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90    
      key travel_id             as TravelID,
      
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['AgencyName']
      @Consumption.valueHelpDefinition: [
        { entity : 
          { name: '/DMO/I_Agency', element: 'AgencyID' },
          //Frontend Validations with useForValidation: true
          //Performed on the UI and improve UX by providing faster validation and avoiding unnecessary server roundtrips. 
          //In this case, it prevents validation of the value help results, since they should already be valid (from the CDS View they originate from)
          useForValidation: true 
        }]
      agency_id                 as AgencyID,
      _Agency.Name              as AgencyName,
      
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['CustomerName']
      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Customer', element: 'CustomerID'  }, useForValidation: true }]
      customer_id               as CustomerID,
      _Customer.LastName        as CustomerName,
      begin_date                as BeginDate,
      end_date                  as EndDate,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee               as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price               as TotalPrice,
      @Consumption.valueHelpDefinition: [{ entity: {name: 'I_CurrencyStdVH', element: 'Currency' }, useForValidation: true }]
      currency_code             as CurrencyCode,
      
      description               as Description,
      
      @ObjectModel.text.element: ['OverallStatusText']
      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Overall_Status_VH', element: 'OverallStatus' }, useForValidation: true }]
      overall_status            as OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized,
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_VIRTUAL_RW7N' //to derive the criticality value
      virtual Criticality : /dmo/overall_status, //to set the relevan icon and color for each table entry

      mime_type                 as MimeType,
      file_name                 as FileName,
      @Semantics.largeObject: { 
        mimeType: 'MimeType',
        fileName: 'FileName',
        acceptableMimeTypes: ['image/png', 'image/jpeg'],
        contentDispositionPreference: #ATTACHMENT 
      }
      attachment                as Attachment,
      
      last_changed_at           as LastChangedAt,
      local_last_changed_at     as LocalLastChangedAt

}
