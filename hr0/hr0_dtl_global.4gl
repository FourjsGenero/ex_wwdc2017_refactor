SCHEMA hr

GLOBALS

DEFINE g_empdet RECORD
    employee_no LIKE employee.employee_no,
    name STRING,
    startdate LIKE employee.startdate,
    position LIKE employee.position,
    taxnumber LIKE employee.taxnumber,
    base LIKE employee.base,
    basetype LIKE employee.basetype,
    sick_balance LIKE employee.sick_balance,
    annual_balance LIKE employee.annual_balance
END RECORD
    
DEFINE ga_pay DYNAMIC ARRAY OF RECORD
    pay_date LIKE paysummary.pay_date,
    pay_amount LIKE paysummary.pay_amount
END RECORD

DEFINE ga_annual DYNAMIC ARRAY OF RECORD
    annual_date LIKE annualleave.annual_date,   
    annual_adjustment LIKE annualleave.annual_adjustment,
    annual_runningbalance LIKE annualleave.annual_runningbalance   
END RECORD
   
DEFINE ga_sick DYNAMIC ARRAY OF RECORD
    sick_date LIKE sickleave.sick_date,   
    sick_adjustment LIKE sickleave.sick_adjustment,
    sick_runningbalance LIKE sickleave.sick_runningbalance  
END RECORD

END GLOBALS


