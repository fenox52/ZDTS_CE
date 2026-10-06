@EndUserText.label: 'Custom Entity for Process Order details'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_POGDTL'
define custom entity ZPP_CI_POGDTL
  with parameters 
    ProcessOrder : aufnr,
    Operation    : char04
{
  key ManufacturingOrder          : aufnr;
      ManufacturingOrderOperation : abap.numc( 4 );
      OperationControlProfile     : steus;
      @Semantics.quantity.unitOfMeasure: 'ProductionUnit'
      MfgOrderPlannedTotalQty     : gamng;
      @Semantics.quantity.unitOfMeasure: 'ProductionUnit'
      MfgOrderConfirmedYieldQty   : co_igmng;
      @Semantics.unitOfMeasure    : true
      ProductionUnit              : meins;
      OrderIsReleased             : boolean;
      Material                    : matnr;
      PalletCount                 : abap.numc( 3 );
      @Semantics.quantity.unitOfMeasure: 'ToBeProdUnit'      
      ToBeConfirmedQty            : gamng; 
      ToBeProdUnit                : meins;  
      NonOrderType                : abap.char( 1 );
}
