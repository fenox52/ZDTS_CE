FUNCTION-POOL zfg_proc_order_conf.          "MESSAGE-ID ..

* INCLUDE LZFG_PROC_ORDER_CONFD...           " Local class definition

TYPES: BEGIN OF gty_mfgordst,
         manufacturingorder        TYPE i_mfgorderwithstatus-manufacturingorder,
         manufacturingordertype    TYPE i_mfgorderwithstatus-manufacturingordertype,
         mfgorderplannedtotalqty   TYPE i_mfgorderwithstatus-mfgorderplannedtotalqty,
         mfgorderconfirmedyieldqty TYPE i_mfgorderwithstatus-mfgorderconfirmedyieldqty,
         productionunit            TYPE i_mfgorderwithstatus-productionunit,
         orderisreleased           TYPE i_mfgorderwithstatus-orderisreleased,
         material                  TYPE i_mfgorderwithstatus-material,
         manufacturingordertext    TYPE i_mfgorderwithstatus-manufacturingordertext,
         productionplant           TYPE i_mfgorderwithstatus-productionplant,
         storagelocation           TYPE i_mfgorderwithstatus-storagelocation,
         batch                     TYPE i_manufacturingorderitem-batch,
         plantseries               TYPE char01,
       END OF gty_mfgordst,

       BEGIN OF gty_mfgordoptn,
         manufacturingorder          TYPE i_manufacturingorderoperation-manufacturingorder,
         manufacturingorderoperation TYPE i_manufacturingorderoperation-manufacturingorderoperation,
         operationcontrolprofile     TYPE i_manufacturingorderoperation-operationcontrolprofile,
         resource                    TYPE i_workcenter-workcenter,
       END OF gty_mfgordoptn,

       BEGIN OF gty_produom,
         product           TYPE  i_productunitsofmeasure-product,
         alternativeunit   TYPE  i_productunitsofmeasure-alternativeunit,
         quantitynumerator TYPE  i_productunitsofmeasure-quantitynumerator,
         baseunit          TYPE  i_productunitsofmeasure-baseunit,
       END OF gty_produom.


DATA: gs_mfgordst   TYPE gty_mfgordst,
      gs_mfgordoptn TYPE gty_mfgordoptn,
      gs_produom    TYPE gty_produom,
      gs_tab        TYPE zpp_palletid.

DATA: gt_bdcdata TYPE STANDARD TABLE OF bdcdata,
      gs_bdcdata TYPE bdcdata,
      gt_messtab TYPE STANDARD TABLE OF bdcmsgcoll,
      gs_messtab TYPE bdcmsgcoll.

DATA: gr_potype   TYPE RANGE OF i_mfgorderwithstatus-manufacturingordertype,
      gr_hupotype TYPE RANGE OF i_mfgorderwithstatus-manufacturingordertype.
