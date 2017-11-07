GLOBALS "hr0_hdr_global.4gl"
GLOBALS "hr0_dtl_global.4gl"

define
  m_initialized boolean

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
    g_empdet.basetype,
    g_empdet.annual_balance,
    g_empdet.sick_balance
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
        ON ACTION EXIT
          LET p_next = "EXIT"
        ON ACTION NEXT
          EXIT INPUT
      END INPUT

    WHEN "PAYSUMMARY"
      LET p_next = PaySummary_Edit()

    WHEN "SICK"
      LET p_next = SickLeave_Edit()

    WHEN "ANNUAL"
      LET p_next = AnnualLeave_Edit()

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
# PaySummary_Edit
#
FUNCTION PaySummary_Edit()

  INPUT ARRAY ga_pay FROM pay_scr.*
    ATTRIBUTES (WITHOUT DEFAULTS)
    
    ON CHANGE pay_date, pay_amount
      CALL Base_Set()
      
    ON ACTION EXIT
      RETURN "EXIT"
      
    ON ACTION prev
      RETURN "DETAIL"
  END INPUT 
  CALL Base_Set()
  
  RETURN "SICK"
  
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
# AnnualLeave_Edit
#
FUNCTION AnnualLeave_Edit()
      
  INPUT ARRAY ga_annual FROM annual_scr.*
    ATTRIBUTES (WITHOUT DEFAULTS)
    
    ON CHANGE annual_date, annual_runningbalance
      CALL AnnualLeave_Balance()
      
    ON ACTION exit
      RETURN "EXIT"
      
    ON ACTION prev
      RETURN "SICK"
  END INPUT 
  CALL AnnualLeave_Balance()

  RETURN iif(g_version = "GUI", "DETAIL", "EXIT")

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

#
# SickLeave_Edit
#
FUNCTION SickLeave_Edit()

  INPUT ARRAY ga_sick FROM sick_scr.*
    ATTRIBUTES (WITHOUT DEFAULTS)
      ON CHANGE sick_date, sick_runningbalance 
        CALL SickLeave_Balance()
        
      AFTER DELETE
        CALL SickLeave_Balance()

      ON ACTION EXIT
        RETURN "EXIT"
        
      ON ACTION prev
        RETURN "PAYSUMMARY"
  END INPUT
  CALL SickLeave_Balance()
  
  RETURN "ANNUAL"
        
END FUNCTION


#
# EmpDet_Init:  Initaliation for details
#
function EmpDet_Init()

  if m_initialized
  then
    return
  end if
  
  declare c_paySummary cursor for
    select *
    from paysummary
    where employee_no = ?
    order by pay_date desc

  declare c_sickLeave cursor for
    select *
    from sickleave
    where employee_no = ?
    order by sick_date desc

  declare c_annualLeave cursor for
    select *
    from annualleave
    where employee_no = ?
    order by annual_date desc
    
end function


#
# EmpDet_Get: get details
#

function EmpDet_Get()

  define
    r_pay record like paysummary.*,
    r_sick record like sickleave.*,
    r_annual record like annualleave.*,
    idx integer

    
  call EmpDet_Init()
  
  # Pay Summary
  let idx = 0
  foreach c_paysummary using g_empdet.employee_no into r_pay.*
    let ga_pay[idx:=idx+1].pay_date = r_pay.pay_date
    let ga_pay[idx].pay_amount = r_pay.pay_amount
  end foreach

  # Sick Leave
  let idx = 0
  foreach c_sickleave using g_empdet.employee_no into r_sick.*
    let ga_sick[idx:=idx+1].sick_adjustment = r_sick.sick_adjustment
    let ga_sick[idx].sick_date = r_sick.sick_date
    let ga_sick[idx].sick_runningbalance = r_sick.sick_runningbalance
  end foreach

  # Annual Leave
  let idx = 0
  foreach c_annualleave using g_empdet.employee_no into r_annual.*
    let ga_annual[idx:=idx+1].annual_adjustment = r_annual.annual_adjustment
    let ga_annual[idx].annual_date = r_annual.annual_date
    let ga_annual[idx].annual_runningbalance = r_annual.annual_runningbalance
  end foreach
  
end function


#
# EmpDet_Put: Put details away
#

function EmpDet_Upsert(p_mode)

  define
    p_mode string,
    idx integer


  # begin work
  delete from paysummary where employee_no = g_empdet.employee_no
  if p_mode != "DELETE"
  then
    let idx = 0
    for idx = 1 to ga_pay.getLength()
      insert into paysummary values(
        g_empdet.employee_no,
        ga_pay[idx].pay_date,
        ga_pay[idx].pay_amount
        )
    end for
  end if 

  delete from sickleave where employee_no = g_empdet.employee_no
  if p_mode != "DELETE"
  then
    let idx = 0
    for idx = 1 to ga_sick.getLength()
      insert into sickleave values(
        g_empdet.employee_no,
        ga_sick[idx].sick_date,
        ga_sick[idx].sick_adjustment,
        ga_sick[idx].sick_runningbalance
        )
    end for
  end if 

  delete from annualleave where employee_no = g_empdet.employee_no
  if p_mode != "DELETE"
  then
    let idx = 0
    for idx = 1 to ga_annual.getLength()
      insert into annualleave values(
        g_empdet.employee_no,
        ga_annual[idx].annual_date,
        ga_annual[idx].annual_adjustment,
        ga_annual[idx].annual_runningbalance
        )
    end for
  end if 
  # end work
end function

#############################################################################
#
# Base_Set: Set base pay frompay details
#
#############################################################################
public function Base_Set()
  define
    idx integer,
    l_date date,
    l_base like employee.base
    

  let l_date = "01/01/1900"
  let l_base = 0

  for idx = 1 to ga_pay.getLength()
    if ga_pay[idx].pay_date > l_date
    then
      let l_base = ga_pay[idx].pay_amount
      let l_date = ga_pay[idx].pay_date
    end if
  end for

  let g_empdet.base = l_base
  display by name g_empdet.base
  
end function



#############################################################################
#
# AnnualLeave_Balance
#
#############################################################################
public function AnnualLeave_Balance()
  define
    idx integer,
    l_date date,
    l_balance like employee.annual_balance
    

  let l_date = "01/01/1900"
  let l_balance = 0

  for idx = 1 to ga_annual.getLength()
    if ga_annual[idx].annual_date > l_date
    then
      let l_balance = ga_annual[idx].annual_runningbalance
      let l_date = ga_annual[idx].annual_date
    end if
  end for

  let g_empdet.annual_balance = l_balance
  display by name g_empdet.annual_balance
  
end function




#############################################################################
#
# SickLeave_Balance
#
#############################################################################
public function SickLeave_Balance()
  define
    idx integer,
    l_date date,
    l_balance like employee.sick_balance
    

  let l_date = "01/01/1900"
  let l_balance = 0

  for idx = 1 to ga_sick.getLength()
    if ga_sick[idx].sick_date > l_date
    then
      let l_balance = ga_sick[idx].sick_runningbalance
      let l_date = ga_sick[idx].sick_date
    end if
  end for

  let g_empdet.sick_balance = l_balance
  display by name g_empdet.sick_balance
  
end function