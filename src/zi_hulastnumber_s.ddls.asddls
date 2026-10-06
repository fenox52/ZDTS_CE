@EndUserText.label: 'HU Last Number Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_HuLastNumber_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_HULASTNUMBER'
  composition [0..*] of ZI_HuLastNumber as _HuLastNumber
{
  key 1 as SingletonID,
  _HuLastNumber,
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax,
  cast( '' as SXCO_TRANSPORT) as TransportRequestID,
  cast( 'X' as ABAP_BOOLEAN preserving type) as HideTransport
  
}
where I_Language.Language = $session.system_language
