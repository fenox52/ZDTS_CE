@EndUserText.label: 'Custom Entity for PO Confirmation'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_POCONF'
define root custom entity ZPP_CI_POCONF
{
  key ManufacturingOrder          : aufnr;
      ManufacturingOrderOperation : abap.numc(4);
      PalletCode                  : abap.char(40);
      @Semantics.quantity.unitOfMeasure: 'ToBeProdUnit'      
      ToBeConfirmedQty            : gamng; 
      ToBeProdUnit                : meins;    
}
