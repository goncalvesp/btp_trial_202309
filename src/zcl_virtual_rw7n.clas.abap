class zcl_virtual_rw7n definition public final create public .
  public section.
    interfaces if_sadl_exit_calc_element_read .
  protected section.
  private section.
endclass.



class zcl_virtual_rw7n implementation.
  method if_sadl_exit_calc_element_read~calculate.
    data lt_travels type standard table of zrap100_c_traveltp_rw7 with default key.

    lt_travels = corresponding #( it_original_data ).
    loop at lt_travels assigning field-symbol(<ls_travel>).
      case <ls_travel>-OverallStatus.
        when 'X'.
          <ls_travel>-Criticality = 1. "'Rejected' --> red
        when 'O'.
          <ls_travel>-Criticality = 2. "'Open'     --> yellow
        when 'A'.
          <ls_travel>-Criticality = 3. "'Accepted' --> green
        when others.
          <ls_travel>-Criticality = 0. "invalid    --> grey
      endcase.
    endloop.
    ct_calculated_data = corresponding #( lt_travels ).
  endmethod.

  method if_sadl_exit_calc_element_read~get_calculation_info.

  endmethod.
endclass.
