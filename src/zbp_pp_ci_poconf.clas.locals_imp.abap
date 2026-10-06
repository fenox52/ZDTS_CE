CLASS lhc_poconf DEFINITION INHERITING FROM cl_abap_behavior_handler .

  PUBLIC SECTION.

    CLASS-DATA: gt_tab TYPE TABLE FOR CREATE zpp_ci_poconf.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR poconf RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE poconf.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE poconf.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE poconf.

    METHODS read FOR READ
      IMPORTING keys FOR READ poconf RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK poconf.

ENDCLASS.

CLASS lhc_poconf IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.

    "Pass payload to buffer
    LOOP AT entities INTO DATA(ls_entity).
      APPEND INITIAL LINE TO gt_tab ASSIGNING FIELD-SYMBOL(<fs_tab>).
      MOVE-CORRESPONDING ls_entity TO <fs_tab>.
    ENDLOOP.

  ENDMETHOD.

  METHOD update.
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zpp_ci_poconf DEFINITION INHERITING FROM cl_abap_behavior_saver_failed.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS adjust_numbers REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lcl_arfc_poconf DEFINITION.
  PUBLIC SECTION.

    DATA:
      mv_completed TYPE boolean,
      mv_type      TYPE syst_msgty,
      mv_message   TYPE char250.

    METHODS: start_afm_run   IMPORTING is_tab TYPE zpp_ci_poconf,
             get_afm_ret     IMPORTING p_task TYPE clike.

ENDCLASS.

CLASS lsc_zpp_ci_poconf IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD adjust_numbers.

    DATA: ls_tab TYPE zpp_ci_poconf.

    DATA(ls_tabc) = lhc_poconf=>gt_tab[ 1 ].
    MOVE-CORRESPONDING ls_tabc TO ls_tab.

    DATA(lo_run) = NEW lcl_arfc_poconf( ).
    lo_run->start_afm_run( EXPORTING is_tab = ls_tab ).

    DATA(lv_msgv1) = lo_run->mv_message(50).
    IF strlen( lo_run->mv_message ) GT 50.
       DATA(lv_msgv2) = lo_run->mv_message+50(50).
    ENDIF.

    CASE lo_run->mv_type.
      WHEN 'E'.
        APPEND INITIAL LINE TO reported-poconf ASSIGNING FIELD-SYMBOL(<lf_rep>).
        <lf_rep>-%msg = new_message(
          id     = 'ZPP_POC'
          number = 000
          v1     = lv_msgv1
          v2     = lv_msgv2
          severity = if_abap_behv_message=>severity-error ).
        <lf_rep>-%element-manufacturingorder = if_abap_behv=>mk-on.
        MOVE-CORRESPONDING ls_tabc TO <lf_rep>.

        APPEND INITIAL LINE TO failed-poconf ASSIGNING FIELD-SYMBOL(<lf_err>).
        MOVE-CORRESPONDING ls_tabc TO <lf_err>.
      WHEN 'S'.
        APPEND INITIAL LINE TO reported-poconf ASSIGNING FIELD-SYMBOL(<lf_poconf>).
        <lf_poconf>-%msg = new_message(
          id     = 'ZPP_POC'
          number = 000
          v1     = lv_msgv1
          v2     = lv_msgv2
          severity = if_abap_behv_message=>severity-success ).
        MOVE-CORRESPONDING ls_tabc TO <lf_poconf>.
    ENDCASE.

  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_arfc_poconf IMPLEMENTATION.

  METHOD start_afm_run.

    CALL FUNCTION 'ZFM_PROCORD_CONF_WRAP'
      STARTING NEW TASK 'TASK1' DESTINATION 'NONE'
      CALLING get_afm_ret ON END OF TASK
      EXPORTING
        manufacturingorder          = is_tab-manufacturingorder
        manufacturingorderoperation = is_tab-manufacturingorderoperation
        palletcode                  = is_tab-PalletCode
        tobeconfirmedqty            = is_tab-tobeconfirmedqty
        tobeprodunit                = is_tab-tobeprodunit
      EXCEPTIONS
        communication_failure       = 1
        system_failure              = 2
        resource_failure            = 3
        OTHERS                      = 4.
    IF sy-subrc NE 0.
       "do nothing
    ENDIF.

    WAIT FOR ASYNCHRONOUS TASKS UNTIL mv_completed EQ abap_true.

  ENDMETHOD.

  METHOD get_afm_ret.

    IF p_task EQ 'TASK1'.
      RECEIVE RESULTS FROM FUNCTION 'ZFM_PROCORD_CONF_WRAP'
        IMPORTING
          ev_type    = mv_type
          ev_message = mv_message
        EXCEPTIONS
          OTHERS = 0.
      mv_completed  = abap_true.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
