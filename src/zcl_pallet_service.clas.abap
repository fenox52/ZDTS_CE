class ZCL_PALLET_SERVICE definition
  public
  final
  create public .

public section.

  types:
    tty_palletid TYPE TABLE OF zpp_palletid .
  types:
    tty_su     TYPE TABLE OF zpp_palletid-su_no .

  class-data GC_PALLET_ID_PDF type FPNAME value 'ZF_PP_PALLET_ID' ##NO_TEXT.

  class-methods INSERT
    importing
      !IS_TAB type ZPP_PALLETID .
  class-methods UPDATE
    importing
      !IS_TAB type ZPP_PALLETID .
  class-methods GET
    importing
      !IV_PROC_ORDER type AUFNR
    exporting
      !ET_TAB type TTY_PALLETID .
  class-methods GET_SU
    importing
      !IT_SU type TTY_SU
    exporting
      !ET_TAB type TTY_PALLETID .
  class-methods PRINT
    importing
      !IS_TAB type ZPP_PALLETID
      !IV_PREVIEW type BOOLEAN default ABAP_FALSE .
  class-methods GET_EXT_HU
    importing
      !IV_SOURCE type ZDE_HU_SOURCE
      !IV_PLANT type WERKS_D
    returning
      value(RV_HUKEY) type EXIDV .
  class-methods UPDATE_EXT_HU
    importing
      !IV_SOURCE type ZDE_HU_SOURCE
      !IV_PREFIX type ZDE_HU_PREFIX
      !IV_LASTHU type ZDE_HU_LASTNUM .
  class-methods DATE_FORMAT_01
    importing
      !IV_DATE type SY-DATUM
    returning
      value(RV_VALUE) type STRING .
protected section.
private section.
ENDCLASS.



CLASS ZCL_PALLET_SERVICE IMPLEMENTATION.


METHOD get.

  SELECT *
  FROM zpp_palletid
  INTO TABLE @et_tab
  WHERE proc_order EQ @iv_proc_order.
  IF sy-subrc EQ 0.
    SORT et_tab BY proc_order
                   pallet_cnt   DESCENDING.
  ENDIF.

ENDMETHOD.


METHOD insert.

  SELECT SINGLE *
  INTO @DATA(ls_pallet)
  FROM zpp_palletid
  WHERE proc_order   EQ @is_tab-proc_order
  AND   pallet_cnt   EQ @is_tab-pallet_cnt
  AND   su_no        EQ @is_tab-su_no.
  IF sy-subrc EQ 0.
    RETURN.
  ENDIF.

  INSERT zpp_palletid FROM is_tab.

ENDMETHOD.


METHOD update.

  SELECT SINGLE *
  FROM zpp_palletid
  INTO @DATA(ls_tab)
  WHERE  proc_order  EQ @is_tab-proc_order
  AND   pallet_cnt   EQ @is_tab-pallet_cnt
  AND   su_no        EQ @is_tab-su_no.
  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

  MODIFY zpp_palletid FROM is_tab.

ENDMETHOD.


METHOD get_su.

  IF it_su[] IS NOT INITIAL.
    SELECT *
    INTO TABLE @et_tab
    FROM zpp_palletid
    FOR ALL ENTRIES IN @it_su
    WHERE su_no EQ @it_su-table_line.
    IF sy-subrc NE 0.
      RETURN.
    ENDIF.
  ENDIF.

ENDMETHOD.


METHOD print.

  DATA: lv_fm_name      TYPE rs38l_fnam,
        ls_outputparams TYPE sfpoutputparams,
        ls_formoutput   TYPE fpformoutput,
        ls_print_params TYPE pri_params,
        ls_default      TYPE usdefaults.

  DATA: ls_tab  TYPE zst_pp_pallet_dtl.

  ls_tab-material      = is_tab-material.
  ls_tab-mat_desc      = is_tab-mat_desc.
  ls_tab-qty           = is_tab-qty.
  ls_tab-uom           = is_tab-uom.
  ls_tab-batch         = is_tab-batch.
  ls_tab-process_order = is_tab-proc_order.
  ls_tab-prod_date     = is_tab-mfg_date.
  ls_tab-exp_date      = is_tab-sled_bbd.
  ls_tab-prod_line     = is_tab-prod_line.
  ls_tab-shift         = is_tab-shift.
  ls_tab-su_no         = is_tab-su_no.

  GET TIME STAMP FIELD DATA(lv_timestamp).
  DATA(lv_dt) = |{ lv_timestamp TIMESTAMP = ISO TIMEZONE = sy-zonlo }|.
  ls_tab-datetime = |{ lv_dt+5(2) }{ lv_dt+8(2) }{ lv_dt(4) }{ lv_dt+11(2) }{ lv_dt+14(2) }|.
  ls_tab-user     = sy-uname.

  CALL FUNCTION 'SUSR_USER_DEFAULTS_GET'
    EXPORTING
      user_name           = sy-uname
    IMPORTING
      user_defaults       = ls_default
    EXCEPTIONS
      user_name_not_exist = 1
      OTHERS              = 2.
  IF sy-subrc <> 0.
    "Do nothing
  ENDIF.

  IF ls_default-spld IS INITIAL.
    ls_default-spld = 'LP01'.
  ENDIF.

  "--Print Pallet ID
  CALL FUNCTION 'GET_PRINT_PARAMETERS'
    EXPORTING
      no_dialog              = abap_true
      destination            = ls_default-spld
      immediately            = ' '
      new_list_id            = abap_true
    IMPORTING
      out_parameters         = ls_print_params
    EXCEPTIONS
      archive_info_not_found = 1
      invalid_print_params   = 2
      invalid_archive_params = 3
      OTHERS                 = 4.
  IF sy-subrc NE 0.
    "do nothing
  ENDIF.

  ls_outputparams-device   = 'PRINTER'.
  ls_outputparams-dest     = ls_print_params-pdest.
  ls_outputparams-nodialog = abap_true.
  ls_outputparams-preview  = COND #( WHEN iv_preview IS NOT INITIAL THEN abap_true  ELSE abap_false ).
  ls_outputparams-reqnew   = COND #( WHEN iv_preview IS NOT INITIAL THEN abap_false ELSE abap_true  ).
  ls_outputparams-reqimm   = COND #( WHEN iv_preview IS NOT INITIAL THEN abap_false ELSE abap_true  ).

  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = ls_outputparams
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.
  IF sy-subrc NE 0.
    "do nothing
  ENDIF.

  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name     = gc_pallet_id_pdf
    IMPORTING
      e_funcname = lv_fm_name.
  IF sy-subrc NE 0.
    "do nothing
  ENDIF.

  CALL FUNCTION lv_fm_name
    EXPORTING
      is_pallet_dtl      = ls_tab
    IMPORTING
      /1bcdwb/formoutput = ls_formoutput
    EXCEPTIONS
      usage_error        = 1
      system_error       = 2
      internal_error     = 3
      OTHERS             = 4.
  IF sy-subrc NE 0.
    "do nothing
  ENDIF.

  CALL FUNCTION 'FP_JOB_CLOSE'
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
  IF sy-subrc NE 0.
    "do nothing
  ENDIF.

ENDMETHOD.


METHOD date_format_01.
  IF iv_date IS INITIAL OR iv_date = '00000000'.
    RETURN.
  ENDIF.

  DATA: lv_month_str TYPE c LENGTH 3.

  CASE iv_date+4(2).
    WHEN '01'. lv_month_str = 'JAN'.
    WHEN '02'. lv_month_str = 'FEB'.
    WHEN '03'. lv_month_str = 'MAR'.
    WHEN '04'. lv_month_str = 'APR'.
    WHEN '05'. lv_month_str = 'MAY'.
    WHEN '06'. lv_month_str = 'JUN'.
    WHEN '07'. lv_month_str = 'JUL'.
    WHEN '08'. lv_month_str = 'AUG'.
    WHEN '09'. lv_month_str = 'SEP'.
    WHEN '10'. lv_month_str = 'OCT'.
    WHEN '11'. lv_month_str = 'NOV'.
    WHEN '12'. lv_month_str = 'DEC'.
  ENDCASE.

  rv_value = to_upper( |{ iv_date+6(2) }{ lv_month_str }{ iv_date(4) }| ).
ENDMETHOD.


METHOD get_ext_hu.

  SELECT SINGLE t1~*,
                t2~*
  FROM zdts_hu_prefix AS t1
  INNER JOIN zdts_lasthu AS t2
  ON  t1~source EQ t2~source
  AND t1~prefix EQ t2~prefix
  WHERE t1~source EQ @iv_source
  AND   t1~plant  EQ @iv_plant
  INTO @DATA(ls_tab).
  IF sy-subrc EQ 0.
    ADD 1 TO ls_tab-t2-last_hu_no.
    rv_hukey = |{ ls_tab-t1-prefix }{ ls_tab-t2-last_hu_no }|.
  ENDIF.

ENDMETHOD.


METHOD update_ext_hu.
  DATA: ls_tab TYPE zdts_lasthu.

  ls_tab-source = iv_source.
  ls_tab-prefix = iv_prefix.
  ls_tab-last_hu_no = iv_lasthu.

  MODIFY zdts_lasthu FROM ls_tab.
  IF sy-subrc EQ 0.
    "do nothing
  ENDIF.
ENDMETHOD.
ENDCLASS.
