class ZCL_POGDTL definition
  public
  final
  create public .

public section.

  interfaces IF_RAP_QUERY_PROVIDER .

  types:
    BEGIN OF gty_produom,
             product           TYPE  i_productunitsofmeasure-product,
             alternativeunit   TYPE  i_productunitsofmeasure-alternativeunit,
             quantitynumerator TYPE  i_productunitsofmeasure-quantitynumerator,
             baseunit          TYPE  i_productunitsofmeasure-baseunit,
           END OF gty_produom .

  data:
    gt_tab TYPE TABLE OF zpp_ci_pogdtl .
  constants GC_PRODCONF_ORDTYPE type RVARI_VNAM value 'ZPP_PRODCONF_ORDTYPE' ##NO_TEXT.
  constants GC_HUPRODCONF_ORDTYPE type RVARI_VNAM value 'ZPP_HUPRODCONF_ORDTYPE' ##NO_TEXT.

  methods M_GET_DATA
    importing
      !IV_PROCORD type ZPP_CI_POGDTL-MANUFACTURINGORDER
      !IV_PHASE type ZPP_CI_POGDTL-MANUFACTURINGORDEROPERATION
    exporting
      !EV_ERRMSG type STRING .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_POGDTL IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    TRY.
        IF io_request->is_data_requested( ).

          DATA(lv_offset) = io_request->get_paging( )->get_offset( ).
          DATA(lv_size)   = io_request->get_paging( )->get_page_size( ).
          DATA(lt_sort)   = io_request->get_sort_elements( ).
          DATA(lv_mrows)  = COND #( WHEN lv_size = if_rap_query_paging=>page_size_unlimited
                                    THEN 0
                                    ELSE lv_size ).

          TRY.
              " Get Filter
              DATA(lt_param) = io_request->get_parameters( ).

              LOOP AT lt_param ASSIGNING FIELD-SYMBOL(<lf_param>).
                CASE sy-tabix.
                  WHEN 1.
                    DATA(lv_procord) = <lf_param>-value.
                  WHEN 2.
                    DATA(lv_phase)    = <lf_param>-value.
                ENDCASE.
              ENDLOOP.

              me->m_get_data( EXPORTING iv_procord = CONV #( lv_procord )
                                        iv_phase   = CONV #( lv_phase )
                              IMPORTING ev_errmsg  = DATA(lv_errmsg)
              ).

              IF lv_errmsg IS NOT INITIAL.
                RAISE EXCEPTION TYPE zcx_rap_query_provider
                  EXPORTING
                    iv_msgid = 'ZPP_POC'
                    iv_msgno = 000
                    iv_msgv1 = CONV #( lv_errmsg ).
              ENDIF.

              io_response->set_total_number_of_records( 1 ).
              io_response->set_data( me->gt_tab ).

            CATCH cx_rap_query_filter_no_range INTO DATA(lo_cxrange).
              DATA(lv_msg) = lo_cxrange->get_text( ).
              RAISE EXCEPTION TYPE zcx_rap_query_provider
                EXPORTING
                  iv_msgid = 'ZPP_POC'
                  iv_msgno = 000
                  iv_msgv1 = CONV #( lv_msg ).
          ENDTRY.

        ENDIF.
      CATCH cx_rap_query_provider INTO DATA(lo_cxprvdr).
        lv_msg = lo_cxprvdr->get_text( ).
        RAISE EXCEPTION TYPE zcx_rap_query_provider
          EXPORTING
            iv_msgid = 'ZPP_POC'
            iv_msgno = 000
            iv_msgv1 = CONV #( lv_msg ).
    ENDTRY.

  ENDMETHOD.


  METHOD m_get_data.
    DATA: ls_produom TYPE gty_produom.

    SELECT sign,
           opti AS option,
           low,
           high
    FROM tvarvc
    INTO TABLE @DATA(lr_hupotype)
    WHERE name EQ @zcl_pogdtl=>gc_huprodconf_ordtype.
    IF sy-subrc NE 0.
      "do nothing
    ENDIF.

    SELECT SINGLE manufacturingorder,
                  manufacturingordertype,
                  mfgorderplannedtotalqty,
                  mfgorderconfirmedyieldqty,
                  actualdeliveredquantity,
                  productionunit,
                  orderisreleased,
                  material
    FROM i_mfgorderwithstatus WITH PRIVILEGED ACCESS
    WHERE manufacturingorder EQ @iv_procord
    INTO @DATA(ls_mforderstat).
    IF sy-subrc NE 0.
      ev_errmsg = TEXT-e01.
      RETURN.
    ENDIF.

    IF ls_mforderstat-orderisreleased NE abap_true.
      ev_errmsg = TEXT-e02.
      RETURN.
    ENDIF.

    SELECT SINGLE manufacturingorder,
                  manufacturingorderoperation,
                  operationcontrolprofile
    FROM i_manufacturingorderoperation WITH PRIVILEGED ACCESS
    WHERE manufacturingorder EQ @iv_procord
    AND   manufacturingorderoperation EQ @iv_phase
    INTO @DATA(ls_mforderoptn).
    IF sy-subrc NE 0.
      ev_errmsg = TEXT-e03.
      RETURN.
    ENDIF.

    IF ls_mforderoptn-operationcontrolprofile EQ 'ZPI4'.
    ELSE.
      ev_errmsg = TEXT-e04.
      RETURN.
    ENDIF.

    IF ls_mforderstat-manufacturingordertype IN lr_hupotype[].
        SELECT SINGLE lhmg1,
                      lhmg2,
                      lhmg3,
                      lhme1,
                      lhme2,
                      lhme3
        FROM mlgn
        INTO @DATA(ls_mlgn)
        WHERE matnr EQ @ls_mforderstat-material
        AND (  lhme1 EQ @ls_mforderstat-productionunit OR
               lhme2 EQ @ls_mforderstat-productionunit OR
               lhme3 EQ @ls_mforderstat-productionunit ).
        IF sy-subrc EQ 0.
          CASE ls_mforderstat-productionunit.
            WHEN ls_mlgn-lhme1.
              ls_produom-quantitynumerator = ls_mlgn-lhmg1.
            WHEN ls_mlgn-lhme2.
              ls_produom-quantitynumerator = ls_mlgn-lhmg2.
            WHEN ls_mlgn-lhme3.
              ls_produom-quantitynumerator = ls_mlgn-lhmg3.
          ENDCASE.
          ls_produom-alternativeunit = 'PAL'.
        ELSE.
          SELECT SINGLE product,
                        alternativeunit,
                        quantitynumerator,
                        baseunit
        FROM  i_productunitsofmeasure WITH PRIVILEGED ACCESS
        WHERE product  EQ @ls_mforderstat-material
        AND   baseunit EQ @ls_mforderstat-productionunit
        AND   alternativeunit EQ 'PAL'
        INTO @ls_produom.
          IF sy-subrc NE 0.
            ev_errmsg = TEXT-e05.
            RETURN.
          ENDIF.
        ENDIF.
    ENDIF.

    zcl_pallet_service=>get(
      EXPORTING
        iv_proc_order = iv_procord
      IMPORTING
        et_tab        = DATA(lt_tab)
    ).

    DATA(lt_tab_open) = lt_tab[].
    DELETE lt_tab_open WHERE su_status NE 'OPEN'.
    IF lt_tab_open[] IS NOT INITIAL.
      SORT lt_tab_open BY pallet_cnt ASCENDING.
      DATA(lv_palcnt) = VALUE #( lt_tab_open[ 1 ]-pallet_cnt OPTIONAL ).
    ELSE.
      lv_palcnt = lines( lt_tab ) + 1.
    ENDIF.

    APPEND INITIAL LINE TO me->gt_tab ASSIGNING FIELD-SYMBOL(<fs_tab>).
    <fs_tab>-manufacturingorder          = ls_mforderstat-manufacturingorder.
    <fs_tab>-manufacturingorderoperation = ls_mforderoptn-manufacturingorderoperation.
    <fs_tab>-operationcontrolprofile     = ls_mforderoptn-operationcontrolprofile.
    <fs_tab>-mfgorderplannedtotalqty     = ls_mforderstat-mfgorderplannedtotalqty.
    <fs_tab>-mfgorderconfirmedyieldqty   = ls_mforderstat-actualdeliveredquantity.
    <fs_tab>-productionunit              = ls_mforderstat-productionunit.
    <fs_tab>-orderisreleased             = ls_mforderstat-orderisreleased.
    <fs_tab>-material                    = ls_mforderstat-material.
    <fs_tab>-tobeconfirmedqty            = ls_produom-quantitynumerator.
    <fs_tab>-tobeprodunit                = ls_produom-alternativeunit.
    <fs_tab>-palletcount                 = lv_palcnt.

    IF ls_mforderstat-manufacturingordertype NOT IN lr_hupotype[].
        <fs_tab>-nonordertype = abap_true.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
