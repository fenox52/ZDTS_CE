@EndUserText.label: 'Maintain Pallet Code Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'SingletonID' ]
define root view entity ZC_PalletCode_S
  provider contract transactional_query
  as projection on ZI_PalletCode_S
{
  key SingletonID,
  LastChangedAtMax,
  _PalletCode : redirected to composition child ZC_PalletCode
  
}
