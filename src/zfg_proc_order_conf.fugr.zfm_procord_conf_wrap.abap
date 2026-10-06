FUNCTION zfm_procord_conf_wrap.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(MANUFACTURINGORDER) TYPE  AUFNR
*"     VALUE(MANUFACTURINGORDEROPERATION) TYPE  VORNR
*"     VALUE(PALLETCODE) TYPE  MATNR
*"     VALUE(TOBECONFIRMEDQTY) TYPE  GAMNG
*"     VALUE(TOBEPRODUNIT) TYPE  MEINS
*"  EXPORTING
*"     VALUE(EV_TYPE) TYPE  SYST_MSGTY
*"     VALUE(EV_MESSAGE) TYPE  CHAR250_D
*"----------------------------------------------------------------------

  SELECT sign,
         opti AS option,
         low,
         high
  FROM tvarvc
  INTO TABLE @gr_potype
  WHERE name EQ @zcl_pogdtl=>gc_prodconf_ordtype.
  IF sy-subrc NE 0.
    "do nothing
  ENDIF.

  SELECT sign,
         opti AS option,
         low,
         high
  FROM tvarvc
  INTO TABLE @gr_hupotype
  WHERE name EQ @zcl_pogdtl=>gc_huprodconf_ordtype.
  IF sy-subrc NE 0.
    "do nothing
  ENDIF.

  PERFORM f_check_lock USING manufacturingorder
                       CHANGING ev_type
                                ev_message.

  CHECK ev_type NE 'E'.

  PERFORM f_validate USING manufacturingorder
                           manufacturingorderoperation
                           palletcode
                           tobeconfirmedqty
                      CHANGING ev_type
                               ev_message.

  CHECK ev_type NE 'E'.

  PERFORM f_procord_confirm USING manufacturingorder
                                  manufacturingorderoperation
                                  palletcode
                                  tobeconfirmedqty
                                  tobeprodunit
                            CHANGING ev_type
                                     ev_message.

ENDFUNCTION.
