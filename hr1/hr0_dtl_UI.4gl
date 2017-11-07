GLOBALS "hr0_hdr_global.4gl"
GLOBALS "hr0_dtl_global.4gl"


#
# hr0detail_View:
#
FUNCTION Employee_Detail(p_mode)

DEFINE
  p_mode STRING
  
  OPEN WINDOW w_hr0detail WITH FORM "hr0_dtl_" || g_version

  CALL EmpDet_Get()
  
  DISPLAY BY NAME
    g_empdet.startdate,
    g_empdet.position,
    g_empdet.taxnumber,
    g_empdet.base,
    g_empdet.basetype
  CALL PaySummary_View(TRUE)
  CALL SickLeave_View(TRUE)
  CALL AnnualLeave_View(TRUE)

  IF p_mode = "EDIT"
  THEN
    CALL EmpDet_Edit()
  ELSE
    MENU ""
      -- COMMAND "Update" "Update Pay Details"
      --  CALL hr0detail_Edit()

      COMMAND "Pay Summary" "View Pay Summary"
        CALL PaySummary_View(FALSE)

      COMMAND "Sick Leave" "View Sick Leave Transactions"
        CALL SickLeave_View(FALSE)

      COMMAND "Annual Leave" "View Annual Leave Transactions"
        CALL AnnualLeave_View(FALSE)

      COMMAND "Exit"
        EXIT MENU
    END MENU
  END IF
  
  CLOSE WINDOW w_hr0detail
  
END FUNCTION


#
# EmpDet_Edit:   Edit details
#
FUNCTION EmpDet_Edit()

  DEFINE
    p_next STRING 

  LET p_next = "DETAIL"
  WHILE p_next != "EXIT"

    CASE p_next
    WHEN "DETAIL"
      LET p_next = "PAYSUMMARY"
      INPUT BY NAME
        g_empdet.startdate,
        g_empdet.position,
        g_empdet.taxnumber,
        g_empdet.basetype,
        g_empdet.base
        ATTRIBUTES (WITHOUT DEFAULTS)
        ON ACTION exit
          LET p_next = "EXIT"
        ON ACTION NEXT
          EXIT INPUT
      END INPUT

    WHEN "PAYSUMMARY"
      LET p_next = "SICK"
      INPUT ARRAY ga_pay FROM pay_scr.*
        ATTRIBUTES (WITHOUT DEFAULTS)
        ON ACTION exit
          LET p_next = "EXIT"
        ON ACTION prev
          LET p_next = "DETAIL"
      END INPUT 

    WHEN "SICK"
      LET p_next = "ANNUAL"
      INPUT ARRAY ga_sick FROM sick_scr.*
        ATTRIBUTES (WITHOUT DEFAULTS)
          ON ACTION exit
            LET p_next = "EXIT"
          ON ACTION prev
            LET p_next = "PAYSUMMARY"
        END INPUT 

    WHEN "ANNUAL"
      LET p_next = "DETAIL"        
      INPUT ARRAY ga_annual FROM annual_scr.*
        ATTRIBUTES (WITHOUT DEFAULTS)
          ON ACTION exit
            LET p_next = "EXIT"
          ON ACTION prev
            LET p_next = "SICK"
        END INPUT 
    END CASE
    
  END WHILE
  
END FUNCTION


#
# PaySummary_View
#
FUNCTION PaySummary_View(p_init)

  DEFINE
    p_init BOOLEAN

  DISPLAY ARRAY ga_pay TO pay_scr.*
    BEFORE DISPLAY
      IF p_init
      THEN
        EXIT DISPLAY
      END IF
      MESSAGE "Scroll to view a summary of salary/wage payments" 
  END DISPLAY
  
  LET int_flag = 0
END FUNCTION


#
# AnnualLeave_View
#
FUNCTION AnnualLeave_View(p_init)

  DEFINE
    p_init BOOLEAN
    
  DISPLAY ARRAY ga_annual TO annual_scr.*
    BEFORE DISPLAY
      IF p_init
      THEN
        EXIT DISPLAY
      END IF
      MESSAGE "Scroll to view a summary of annual leave adjustments" 
  END DISPLAY
  
  LET int_flag = 0
END FUNCTION


#
# SickLeave_View
#
FUNCTION SickLeave_View(p_init)

  DEFINE
    p_init BOOLEAN

  DISPLAY ARRAY ga_sick TO sick_scr.*
    BEFORE DISPLAY
      IF p_init
      THEN
        EXIT DISPLAY
      END IF
      MESSAGE "Scroll to view a summary of sick leave adjustments" 
  END DISPLAY
  
  LET int_flag = 0
END FUNCTION