@EndUserText.label: 'Pallet Code Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_PalletCode_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_PALLETCODE'
  composition [0..*] of ZI_PalletCode as _PalletCode
{
  key 1 as SingletonID,
  _PalletCode,
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
  
}
where I_Language.Language = $session.system_language
