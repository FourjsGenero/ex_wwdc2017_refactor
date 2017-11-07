schema hr

globals

define g_empdet record
    employee_no like employee.employee_no,
    name string,
    startdate like employee.startdate,
    position like employee.position,
    taxnumber like employee.taxnumber,
    base like employee.base,
    basetype like employee.basetype,
    sick_balance like employee.sick_balance,
    annual_balance like employee.annual_balance
end record
    
define ga_pay dynamic array of record
    pay_date like paysummary.pay_date,
    pay_amount like paysummary.pay_amount
end record

define ga_annual dynamic array of record
    annual_date like annualleave.annual_date,   
    annual_adjustment like annualleave.annual_adjustment,
    annual_runningbalance like annualleave.annual_runningbalance   
end record
   
define ga_sick dynamic array of record
    sick_date like sickleave.sick_date,   
    sick_adjustment like sickleave.sick_adjustment,
    sick_runningbalance like sickleave.sick_runningbalance  
end record

end globals


