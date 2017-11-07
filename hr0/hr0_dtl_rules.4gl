globals "hr0_dtl_global.4gl"

define
  m_initialized boolean
  

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

  declare c_sickLeave cursor for
    select *
    from sickleave
    where employee_no = ?

  declare c_annualLeave cursor for
    select *
    from annualleave
    where employee_no = ?
    
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
