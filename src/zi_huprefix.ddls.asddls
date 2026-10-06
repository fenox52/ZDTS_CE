@EndUserText.label: 'HU Prefix'
@AccessControl.authorizationCheck: #CHECK
define view entity ZI_HuPrefix
  as select from ZDTS_HU_PREFIX
  association to parent ZI_HuPrefix_S as _HuPrefixAll on $projection.SingletonID = _HuPrefixAll.SingletonID
{
  key SOURCE as Source,
  key PLANT as Plant,
  PREFIX as Prefix,
  1 as SingletonID,
  _HuPrefixAll
  
}
