@EndUserText.label: 'Maintain HU Last Number Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'SingletonID' ]
define root view entity ZC_HuLastNumber_S
  provider contract transactional_query
  as projection on ZI_HuLastNumber_S
{
  key SingletonID,
  LastChangedAtMax,
  TransportRequestID,
  HideTransport,
  _HuLastNumber : redirected to composition child ZC_HuLastNumber
  
}
