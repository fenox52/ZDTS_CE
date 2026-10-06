CLASS LHC_RAP_TDAT_CTS DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      GET
        RETURNING
          VALUE(RESULT) TYPE REF TO IF_MBC_CP_RAP_TDAT_CTS.

ENDCLASS.

CLASS LHC_RAP_TDAT_CTS IMPLEMENTATION.
  METHOD GET.
    result = mbc_cp_api=>rap_tdat_cts( tdat_name = 'ZPALLETCODE'
                                       table_entity_relations = VALUE #(
                                         ( entity = 'PalletCode' table = 'ZDTS_PALLETCODE' )
                                       ) ) ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_PALLETCODE_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR PalletCodeAll
        RESULT result,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR PalletCodeAll
        RESULT result.
ENDCLASS.

CLASS LHC_ZI_PALLETCODE_S IMPLEMENTATION.
  METHOD GET_INSTANCE_FEATURES.
    DATA(edit_flag) = if_abap_behv=>fc-o-enabled.

    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    READ ENTITIES OF ZI_PalletCode_S IN LOCAL MODE
    ENTITY PalletCodeAll
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(entities)
      FAILED failed.
    result = VALUE #( FOR row IN entities (
               %TKY = row-%TKY
               %ACTION-edit = edit_flag
               %ASSOC-_PalletCode = edit_flag
    ) ).
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_PALLETCODE' ID 'ACTVT' FIELD '02'.
    DATA(is_authorized) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized ).
    result-%UPDATE      = is_authorized.
    result-%ACTION-Edit = is_authorized.
  ENDMETHOD.
ENDCLASS.
CLASS LSC_ZI_PALLETCODE_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_SAVER.
  PROTECTED SECTION.
    METHODS:
      SAVE_MODIFIED REDEFINITION,
      CLEANUP_FINALIZE REDEFINITION.
ENDCLASS.

CLASS LSC_ZI_PALLETCODE_S IMPLEMENTATION.
  METHOD SAVE_MODIFIED.
    mbc_cp_api=>rap_bc_api( )->update_last_changed_date_time(
      maintenance_object = 'ZPALLETCODE'
      entity             = 'ZI_PALLETCODE'
      create             = REF #( create )
      update             = REF #( update )
      delete             = REF #( delete ) ).
  ENDMETHOD.
  METHOD CLEANUP_FINALIZE ##NEEDED.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_PALLETCODE DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_FEATURES FOR GLOBAL FEATURES
        IMPORTING
          REQUEST REQUESTED_FEATURES FOR PalletCode
        RESULT result.
ENDCLASS.

CLASS LHC_ZI_PALLETCODE IMPLEMENTATION.
  METHOD GET_GLOBAL_FEATURES.
    DATA(edit_flag) = if_abap_behv=>fc-o-enabled.
    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    result-%UPDATE = edit_flag.
    result-%DELETE = edit_flag.
  ENDMETHOD.
ENDCLASS.
