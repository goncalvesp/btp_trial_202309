@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel RW7N CDS Data Model'
define root view entity ZRAP100_R_TRAVELTP_RW7
  as select from zrap100_atravrw7 as Travel //data source in DB now with alias 'Travel'
  
  association [0..1] to /DMO/I_Agency            as _Agency        on $projection.agency_id = _Agency.AgencyID
  association [0..1] to /DMO/I_Customer          as _Customer      on $projection.customer_id = _Customer.CustomerID
  association [1..1] to /DMO/I_Overall_Status_VH as _OverallStatus on $projection.overall_status = _OverallStatus.OverallStatus
  association [0..1] to I_Currency               as _Currency      on $projection.currency_code = _Currency.Currency {

      key travel_id,
      agency_id,
      customer_id,
      begin_date,
      end_date,
      @Semantics.amount.currencyCode: 'currency_code'
      booking_fee,
      @Semantics.amount.currencyCode: 'currency_code'
      total_price,
      currency_code,
      description,
      overall_status,
      @Semantics.mimeType: true
      mime_type,
      file_name,
      attachment,
      @Semantics.user.createdBy: true
      created_by,
      @Semantics.systemDateTime.createdAt: true
      created_at,
      @Semantics.user.localInstanceLastChangedBy: true 
      local_last_changed_by, 
      @Semantics.systemDateTime.localInstanceLastChangedAt: true 
      local_last_changed_at, 
      @Semantics.systemDateTime.lastChangedAt: true 
      last_changed_at, 
     
      //expose associations 
      _Customer, 
      _Agency, 
      _OverallStatus, 
      _Currency 
}
