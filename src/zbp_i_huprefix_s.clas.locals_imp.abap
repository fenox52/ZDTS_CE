CLASS LHC_RAP_TDAT_CTS DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      GET
        RETURNING
          VALUE(RESULT) TYPE REF TO IF_MBC_CP_RAP_TDAT_CTS.

ENDCLASS.

CLASS LHC_RAP_TDAT_CTS IMPLEMENTATION.
  METHOD GET.
    result = mbc_cp_api=>rap_tdat_cts( tdat_name = 'ZHUPREFIX'
                                       table_entity_relations = VALUE #(
                                         ( entity = 'HuPrefix' table = 'ZDTS_HU_PREFIX' )
                                       ) ) ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_HUPREFIX_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR HuPrefixAll
        RESULT result,
      SELECTCUSTOMIZINGTRANSPTREQ FOR MODIFY
        IMPORTING
          KEYS FOR ACTION HuPrefixAll~SelectCustomizingTransptReq
        RESULT result,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR HuPrefixAll
        RESULT result.
ENDCLASS.

CLASS LHC_ZI_HUPREFIX_S IMPLEMENTATION.
  METHOD GET_INSTANCE_FEATURES.
    DATA(selecttransport_flag) = if_abap_behv=>fc-o-enabled.
    DATA(edit_flag) = if_abap_behv=>fc-o-enabled.

    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    IF lhc_rap_tdat_cts=>get( )->is_transport_allowed( ) = abap_false.
      selecttransport_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    READ ENTITIES OF ZI_HuPrefix_S IN LOCAL MODE
    ENTITY HuPrefixAll
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(entities)
      FAILED failed.
    result = VALUE #( FOR row IN entities (
               %TKY = row-%TKY
               %ACTION-edit = edit_flag
               %ASSOC-_HuPrefix = edit_flag
               %ACTION-SelectCustomizingTransptReq = COND #( WHEN row-%is_draft = if_abap_behv=>mk-off
                                                             THEN if_abap_behv=>fc-o-disabled
                                                             ELSE selecttransport_flag ) ) ).
  ENDMETHOD.
  METHOD SELECTCUSTOMIZINGTRANSPTREQ.
    MODIFY ENTITIES OF ZI_HuPrefix_S IN LOCAL MODE
      ENTITY HuPrefixAll
        UPDATE FIELDS ( TransportRequestID HideTransport )
        WITH VALUE #( FOR key IN keys
                        ( %TKY               = key-%TKY
                          TransportRequestID = key-%PARAM-transportrequestid
                          HideTransport      = abap_false ) )
                          FAILED failed.

    READ ENTITIES OF ZI_HuPrefix_S IN LOCAL MODE
      ENTITY HuPrefixAll
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(entities).
    result = VALUE #( FOR entity IN entities
                        ( %TKY   = entity-%TKY
                          %PARAM = entity ) ).
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_HUPREFIX' ID 'ACTVT' FIELD '02'.
    DATA(is_authorized) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized ).
    result-%UPDATE      = is_authorized.
    result-%ACTION-Edit = is_authorized.
    result-%ACTION-SelectCustomizingTransptReq = is_authorized.
  ENDMETHOD.
ENDCLASS.
CLASS LSC_ZI_HUPREFIX_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_SAVER.
  PROTECTED SECTION.
    METHODS:
      SAVE_MODIFIED REDEFINITION,
      CLEANUP_FINALIZE REDEFINITION.
ENDCLASS.

CLASS LSC_ZI_HUPREFIX_S IMPLEMENTATION.
  METHOD SAVE_MODIFIED.
    READ TABLE update-HuPrefixAll INDEX 1 INTO DATA(all).
    IF all-TransportRequestID IS NOT INITIAL.
      lhc_rap_tdat_cts=>get( )->record_changes(
                                  transport_request = all-TransportRequestID
                                  create            = REF #( create )
                                  update            = REF #( update )
                                  delete            = REF #( delete ) ).
    ENDIF.
    mbc_cp_api=>rap_bc_api( )->update_last_changed_date_time(
      maintenance_object = 'ZHUPREFIX'
      entity             = 'ZI_HUPREFIX'
      create             = REF #( create )
      update             = REF #( update )
      delete             = REF #( delete ) ).
  ENDMETHOD.
  METHOD CLEANUP_FINALIZE ##NEEDED.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_HUPREFIX DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      VALIDATETRANSPORTREQUEST FOR VALIDATE ON SAVE
        IMPORTING
          KEYS FOR HuPrefix~ValidateTransportRequest,
      GET_GLOBAL_FEATURES FOR GLOBAL FEATURES
        IMPORTING
          REQUEST REQUESTED_FEATURES FOR HuPrefix
        RESULT result.
ENDCLASS.

CLASS LHC_ZI_HUPREFIX IMPLEMENTATION.
  METHOD VALIDATETRANSPORTREQUEST.
    DATA change TYPE REQUEST FOR CHANGE ZI_HuPrefix_S.
    READ ENTITIES OF ZI_HuPrefix_S IN LOCAL MODE
      ENTITY HuPrefix BY \_HuPrefixAll
      FIELDS ( TransportRequestID )
      WITH CORRESPONDING #( keys )
      RESULT DATA(transport_from_singleton).
    lhc_rap_tdat_cts=>get( )->validate_changes(
                                transport_request = VALUE #( transport_from_singleton[ 1 ]-TransportRequestID OPTIONAL )
                                table             = 'ZDTS_HU_PREFIX'
                                keys              = REF #( keys )
                                reported          = REF #( reported )
                                failed            = REF #( failed )
                                change            = REF #( change-HuPrefix ) ).
  ENDMETHOD.
  METHOD GET_GLOBAL_FEATURES.
    DATA(edit_flag) = if_abap_behv=>fc-o-enabled.
    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    result-%UPDATE = edit_flag.
    result-%DELETE = edit_flag.
  ENDMETHOD.
ENDCLASS.
