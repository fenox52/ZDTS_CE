@EndUserText.label: 'Maintain Pallet Code'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZC_PalletCode
  as projection on ZI_PalletCode
{
  key PalletCode,
  key PalletBrand,
  PalletType,
  PalletCodeDesc,
  Active,
  PalletDefault,
  @Consumption.hidden: true
  SingletonID,
  _PalletCodeAll : redirected to parent ZC_PalletCode_S
  
}
