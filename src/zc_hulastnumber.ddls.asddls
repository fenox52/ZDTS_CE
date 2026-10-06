@EndUserText.label: 'Maintain HU Last Number'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZC_HuLastNumber
  as projection on ZI_HuLastNumber
{
  key Source,
  key Prefix,
  LastHuNo,
  @Consumption.hidden: true
  SingletonID,
  _HuLastNumberAll : redirected to parent ZC_HuLastNumber_S
  
}
