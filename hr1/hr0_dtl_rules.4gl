GLOBALS "hr0_dtl_global.4gl"

DEFINE
  m_initialized BOOLEAN
  

#
# EmpDet_Init:  Initaliation for details
#
FUNCTION EmpDet_Init()

  IF m_initialized
  THEN
    RETURN
  END IF
  
  DECLARE c_paySummary CURSOR FOR
    SELECT *
    FROM paysummary
    WHERE employee_no = ?

  DECLARE c_sickLeave CURSOR FOR
    SELECT *
    FROM sickleave
    WHERE employee_no = ?

  DECLARE c_annualLeave CURSOR FOR
    SELECT *
    FROM annualleave
    WHERE employee_no = ?
    
END FUNCTION


#
# EmpDet_Get: get details
#

FUNCTION EmpDet_Get()

  DEFINE
    r_pay RECORD LIKE paysummary.*,
    r_sick RECORD LIKE sickleave.*,
    r_annual RECORD LIKE annualleave.*,
    idx INTEGER

    
  CALL EmpDet_Init()
  
  # Pay Summary
  LET idx = 0
  FOREACH c_paysummary USING g_empdet.employee_no INTO r_pay.*
    LET ga_pay[idx:=idx+1].pay_date = r_pay.pay_date
    LET ga_pay[idx].pay_amount = r_pay.pay_amount
  END FOREACH

  # Sick Leave
  LET idx = 0
  FOREACH c_sickleave USING g_empdet.employee_no INTO r_sick.*
    LET ga_sick[idx:=idx+1].sick_adjustment = r_sick.sick_adjustment
    LET ga_sick[idx].sick_date = r_sick.sick_date
    LET ga_sick[idx].sick_runningbalance = r_sick.sick_runningbalance
  END FOREACH

  # Annual Leave
  LET idx = 0
  FOREACH c_annualleave USING g_empdet.employee_no INTO r_annual.*
    LET ga_annual[idx:=idx+1].annual_adjustment = r_annual.annual_adjustment
    LET ga_annual[idx].annual_date = r_annual.annual_date
    LET ga_annual[idx].annual_runningbalance = r_annual.annual_runningbalance
  END FOREACH
  
END FUNCTION


#
# EmpDet_Put: Put details away
#

FUNCTION EmpDet_Upsert(p_mode)

  DEFINE
    p_mode STRING,
    idx INTEGER


  # begin work
  DELETE FROM paysummary WHERE employee_no = g_empdet.employee_no
  IF p_mode != "DELETE"
  THEN
    LET idx = 0
    FOR idx = 1 TO ga_pay.getLength()
      INSERT INTO paysummary VALUES(
        g_empdet.employee_no,
        ga_pay[idx].pay_date,
        ga_pay[idx].pay_amount
        )
    END FOR
  END IF 

  DELETE FROM sickleave WHERE employee_no = g_empdet.employee_no
  IF p_mode != "DELETE"
  THEN
    LET idx = 0
    FOR idx = 1 TO ga_sick.getLength()
      INSERT INTO sickleave VALUES(
        g_empdet.employee_no,
        ga_sick[idx].sick_date,
        ga_sick[idx].sick_adjustment,
        ga_sick[idx].sick_runningbalance
        )
    END FOR
  END IF 

  DELETE FROM annualleave WHERE employee_no = g_empdet.employee_no
  IF p_mode != "DELETE"
  THEN
    LET idx = 0
    FOR idx = 1 TO ga_annual.getLength()
      INSERT INTO annualleave VALUES(
        g_empdet.employee_no,
        ga_annual[idx].annual_date,
        ga_annual[idx].annual_adjustment,
        ga_annual[idx].annual_runningbalance
        )
    END FOR
  END IF 
  # end work
END FUNCTION
