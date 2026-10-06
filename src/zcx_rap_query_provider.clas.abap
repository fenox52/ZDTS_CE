CLASS zcx_rap_query_provider DEFINITION
  PUBLIC INHERITING FROM cx_rap_query_provider
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
     IMPORTING
        previous TYPE REF TO cx_root OPTIONAL
        iv_msgid TYPE symsgid OPTIONAL
        iv_msgno TYPE symsgno OPTIONAL
        iv_msgv1 TYPE symsgv1 OPTIONAL
        iv_msgv2 TYPE symsgv2 OPTIONAL
        iv_msgv3 TYPE symsgv3 OPTIONAL
        iv_msgv4 TYPE symsgv4 OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcx_rap_query_provider IMPLEMENTATION.

 METHOD constructor ##ADT_SUPPRESS_GENERATION.
   CALL METHOD super->constructor
     EXPORTING
       previous = previous.

   me->if_t100_message~t100key = VALUE #(  msgid = iv_msgid
                                           msgno = iv_msgno
                                           attr1 = iv_msgv1
                                           attr2 = iv_msgv2
                                           attr3 = iv_msgv3
                                           attr4 = iv_msgv4
                                        ).
 ENDMETHOD.

ENDCLASS.
