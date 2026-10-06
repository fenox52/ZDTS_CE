@EndUserText.label: 'Pallet Code'
@AccessControl.authorizationCheck: #CHECK
define view entity ZI_PalletCode
  as select from ZDTS_PALLETCODE
  association to parent ZI_PalletCode_S as _PalletCodeAll on $projection.SingletonID = _PalletCodeAll.SingletonID
{
  key PALLET_CODE as PalletCode,
  key PALLET_BRAND as PalletBrand,
  PALLET_TYPE as PalletType,
  PALLET_CODE_DESC as PalletCodeDesc,
  ACTIVE as Active,
  PALLET_DEFAULT as PalletDefault,
  1 as SingletonID,
  _PalletCodeAll
  
}
