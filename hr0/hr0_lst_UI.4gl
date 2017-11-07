GLOBALS "hr0_hdr_global.4gl"

#
# Employee_List: Browse through list of selected employees
#

FUNCTION Employee_List(p_mode, p_idx)

  DEFINE
    p_mode STRING,
    p_idx INTEGER,
    l_idx INTEGER
  
  OPEN WINDOW w_hr0list WITH FORM "hr0_lst_" || g_version

  LET l_idx = 0
  DISPLAY ARRAY ga_empList TO emp_list.* ATTRIBUTES(COUNT=-1)
    BEFORE DISPLAY
      CALL dialog.setCurrentRow("emp_list", p_idx)
    ON ACTION accept
      LET l_idx = ARR_CURR()
      EXIT DISPLAY
  END DISPLAY
  
  CLOSE WINDOW w_hr0list

  RETURN l_idx
  
END FUNCTION


