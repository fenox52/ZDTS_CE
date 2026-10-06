@EndUserText.label: 'Maintain HU Prefix Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'SingletonID' ]
define root view entity ZC_HuPrefix_S
  provider contract transactional_query
  as projection on ZI_HuPrefix_S
{
  key SingletonID,
  LastChangedAtMax,
  TransportRequestID,
  HideTransport,
  _HuPrefix : redirected to composition child ZC_HuPrefix
  
}
