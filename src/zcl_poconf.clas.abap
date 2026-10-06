CLASS zcl_poconf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: gt_tab TYPE TABLE OF zpp_ci_poconf.

    INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_poconf IMPLEMENTATION.
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
              DATA(lo_filter) = io_request->get_filter( ).

              io_response->set_total_number_of_records( 1 ).
              io_response->set_data( me->gt_tab ).

            CATCH cx_rap_query_filter_no_range INTO DATA(lo_cxrange).

          ENDTRY.

        ENDIF.
      CATCH cx_rap_query_provider INTO DATA(lo_cxprvdr).

    ENDTRY.
  ENDMETHOD.
ENDCLASS.
