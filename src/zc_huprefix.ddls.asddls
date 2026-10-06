@EndUserText.label: 'Maintain HU Prefix'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZC_HuPrefix
  as projection on ZI_HuPrefix
{
  key Source,
  key Plant,
  Prefix,
  @Consumption.hidden: true
  SingletonID,
  _HuPrefixAll : redirected to parent ZC_HuPrefix_S
  
}
