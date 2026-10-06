@EndUserText.label: 'HU Last Number'
@AccessControl.authorizationCheck: #CHECK
define view entity ZI_HuLastNumber
  as select from ZDTS_LASTHU
  association to parent ZI_HuLastNumber_S as _HuLastNumberAll on $projection.SingletonID = _HuLastNumberAll.SingletonID
{
  key SOURCE as Source,
  key PREFIX as Prefix,
  LAST_HU_NO as LastHuNo,
  1 as SingletonID,
  _HuLastNumberAll
  
}
