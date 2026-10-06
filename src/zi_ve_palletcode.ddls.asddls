@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pallet Code'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_VE_PALLETCODE
  as select from zdts_palletcode
{
  key pallet_code      as PalletCode,
  key pallet_brand     as PalletBrand,
      pallet_code_desc as PalletCodeDesc
}
where
  active = 'X'
  and pallet_default = ''
