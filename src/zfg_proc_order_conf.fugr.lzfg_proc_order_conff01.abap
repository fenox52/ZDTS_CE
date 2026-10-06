*----------------------------------------------------------------------*
***INCLUDE LZFG_PROC_ORDER_CONFF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form f_check_lock
*&---------------------------------------------------------------------*
*& Check Lock
*&---------------------------------------------------------------------*
FORM f_check_lock  USING    iv_manufacturingorder
                   CHANGING cv_type
                            cv_message.

  CALL FUNCTION 'ENQUEUE_ESORDER'
    EXPORTING
      mode_aufk      = 'E'
      mandt          = sy-mandt
      aufnr          = iv_manufacturingorder
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid
          TYPE sy-msgty
        NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
          INTO DATA(lv_msg).
    cv_type = 'E'.
    cv_message = lv_msg.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_validate
*&---------------------------------------------------------------------*
*& Validate Process Order
*&---------------------------------------------------------------------*
FORM f_validate  USING    iv_manufacturingorder
                          iv_manufacturingorderoperation
                          iv_palletcode
                          iv_tobeconfirmedqty
                 CHANGING cv_type
                          cv_message.

  SELECT SINGLE t1~manufacturingorder,
                t1~manufacturingordertype,
                t1~mfgorderplannedtotalqty,
                t1~mfgorderconfirmedyieldqty,
                t1~productionunit,
                t1~orderisreleased,
                t1~material,
                t1~manufacturingordertext,
                t1~productionplant,
                t1~storagelocation,
                t2~batch
  FROM i_mfgorderwithstatus WITH PRIVILEGED ACCESS AS t1
  LEFT JOIN i_manufacturingorderitem WITH PRIVILEGED ACCESS AS t2
  ON t1~manufacturingorder EQ t2~manufacturingorder
  WHERE t1~manufacturingorder EQ @iv_manufacturingorder
  INTO @gs_mfgordst.
  IF sy-subrc NE 0.
    cv_type = 'E'.
    cv_message = TEXT-e01.
    RETURN.
  ENDIF.

  IF gs_mfgordst-orderisreleased NE abap_true.
    cv_type = 'E'.
    cv_message = TEXT-e02.
    RETURN.
  ENDIF.

  SELECT SINGLE t1~manufacturingorder,
                t1~manufacturingorderoperation,
                t1~operationcontrolprofile,
                t2~workcenter
  FROM i_manufacturingorderoperation WITH PRIVILEGED ACCESS AS t1
  LEFT JOIN i_workcenter WITH PRIVILEGED ACCESS AS t2
  ON t1~workcenterinternalid EQ t2~workcenterinternalid
  AND t1~workcentertypecode EQ t2~workcentertypecode
  WHERE manufacturingorder EQ @iv_manufacturingorder
  AND   manufacturingorderoperation EQ @iv_manufacturingorderoperation
  INTO @gs_mfgordoptn.
  IF sy-subrc NE 0.
    cv_type = 'E'.
    cv_message = TEXT-e03.
    RETURN.
  ENDIF.

  IF gs_mfgordoptn-operationcontrolprofile EQ 'ZPI4'.
  ELSE.
    cv_type = 'E'.
    cv_message = TEXT-e04.
    RETURN.
  ENDIF.

  CONDENSE iv_palletcode.

  IF gs_mfgordst-manufacturingordertype IN gr_hupotype[].

    SELECT SINGLE pallet_code
    FROM zdts_palletcode
    INTO @DATA(lv_palletcode)
    WHERE pallet_code EQ @iv_palletcode.
    IF sy-subrc NE 0.
      cv_type = 'E'.
      cv_message = TEXT-e12.
      RETURN.
    ENDIF.

    SELECT SINGLE lhmg1,
                  lhmg2,
                  lhmg3,
                  lhme1,
                  lhme2,
                  lhme3
    FROM mlgn
    INTO @DATA(ls_mlgn)
    WHERE matnr EQ @gs_mfgordst-material
    AND (  lhme1 EQ @gs_mfgordst-productionunit OR
           lhme2 EQ @gs_mfgordst-productionunit OR
           lhme3 EQ @gs_mfgordst-productionunit ).
    IF sy-subrc EQ 0.
      CASE gs_mfgordst-productionunit.
        WHEN ls_mlgn-lhme1.
          gs_produom-quantitynumerator = ls_mlgn-lhmg1.
        WHEN ls_mlgn-lhme2.
          gs_produom-quantitynumerator = ls_mlgn-lhmg2.
        WHEN ls_mlgn-lhme3.
          gs_produom-quantitynumerator = ls_mlgn-lhmg3.
      ENDCASE.
    ELSE.
      SELECT SINGLE product,
                    alternativeunit,
                    quantitynumerator,
                    baseunit
      FROM  i_productunitsofmeasure WITH PRIVILEGED ACCESS
      WHERE product  EQ @gs_mfgordst-material
      AND   baseunit EQ @gs_mfgordst-productionunit
      AND   alternativeunit EQ 'PAL'
      INTO @gs_produom.
      IF sy-subrc NE 0.
        cv_type = 'E'.
        cv_message = TEXT-e05.
        RETURN.
      ENDIF.
    ENDIF.

    IF iv_tobeconfirmedqty > gs_produom-quantitynumerator.
      cv_type = 'E'.
      cv_message = |{ TEXT-e06 } { gs_produom-quantitynumerator } { gs_produom-baseunit }|.
      RETURN.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_procord_confirm
*&---------------------------------------------------------------------*
*& Call BAPI to confirm process order
*&---------------------------------------------------------------------*
FORM f_procord_confirm  USING iv_manufacturingorder
                              iv_manufacturingorderoperation
                              iv_palletcode
                              iv_tobeconfirmedqty
                              iv_tobeprodunit
                        CHANGING cv_type
                                 cv_message.

  DATA: lt_tkt   TYPE TABLE OF bapi_pi_timeticket1,
        lt_gdmvt TYPE TABLE OF bapi2017_gm_item_show,
        lt_gmcrt TYPE TABLE OF bapi2017_gm_item_create,
        lt_link  TYPE TABLE OF bapi_link_conf_goodsmov,
        lt_flmvt TYPE TABLE OF bapi_coru_fgm,
        lt_coret TYPE TABLE OF bapi_coru_return,
        lt_huret TYPE TABLE OF bapiret2,
        lt_headr TYPE TABLE OF bapi_order_header1,
        lt_cmpnt TYPE TABLE OF bapi_order_component,
        lt_comp  TYPE TABLE OF cowb_comp,
        lt_kbtch TYPE TABLE OF cowb_key_stock.

  DATA: ls_huchnge TYPE bapihuheader,
        ls_confdtl TYPE bapi_pi_confirm,
        ls_ordobj  TYPE bapi_pi_order_objects,
        ls_unpack  TYPE bapihuitmunpack,
        ls_pack    TYPE bapihuitmproposal.

  DATA: ls_ctu_params TYPE ctu_params.

  ls_ordobj-header = abap_true.
  ls_ordobj-components = abap_true.

  CALL FUNCTION 'BAPI_PROCORD_GET_DETAIL'
    EXPORTING
      number        = iv_manufacturingorder
      order_objects = ls_ordobj
    TABLES
      header        = lt_headr
      component     = lt_cmpnt.

  DATA(ls_headr) = VALUE #( lt_headr[ 1 ] OPTIONAL ).

  zcl_pallet_service=>get( EXPORTING iv_proc_order = iv_manufacturingorder
                           IMPORTING et_tab        = DATA(lt_tab) ).

  SORT lt_tab BY pallet_cnt ASCENDING.
  DATA(ls_tab) = VALUE #( lt_tab[ su_status = 'OPEN' ] OPTIONAL ).
  IF ls_tab IS NOT INITIAL.
    gs_tab = ls_tab.
    DATA(lv_wopensu) = abap_true.
  ENDIF.

  gs_tab-batch = zcl_generate_batch_number=>get( iv_order = gs_mfgordst-manufacturingorder
                                                 iv_plant = gs_mfgordst-productionplant ).
  IF gs_tab-batch IS INITIAL.
    gs_tab-batch = gs_mfgordst-batch.
  ENDIF.

  "--Create HU
  IF gs_mfgordst-manufacturingordertype IN gr_hupotype[].

    PERFORM f_hu_create  USING iv_manufacturingorder
                               iv_palletcode
                               iv_tobeconfirmedqty
                               iv_tobeprodunit
                               lv_wopensu
                         CHANGING cv_type
                                  cv_message.

    IF cv_type EQ 'E'.
      PERFORM f_bapi_rollback.
      RETURN.
    ENDIF.

    ls_huchnge-pack_mat_object  = '09'.
    ls_huchnge-pack_mat_obj_key = iv_manufacturingorder.

    FREE: lt_huret.
    CALL FUNCTION 'BAPI_HU_CHANGE_HEADER'
      EXPORTING
        hukey     = gs_tab-su_no
        huchanged = ls_huchnge
      TABLES
        return    = lt_huret.

    PERFORM f_bapi_commit.
  ENDIF.

  APPEND INITIAL LINE TO lt_tkt ASSIGNING FIELD-SYMBOL(<fs_tkt>).
  <fs_tkt>-orderid        = iv_manufacturingorder.
  <fs_tkt>-phase          = iv_manufacturingorderoperation.
  <fs_tkt>-postg_date     = sy-datum.
  <fs_tkt>-conf_quan_unit = iv_tobeprodunit.
  <fs_tkt>-yield          = iv_tobeconfirmedqty.

  "Required to get actual GR material doc. in the system
  DATA(lv_wait) = 30.

  "--Call BDC Transaction COWBHUWE to create IB from HU
  "--(No released API or BAPI available)
  IF gs_mfgordst-manufacturingordertype IN gr_hupotype[].
    "Downstream Process Order
    PERFORM build_bdc USING iv_manufacturingorder.

    ls_ctu_params-dismode = 'N'.   " Mode
    ls_ctu_params-updmode = 'S'.   " Update

    CALL TRANSACTION 'COWBHUWE' USING gt_bdcdata
                                OPTIONS FROM ls_ctu_params
                                MESSAGES INTO gt_messtab.

    DATA(ls_messtab) = VALUE #( gt_messtab[ msgtyp = 'S'
                                             msgid = 'L9'
                                             msgnr = 514 ] OPTIONAL ).
    IF ls_messtab IS INITIAL.
      "--If with error, unpack and delete HU
      ls_unpack-hu_item_number = 1.
      ls_unpack-material       = gs_mfgordst-material.
      ls_unpack-pack_qty       = iv_tobeconfirmedqty.

      CALL FUNCTION 'BAPI_HU_UNPACK'
        EXPORTING
          hukey      = gs_tab-su_no
          itemunpack = ls_unpack
        TABLES
          return     = lt_huret.

      PERFORM f_bapi_commit.

      IF lv_wopensu IS INITIAL.
        CALL FUNCTION 'BAPI_HU_DELETE'
          EXPORTING
            hukey  = gs_tab-su_no
          TABLES
            return = lt_huret.

        PERFORM f_bapi_commit.
      ENDIF.

      cv_type = 'E'.
      cv_message = TEXT-e14.
      RETURN.
    ENDIF.

  ELSEIF gs_mfgordst-manufacturingordertype IN gr_potype[].
    "Upstream Process Order
    APPEND INITIAL LINE TO lt_gmcrt ASSIGNING FIELD-SYMBOL(<fs_gmcrt>).
    <fs_gmcrt>-material  = gs_mfgordst-material.
    <fs_gmcrt>-plant     = gs_mfgordst-productionplant.
    <fs_gmcrt>-stge_loc  = gs_mfgordst-storagelocation.
    <fs_gmcrt>-move_type = '101'.
    <fs_gmcrt>-mvt_ind   = 'F'.
    <fs_gmcrt>-prod_date = sy-datum.
    <fs_gmcrt>-entry_qnt = iv_tobeconfirmedqty.
    <fs_gmcrt>-entry_uom = iv_tobeprodunit.
    <fs_gmcrt>-orderid   = iv_manufacturingorder.
    <fs_gmcrt>-orderid   = iv_manufacturingorder.
    <fs_gmcrt>-orderid   = iv_manufacturingorder.
    <fs_gmcrt>-batch     = gs_tab-batch.

    APPEND INITIAL LINE TO lt_link ASSIGNING FIELD-SYMBOL(<fs_link>).
    <fs_link>-index_confirm  = 1.
    <fs_link>-index_goodsmov = 1.

    "--Process Order confirmation
    CALL FUNCTION 'BAPI_PROCORDCONF_CREATE_TT'
      TABLES
        timetickets        = lt_tkt
        goodsmovements     = lt_gmcrt
        link_conf_goodsmov = lt_link
        detail_return      = lt_coret.

    IF lt_coret[] IS NOT INITIAL.
      DATA(ls_coret) = lt_coret[ 1 ].
      IF ls_coret-conf_no  IS NOT INITIAL AND
         ls_coret-conf_cnt IS NOT INITIAL AND
         ls_coret-id       EQ 'RU' AND
         ls_coret-number   EQ '100'.
        cv_type = 'S'.
        cv_message = ls_coret-message.
      ELSE.
        cv_type = 'E'.
        cv_message = ls_coret-message.
      ENDIF.
    ELSE.
      cv_type = 'E'.
      cv_message = TEXT-e08.
    ENDIF.

    IF cv_type EQ 'E'.
      PERFORM f_bapi_rollback.
      RETURN.
    ELSE.
      PERFORM f_bapi_commit.
    ENDIF.

    DO lv_wait TIMES.
      WAIT UP TO 1 SECONDS.
      CALL FUNCTION 'BAPI_PROCORDCONF_GETDETAIL'
        EXPORTING
          confirmation        = ls_coret-conf_no
          confirmationcounter = ls_coret-conf_cnt
        IMPORTING
          conf_detail         = ls_confdtl
        TABLES
          goodsmovements      = lt_gdmvt
          failedgmoves        = lt_flmvt.
      IF lt_gdmvt[] IS NOT INITIAL.
        DATA(ls_gdmvt) = VALUE #( lt_gdmvt[ material = gs_mfgordst-material ] OPTIONAL ).
        IF ls_gdmvt IS NOT INITIAL.
          "Check if there are component material with pending GR posting delay
          DATA(ls_flmvt) = VALUE #( lt_flmvt[ msg_type = ''  msg_id   = '' ] OPTIONAL ).
          IF ls_flmvt IS INITIAL.
            EXIT.
          ENDIF.
        ENDIF.
      ELSEIF lt_flmvt[] IS NOT INITIAL.
        "If no error found in GR posting,
        "add wait for the GR doc to be posted in the system.
        ls_flmvt = VALUE #( lt_flmvt[ material = gs_mfgordst-material ] OPTIONAL ).
        IF ls_flmvt-msg_type IS NOT INITIAL AND
           ls_flmvt-msg_id IS NOT INITIAL.
          EXIT.
        ENDIF.
      ENDIF.
      FREE: ls_flmvt.
    ENDDO.

    FREE: ls_flmvt.
    ls_flmvt = VALUE #( lt_flmvt[ move_type = '101' ] OPTIONAL ).
    IF ls_flmvt IS NOT INITIAL.
      "--Cancel Process Order confirmation
      CALL FUNCTION 'BAPI_PROCORDCONF_CANCEL'
        EXPORTING
          confirmation        = ls_confdtl-conf_no
          confirmationcounter = ls_confdtl-conf_cnt.

      ls_unpack-hu_item_number = 1.
      ls_unpack-material       = gs_mfgordst-material.
      ls_unpack-pack_qty       = iv_tobeconfirmedqty.
*
      CALL FUNCTION 'BAPI_HU_UNPACK'
        EXPORTING
          hukey      = gs_tab-su_no
          itemunpack = ls_unpack
        TABLES
          return     = lt_huret.

      PERFORM f_bapi_commit.

      CALL FUNCTION 'BAPI_HU_DELETE'
        EXPORTING
          hukey  = gs_tab-su_no
        TABLES
          return = lt_huret.

      PERFORM f_bapi_commit.

      cv_type = 'E'.
      cv_message = TEXT-e13.
      RETURN.
    ELSE.
      IF lt_gdmvt[] IS NOT INITIAL.
        ls_gdmvt = VALUE #( lt_gdmvt[ material = gs_mfgordst-material ] OPTIONAL ).
        gs_tab-mblnr = ls_gdmvt-mat_doc.
        gs_tab-mjahr = ls_gdmvt-doc_year.
        IF gs_mfgordst-batch IS INITIAL.
          gs_tab-batch = ls_gdmvt-batch.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  "--Manual Backflushing of component
  DATA(lv_alloc) = iv_tobeconfirmedqty / gs_mfgordst-mfgorderplannedtotalqty.

  APPEND INITIAL LINE TO lt_kbtch ASSIGNING FIELD-SYMBOL(<fs_kbtch>).
  <fs_kbtch>-aufnr = iv_manufacturingorder.
  <fs_kbtch>-auart = gs_mfgordst-manufacturingordertype.
  <fs_kbtch>-werks = gs_mfgordst-productionplant.

  DATA(lv_index) = 1.

  FREE: lt_gmcrt,
        lt_link,
        lt_coret.

  LOOP AT lt_cmpnt ASSIGNING FIELD-SYMBOL(<fs_cmpnt>)
                             WHERE backflush EQ abap_true.
    APPEND INITIAL LINE TO lt_gmcrt ASSIGNING <fs_gmcrt>.
    <fs_gmcrt>-material  = <fs_cmpnt>-material.
    <fs_gmcrt>-plant     = <fs_cmpnt>-prod_plant.
    <fs_gmcrt>-stge_loc  = <fs_cmpnt>-storage_location.
    <fs_gmcrt>-move_type = <fs_cmpnt>-movement_type.
    <fs_gmcrt>-prod_date = sy-datum.
    <fs_gmcrt>-activity  = <fs_cmpnt>-operation.
    <fs_gmcrt>-entry_qnt = <fs_cmpnt>-entry_quantity * lv_alloc.
    <fs_gmcrt>-entry_uom = <fs_cmpnt>-entry_uom.
    <fs_gmcrt>-orderid   = iv_manufacturingorder.
    <fs_gmcrt>-reserv_no = <fs_cmpnt>-reservation_number.
    <fs_gmcrt>-res_item  = <fs_cmpnt>-reservation_item.

    APPEND INITIAL LINE TO lt_comp ASSIGNING FIELD-SYMBOL(<fs_comp>).
    <fs_comp>-bwart  = <fs_cmpnt>-movement_type.
    <fs_comp>-matnr  = <fs_cmpnt>-material.
    <fs_comp>-werks  = <fs_cmpnt>-prod_plant.
    <fs_comp>-lgort  = <fs_cmpnt>-storage_location.
    <fs_comp>-erfmg  = <fs_gmcrt>-entry_qnt.
    <fs_comp>-erfme  = <fs_cmpnt>-entry_uom.
    <fs_comp>-rsnum  = <fs_cmpnt>-reservation_number.
    <fs_comp>-rspos  = <fs_cmpnt>-reservation_item.
    <fs_comp>-aufnr  =  iv_manufacturingorder.

    "--Determination of component batch based from COR6n
    CALL FUNCTION 'CO_WB_BATCH_DETERMINATION'
      EXPORTING
        i_operation     = '3'
        i_flg_no_dialog = abap_true
      TABLES
        t_comp          = lt_comp
        t_key_batch     = lt_kbtch.

    <fs_gmcrt>-batch = VALUE #( lt_comp[ 1 ]-charg OPTIONAL ).

    APPEND INITIAL LINE TO lt_link ASSIGNING <fs_link>.
    <fs_link>-index_confirm  = 1.
    <fs_link>-index_goodsmov = lv_index.

    ADD 1 TO lv_index.

    FREE: lt_comp.
  ENDLOOP.

  "--Process Order confirmation
  CALL FUNCTION 'BAPI_PROCORDCONF_CREATE_TT'
    TABLES
      timetickets        = lt_tkt
      goodsmovements     = lt_gmcrt
      link_conf_goodsmov = lt_link
      detail_return      = lt_coret.

  IF lt_coret[] IS NOT INITIAL.
    ls_coret = lt_coret[ 1 ].
    IF ls_coret-conf_no  IS NOT INITIAL AND
       ls_coret-conf_cnt IS NOT INITIAL AND
       ls_coret-id       EQ 'RU' AND
       ls_coret-number   EQ '100'.
      cv_type = 'S'.
      cv_message = ls_coret-message.
    ELSE.
      cv_type = 'E'.
      cv_message = ls_coret-message.
    ENDIF.
  ENDIF.

  IF cv_type NE 'E'.
    PERFORM f_bapi_commit.
  ENDIF.

  FREE: lt_gdmvt,
        lt_flmvt.

  DO lv_wait TIMES.
    WAIT UP TO 1 SECONDS.
    CALL FUNCTION 'BAPI_PROCORDCONF_GETDETAIL'
      EXPORTING
        confirmation        = ls_coret-conf_no
        confirmationcounter = ls_coret-conf_cnt
      IMPORTING
        conf_detail         = ls_confdtl
      TABLES
        goodsmovements      = lt_gdmvt
        failedgmoves        = lt_flmvt.
    IF lt_flmvt[] IS NOT INITIAL.
      "If no error found in GR posting,
      "add wait for the GR doc to be posted in the system.
      ls_flmvt = VALUE #( lt_flmvt[ msg_type = ''
                                    msg_id   = '' ] OPTIONAL ).
      IF ls_flmvt IS INITIAL.
        EXIT.
      ENDIF.
    ELSE.
      EXIT.
    ENDIF.
    FREE: ls_flmvt.
  ENDDO.

  gs_tab-budat = ls_confdtl-postg_date.

  IF lv_wopensu IS INITIAL.
    IF lt_tab[] IS INITIAL.
      gs_tab-pallet_cnt   = '001'.
    ELSE.
      FREE: ls_tab.
      SORT lt_tab BY pallet_cnt DESCENDING.
      ls_tab = lt_tab[ 1 ].
      gs_tab-pallet_cnt = ls_tab-pallet_cnt + 1.
    ENDIF.

    gs_tab-proc_order   = iv_manufacturingorder.
    gs_tab-order_type   = gs_mfgordst-manufacturingordertype.
    gs_tab-qty          = iv_tobeconfirmedqty.
    gs_tab-uom          = iv_tobeprodunit.
    gs_tab-material     = gs_mfgordst-material.
    gs_tab-mat_desc     = gs_mfgordst-manufacturingordertext.
    gs_tab-plant        = gs_mfgordst-productionplant.
    gs_tab-plan_qty     = gs_mfgordst-mfgorderplannedtotalqty.
    gs_tab-base_uom     = gs_mfgordst-productionunit.
    gs_tab-conf_no      = ls_coret-conf_no.
    gs_tab-conf_cnt     = ls_coret-conf_cnt.
    gs_tab-prod_line    = gs_mfgordoptn-resource.
    gs_tab-pallet_code  = iv_palletcode.
    gs_tab-created_on   = sy-datum.
    gs_tab-created_at   = sy-uzeit.
    gs_tab-created_by   = sy-uname.
    gs_tab-create_mode  = 'R'.
    gs_tab-su_status    = 'USED'.
    IF ls_headr-sched_start_time BETWEEN '000000' AND '115900'.
      gs_tab-shift = 'A'.
    ELSE.
      gs_tab-shift = 'B'.
    ENDIF.
  ELSE.
    gs_tab-conf_no      = ls_coret-conf_no.
    gs_tab-conf_cnt     = ls_coret-conf_cnt.
    gs_tab-pallet_code  = iv_palletcode.
    gs_tab-prod_line    = gs_mfgordoptn-resource.
    gs_tab-su_status    = 'USED'.
  ENDIF.

  gs_tab-act_qty = iv_tobeconfirmedqty.

  "Get batch details
  SELECT SINGLE manufacturedate,
                shelflifeexpirationdate
  FROM i_batch WITH PRIVILEGED ACCESS
  WHERE plant    EQ @gs_tab-plant
  AND   material EQ @gs_tab-material
  AND   batch    EQ @gs_tab-batch
  INTO @DATA(ls_batch).
  IF sy-subrc EQ 0.
    gs_tab-mfg_date = ls_batch-manufacturedate.
    gs_tab-sled_bbd = ls_batch-shelflifeexpirationdate.
  ENDIF.

  IF lt_tab[] IS NOT INITIAL.
    DATA(lv_gdmvtcnt) = REDUCE i( INIT x = 0
                                  FOR tab IN lt_tab WHERE ( mblnr IS NOT INITIAL )
                                  NEXT x = x + 1 ).
    gs_tab-counter = lv_gdmvtcnt + 1.
  ELSE.
    gs_tab-counter = 1.
  ENDIF.

  IF lv_wopensu IS INITIAL.
    "Insert Pallet ID
    zcl_pallet_service=>insert( EXPORTING is_tab = gs_tab ).

    IF gs_mfgordst-manufacturingordertype IN gr_hupotype[].
      "Print SU
      zcl_pallet_service=>print( EXPORTING is_tab = gs_tab ).
    ENDIF.
  ELSE.
    "Update Pallet ID
    zcl_pallet_service=>update( EXPORTING is_tab = gs_tab ).
  ENDIF.

  DATA(lv_fail) = lines( lt_flmvt ).
  DATA(lv_good) = lines( lt_gdmvt ) + 1.

  cv_type = 'S'.
  cv_message = |{ TEXT-s01 } { lv_good }{ TEXT-s02 } { lv_fail })|.

*Start of Add DLW060 18/05/2026 - SI-81
  DATA(lwa_lemovhus) = VALUE lemovhus( exidv = gs_tab-su_no
                                       matnr = gs_tab-material
                                       werks = gs_tab-plant
                                       lgort = gs_mfgordst-storagelocation ).

  DATA(lv_task) = VALUE char30( ).

  lv_task = sy-uname.

  CALL FUNCTION 'ZFM_EWM_GOODSMVT_CREATE'
    STARTING NEW TASK lv_task
    DESTINATION 'NONE'
    EXPORTING
      lemovhus = lwa_lemovhus.

*End of Add DLW060 18/05/2026 - SI-81
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_hu_process
*&---------------------------------------------------------------------*
*& Handling Unit create
*&---------------------------------------------------------------------*
FORM f_hu_create   USING iv_manufacturingorder
                         iv_palletcode
                         iv_tobeconfirmedqty
                         iv_tobeprodunit
                         iv_wopensu
                   CHANGING cv_type
                            cv_message.

  DATA: lt_itm   TYPE TABLE OF bapihuitmproposal,
        lt_huret TYPE TABLE OF bapiret2.

  DATA: ls_hdrprop TYPE bapihuhdrproposal,
        ls_hukey   TYPE bapihukey-hu_exid.

  IF iv_wopensu IS INITIAL.
    "Real-time: No open SU from Pallet table
    ls_hdrprop-hu_exid = zcl_pallet_service=>get_ext_hu( iv_source = 'PROD'
                                                         iv_plant  = gs_mfgordst-productionplant ).
  ELSE.
    "Advance: Pack material from existing Open SU
    ls_hdrprop-hu_exid = gs_tab-su_no.
  ENDIF.

  IF ls_hdrprop-hu_exid IS INITIAL.
    cv_type = 'E'.
    cv_message = TEXT-e11.
    RETURN.
  ENDIF.

  ls_hdrprop-hu_status_init = 'A'.
  ls_hdrprop-pack_mat       = iv_palletcode.

  APPEND INITIAL LINE TO lt_itm ASSIGNING FIELD-SYMBOL(<fs_itm>).
  <fs_itm>-hu_item_type  = '1'.
  <fs_itm>-pack_qty      = iv_tobeconfirmedqty.
  <fs_itm>-base_unit_qty = iv_tobeprodunit.
  <fs_itm>-material      = gs_mfgordst-material.
  <fs_itm>-plant         = gs_mfgordst-productionplant.
  <fs_itm>-stge_loc      = gs_mfgordst-storagelocation.

  CALL FUNCTION 'BAPI_HU_CREATE'
    EXPORTING
      headerproposal = ls_hdrprop
    IMPORTING
      hukey          = ls_hukey
    TABLES
      itemsproposal  = lt_itm
      return         = lt_huret.

  DATA(ls_huret) = VALUE #( lt_huret[ type = 'E'] OPTIONAL ).
  IF ls_huret-type EQ 'E'.
    IF ls_huret-message IS NOT INITIAL.
      cv_type = 'E'.
      cv_message = ls_huret-message.
    ELSE.
      MESSAGE ID ls_huret-id
            TYPE ls_huret-type
          NUMBER ls_huret-number
            WITH ls_huret-message_v1
                 ls_huret-message_v2
                 ls_huret-message_v3
                 ls_huret-message_v4
       INTO DATA(lv_msg).
      cv_type = 'E'.
      cv_message = lv_msg.
    ENDIF.
    RETURN.
  ELSE.
    IF iv_wopensu IS INITIAL.
      zcl_pallet_service=>update_ext_hu( iv_source = 'PROD'
                                         iv_prefix = CONV zde_hu_prefix( ls_hdrprop-hu_exid(3) )
                                         iv_lasthu = CONV zde_hu_lastnum( ls_hdrprop-hu_exid+3(13) ) ).
    ENDIF.
    PERFORM f_bapi_commit.
  ENDIF.

  gs_tab-su_no = ls_hukey.

ENDFORM.
*---------------------------------------------------------------------*
* BDC recording
*---------------------------------------------------------------------*
FORM bdc_dynpro USING iv_program TYPE bdc_prog
                      iv_dynpro  TYPE bdc_dynr.

  CLEAR gs_bdcdata.
  gs_bdcdata-program  = iv_program.
  gs_bdcdata-dynpro   = iv_dynpro.
  gs_bdcdata-dynbegin = 'X'.
  APPEND gs_bdcdata TO gt_bdcdata.

ENDFORM.

FORM bdc_field USING iv_fnam TYPE bdc_fnam
                     iv_fval TYPE bdc_fval.

  CLEAR gs_bdcdata.
  gs_bdcdata-fnam = iv_fnam.
  gs_bdcdata-fval = iv_fval.
  APPEND gs_bdcdata TO gt_bdcdata.

ENDFORM.

*---------------------------------------------------------------------*
* Build BDC
*---------------------------------------------------------------------*
FORM build_bdc USING iv_manufacturingorder.

  DATA: lv_value TYPE bdc_fval.

  CLEAR gt_bdcdata.

  "Screen 1
  PERFORM bdc_dynpro USING 'SAPLVHURM'
                           '3500'.

  PERFORM bdc_field  USING 'BDC_CURSOR'
                           'VHURMEAE-EXIDV_I'.

  PERFORM bdc_field USING 'BDC_OKCODE'
                          '=VHURM_GOON'.

  lv_value = iv_manufacturingorder.
  PERFORM bdc_field USING 'CAUFVD-AUFNR'
                          lv_value.

  WRITE sy-datum TO lv_value.
  PERFORM bdc_field USING 'MKPF-BLDAT'
                           lv_value.

  PERFORM bdc_field USING 'MKPF-BUDAT'
                          lv_value.

  lv_value = gs_tab-su_no.
  PERFORM bdc_field USING 'VHURMEAE-EXIDV_I'
                          lv_value.

  "Screen 2
  PERFORM bdc_dynpro USING 'SAPLVHURM'
                           '3500'.

  PERFORM bdc_field USING 'BDC_OKCODE'
                          '=VHURM_GOON'.

  PERFORM bdc_field USING 'BDC_CURSOR'
                          'VHURMHUD-PRODDATE(01)'.

  WRITE sy-datum TO lv_value.
  PERFORM bdc_field USING 'VHURMHUD-PRODDATE(01)'
                          lv_value.

  lv_value = gs_tab-batch.
  PERFORM bdc_field USING 'VHURMHUD-CHARG(01)'
                          lv_value.
  "Screen 3
  PERFORM bdc_dynpro USING 'SAPLVHURM'
                           '3500'.

  PERFORM bdc_field USING 'BDC_OKCODE'
                          '=SFCS'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_bapi_commit
*&---------------------------------------------------------------------*
*& BAPI Commit
*&---------------------------------------------------------------------*
FORM f_bapi_commit .
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = abap_true.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_bapi_rollback
*&---------------------------------------------------------------------*
*& BAPI Rollback
*&---------------------------------------------------------------------*
FORM f_bapi_rollback .
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
ENDFORM.
