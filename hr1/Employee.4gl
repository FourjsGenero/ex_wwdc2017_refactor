#
# Employee    Business rules and model logic for Employee
#

import FGL Common
import FGL Selection

schema hr


#
# Module Types
#
public type

  t_Employee record like employee.*,
  t_PaySummary record like paysummary.*,
  t_AnnualLeave record like annualleave.*,
  t_SickLeave record like sickleave.*,

  t_Line
    record
      employee_no like employee.employee_no,
      employee_surname like employee.surname,
      employee_firstname like employee.firstname,
      employee_position like employee.position
    end record,
    
  t_List
    dynamic array of t_Line,

  t_View
    record
      employee t_Employee,
      pay dynamic array of t_PaySummary,
      annual dynamic array of t_AnnualLeave,
      sick dynamic array of t_SickLeave
    end record


#
# Module
#

public define    
  rView t_View,
  aList t_List,
    error string

private define
  ma_valid dictionary of function(),
  m_initialized boolean




#
# MAIN - Standalone or Unit Test
#
main

end main





#
# PUBLIC
#


#############################################################################
#
#! Init
#+ Initialize the module
#+
#+ @code
#+ call Employee.Init()
#
#############################################################################
public function Init()

  if m_initialized
  then
    return
  end if
  let m_initialized = TRUE

  -- Declare static cursors
  declare c_employee cursor for
    select * from employee where employee_no = ?
    order by employee_no

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

  declare c_country cursor for
    select *
    from country
    where country_id = ?
    order by country_id
    
  -- Set Selection defaults
  call selection_Defaults()

  -- Dictionary of Validation functions
  let ma_valid["firstname"] = function Valid_Firstname
  let ma_valid["surname"] = function Valid_Surname
  let ma_valid["title_id"] = function Valid_Title_ID
  let ma_valid["birthdate"] = function Valid_Birthdate
  let ma_valid["gender"] = function Valid_Gender
  let ma_valid["address1"] = function Valid_Address1
  let ma_valid["postcode"] = function Valid_Postcode
  let ma_valid["country_id"] = function Valid_Country_ID
  let ma_valid["phone"] = function Valid_Phone
  let ma_valid["mobile"] = function Valid_Mobile
  let ma_valid["email"] = function Valid_Email
  
end function



#############################################################################
#
#! Select()
#+ Set query to select sorted list of records and open cursor
#+
#+ @code
#+ call Employee.Select()
#
#############################################################################
public function Select()

{%%
  define l_debug string
  let l_debug = Selection.SQL("DATA")
}
  
  -- Cursor for list
  declare c_empLine scroll cursor with hold from Selection.SQL("DATA")
  open c_empLine

  -- Save count
  declare c_empCount cursor from Selection.SQL("COUNT")
  foreach c_empCount into Selection.rCurrent.count
  end foreach
  
end function



#############################################################################
#
#! List_Load
#+ Load the current page in list view
#+
#+ @param p_start    Starting absolute record
#+ @param p_len      Number of records
#+
#+ @code
#+ ...
#+ call Employee.List_Load(fgl_dialog_getBufferStart(), fgl_dialog_getBufferLength())
#
#############################################################################
public function List_Load(p_start int, p_len int) returns integer
  define
    l_row, idx integer

  call aList.clear()

  let l_row = p_start
  for idx = 1 to p_len
    fetch absolute l_row c_empLine into aList[idx].*
    if SQLCA.SQLcode
    then
      return l_row-1
    end if
    let l_row = l_row + 1
  end for

  -- default row if no data
  return l_row
  
end function


#############################################################################
#
#! ListItem_Key
#+ Return the key for an absolute list item in the list
#+
#+ @param p_row      Item number in list
#+
#+ @returnType      like employee.employee_no
#+ @return          Primary key - Employee number
#+
#+ @code
#+ define p_employeeNo like employee.employee_no
#+ ...
#+ let p_employeeNo = Employee.ListItem_Key(arr_curr()) 
#
#############################################################################

public function ListItem_Key(p_row integer) returns like employee.employee_no

  define
    r_line t_line
    
  fetch absolute p_row c_empLine into r_line.*
  if SQLCA.SQLcode
  then
    return NULL
  end if

  return r_line.employee_no

end function


#############################################################################
#
#! New()
#+ Setup defaults for a New employee
#+
#+ @code
#+ call Employee.New()
#
#############################################################################
public function New()

  define
    p_maxEmpNo like employee.employee_no


  -- get last employee number
  select max(employee_no)
  into p_maxEmpNo
  from employee


  -- Clear
  call view_Clear()
  
  -- Setup defaults
  let rView.employee.employee_no = nvl(p_maxEmpNo, 0) + 1
  let rView.employee.country_id = "AU"
  let rView.employee.birthdate = TODAY
  let rView.employee.title_id = "Mr"
  let rView.employee.gender = "M"
  let rView.employee.phone = "+61 "
  let rView.employee.mobile = "+61 "

  let rView.employee.employee_no = rView.employee.employee_no
  let rView.employee.annual_balance = 0
  let rView.employee.base = 0
  let rView.employee.basetype = "SAL"
  let rView.employee.sick_balance = 0
  let rView.employee.startdate = TODAY
    
end function



#############################################################################
#
#! Get()
#+ Get related data for an employee number
#+
#+ @code
#+ define p_employeeNo like employee.employee_no
#+ call Employee.Get(p_employeeNo)
#
#############################################################################
public function Get(p_employeeNo like employee.employee_no)

  define
    r_pay t_PaySummary,
    r_sick t_SickLeave,
    r_annual t_AnnualLeave,
    idx integer


  call view_Clear()
  
  -- Employee
  foreach c_employee using p_employeeNo into rView.employee.*
    exit foreach
  end foreach

  -- Pay Summary
  let idx = 0
  foreach c_paysummary using p_employeeNo into r_pay.*
    let rView.pay[idx:=idx+1].* = r_pay.*
  end foreach

  -- Sick Leave
  let idx = 0
  foreach c_sickleave using p_employeeNo into r_sick.*
    let rView.sick[idx:=idx+1].* = r_sick.*
  end foreach

  -- Annual Leave
  let idx = 0
  foreach c_annualleave using p_employeeNo into r_annual.*
    let rView.annual[idx:=idx+1].* = r_annual.*
  end foreach
  
end function



#############################################################################
#
#! Put()
#+ Put related data for current employee
#+
#+ @code
#+ define p_employeeNo like employee.employee_no
#+ ...
#+ call Employee.Get(p_employeeNo)
#
#############################################################################
public function Put() returns string

  define
    l_mode string

    
  select employee_no
  from employee
  where employee_no = rView.employee.employee_no
  let l_mode = iif(status = NOTFOUND, "ADD", "UPDATE")

  -- Update balances
  call SickLeave_Balance()
  call AnnualLeave_Balance()
  
  -- Upsert
  if l_mode = "ADD"
  then
    return (Insert())
  else
    return (Update())
  end if
  
end function




#############################################################################
#
#! Delete()
#+ Delete related data for current employee
#+
#+ @code
#+ define p_employeeNo like employee.employee_no
#+ call Employee.Get(p_employeeNo)
#
#############################################################################
public function Delete(p_employeeNo like employee.employee_no) returns string

  define
    l_status string,
    l_void integer


  -- Start
  if db_Transact("BEGIN")
  then
    return "ERROR: Unable to start database transaction"
  end if
  let l_status = "OK"

  if (l_status := detail_Upsert("DELETE", p_employeeNo)) = "OK"
  then
    try
      delete from employee
      where employee_no = p_employeeNo
    catch
      let l_status = "ERROR: " || SQLCA.SQLERRM
    end try
  end if

  if l_status matches "ERROR*"
  then
    let l_void = db_Transact("ROLLBACK")
    return l_status
  end if

  if db_Transact("COMMIT")
  then
    return "ERROR: Unable to commit transaction"
  end if
        
  return "OK"
  
end function



#############################################################################
#
#! Insert()
#+ Insert related data for current employee
#+
#+ @code
#+ call Employee.Insert()
#
#############################################################################
public function Insert() returns string

  define
    l_status string,
    l_void integer
    

  -- Start
  if db_Transact("BEGIN")
  then
    return "ERROR: Unable to start database transaction"
  end if
  let l_status = "OK"

  -- Employee
  try
    insert into employee values (rView.employee.*)
  catch
    let l_status = "ERROR: " || SQLCA.SQLERRM
  end try

  if l_status = "OK"
  then
    let l_status = detail_Upsert("INSERT", rView.employee.employee_no)
  end if

  if l_status matches "ERROR*"
  then
    let l_void = db_Transact("ROLLBACK")
    return l_status
  end if

  if db_Transact("COMMIT")
  then
    return "ERROR: Unable to commit transaction"
  end if
        
  return "OK"
  
end function



#############################################################################
#
#! Update()
#+ Update related data for current employee
#+
#+ @code 
#+ call Employee.Update()
#
#############################################################################
public function Update() returns string

  define
    l_status string,
    l_void integer
    

  -- Start
  if db_Transact("BEGIN")
  then
    return "ERROR: Unable to start database transaction"
  end if
  let l_status = "OK"

  -- Employee
  try
    update employee
    set
      employee.* = rView.employee.*
    where employee_no = rView.employee.employee_no
  catch
    let l_status = "ERROR: " || SQLCA.SQLERRM
  end try

  if l_status = "OK"
  then
    let l_status = detail_Upsert("INSERT", rView.employee.employee_no)
  end if

  if l_status matches "ERROR*"
  then
    let l_void = db_Transact("ROLLBACK")
    return l_status
  end if

  if db_Transact("COMMIT")
  then
    return "ERROR: Unable to commit transaction"
  end if
        
  return "OK"
  
end function



#############################################################################
#
#! Base_Set()
#+ Set base salary or wage
#+
#+ @code
#+ call Employee.Base_Set()
#
#############################################################################
public function Base_Set()
  define
    idx integer,
    l_date date,
    l_base like employee.base
    

  let l_date = "01/01/1900"
  let l_base = 0

  for idx = 1 to rView.pay.getLength()
    if rView.pay[idx].pay_date > l_date
    then
      let l_base = rView.pay[idx].pay_amount
      let l_date = rView.pay[idx].pay_date
    end if
  end for

  let rView.employee.base = l_base
end function



#############################################################################
#
#! AnnualLeave_Balance()
#+ Update Annual Leave Balance
#+
#+ @code
#+ call Employee.AnnualLeave_Balance()
#
#############################################################################
public function AnnualLeave_Balance()
  define
    idx integer,
    l_date date,
    l_balance like employee.annual_balance
    

  let l_date = "01/01/1900"
  let l_balance = 0

  for idx = 1 to rView.annual.getLength()
    if rView.annual[idx].annual_date > l_date
    then
      let l_balance = rView.annual[idx].annual_runningbalance
      let l_date = rView.annual[idx].annual_date
    end if
  end for

  let rView.employee.annual_balance = l_balance
end function




#############################################################################
#
#! SickLeave_Balance()
#+ Update Sick Leave Balance
#+
#+ @code
#+ call Employee.SickLeave_Balance()
#
#############################################################################
public function SickLeave_Balance()
  define
    idx integer,
    l_date date,
    l_balance like employee.sick_balance
    

  let l_date = "01/01/1900"
  let l_balance = 0

  for idx = 1 to rView.sick.getLength()
    if rView.sick[idx].sick_date > l_date
    then
      let l_balance = rView.sick[idx].sick_runningbalance
      let l_date = rView.sick[idx].sick_date
    end if
  end for

  let rView.employee.sick_balance = l_balance
end function


#
# Valid_*: Field Validation functions
#
function Valid_FirstName()
  if rView.employee.firstname is null then
      return FALSE, "Firstname must be entered"
  end if
  return TRUE, ""
end function

function Valid_Surname()
  if rView.employee.surname is null then
      return FALSE, "Surname must be entered"
  end if
  return TRUE, ""
end function

function Valid_Title_ID()
  select  title_id
  from    title
  where   title_id = rView.employee.title_id
  if status = NOTFOUND
  then
    return FALSE, "Title is invalid"
  end if
  return TRUE, ""
end function

function Valid_Gender()
  if rView.employee.gender matches "[MF]" then
      #OK
  else
      return FALSE, "Gender must either be (M)ale or (F)emale"
  end if
  return TRUE, ""
end function

function Valid_Birthdate()
  if rView.employee.birthdate is null then
      return FALSE, "Birthdate must be entered"
  end if
  if rView.employee.birthdate > today then
      return FALSE, "Birthdate must be before today"
  end if
  if rView.employee.birthdate < "01/01/1900" then
      return FALSE, "Birthdate must be on or after 1/1/1900"
  end if
  return TRUE, ""
end function

function Valid_Address1()
  if rView.employee.address1 is null then
      return FALSE, "Address must be entered"
  end if
  return TRUE, ""
end function

function Valid_PostCode()
  return TRUE, ""
end function

function Valid_Country_ID()
  select  country_id
  from    country
  where   country_id = rView.employee.country_id
  if status = NOTFOUND
  then
    return FALSE, "Country is invalid"
  end if
  return TRUE, ""
end function

function Valid_Phone()
  if Valid_PhoneNumber(rView.employee.phone)
  then
    return TRUE, ""
  else
    return FALSE, "Invalid phone number - must contain + and numbers"
  end if
end function

function Valid_Mobile()
  if Valid_PhoneNumber(rView.employee.mobile)
  then
    return TRUE, ""
  else
    return FALSE, "Invalid mobile number - must contain numbers with spaces, optional +"
  end if
end function

function Valid_PhoneNumber(p_phone string)
  if p_phone matches "+*"
  then
    let p_phone = p_phone.subString(2,p_phone.getLength())
  end if
  
  return str_HasOnly("[0-9 ]", p_phone)
end function

function Valid_Email()
  define
    l_email string,
    l_user string,
    l_domain string


  -- Split address into user and domain
  let l_email = rView.employee.email
  call str_Split(l_email.toLowerCase(), "@")
    returning l_user, l_domain

  -- User and domain must be non-null
  if l_user.getLength() = 0 or l_domain.getLength() = 0
  then
    return FALSE, "Email address invalid: user or domain is null"
  end if

  -- Must contain alphanumeric, dash, underscore and dots only
  -- but not overly concerned as we need to validate it anyway
  if str_HasOnly("[a-z0-9._-]", l_user) and str_HasOnly("[a-z0-9._-]", l_domain)
  then
    return FALSE, "Email address contains invalid characters"
  end if

  return TRUE, ""
end function


#
# Valid_Field: Validate a field
#
function Valid_Field(p_field string)
  define
    l_validFunc function(),
    l_error string,
    ok boolean

  if ma_valid.contains(p_field)
  then
    let l_validFunc = ma_valid[p_field]
  else
    return TRUE, ""
  end if

  call l_validFunc()
    returning ok, l_error

  return ok, l_error
  
end function

#
# Valid_Record - Validate all fields plus some
#
function Valid_Record()
  define
    a_fields dynamic array of string,
    l_validFunc function(),
    l_error string,
    ok boolean,
    idx integer

  -- get field list
  let a_fields = ma_valid.getKeys()
  
  -- Validate each field
  for idx = 1 to a_fields.getLength()
    let l_validFunc = ma_valid[a_fields[idx]]
    call l_validFunc() returning ok, l_error
    if not ok
    then
      return FALSE, l_error, a_fields[idx]
    end if
  end for

  -- Other rules
  if not Valid_Postcode_Country_Combination() 
  then
      return FALSE, "Postcode must be valid for country", "postcode"
  end if
  
  return TRUE, "", ""
  
end function

function Valid_PostCode_Country_Combination()
  define
    r_country record like country.*,
    l_postcode string

  let l_postcode = nvl(rView.employee.postcode,"")
  let l_postcode = l_postcode.trim()

  -- get country record
  call country_Get(rView.employee.country_id)
    returning r_country.*

  -- Verify postcode is correct length for country
  if l_postcode.getLength() != r_country.postcode_length
  then
    return FALSE
  end if

  return TRUE
end function





#--------------------PRIVATE---------------------------------#

#############################################################################
#
#! detail_Upsert()
#+ Upsert related data for current employee
#+
#+ @code
#+ define p_employeeNo like employee.employee_no
#+ ...
#+ call Employee.Get(p_employeeNo)
#
#############################################################################
private function detail_Upsert(p_mode string, p_employeeNo like employee.employee_no)

  define
    idx integer

    
  let p_mode = p_mode.toUpperCase()

  try
    delete from paysummary where employee_no = p_employeeNo
    if p_mode != "DELETE"
    then
      let idx = 0
      for idx = 1 to rView.pay.getLength()
        let rView.pay[idx].employee_no = rView.employee.employee_no
        insert into paysummary values(rView.pay[idx].*)
      end for
    end if 

    delete from sickleave where employee_no = p_employeeNo
    if p_mode != "DELETE"
    then
      let idx = 0
      for idx = 1 to rView.sick.getLength()
        let rView.sick[idx].employee_no = rView.employee.employee_no
        insert into sickleave values(rView.sick[idx].*)
      end for
    end if 

    delete from annualleave where employee_no = p_employeeNo
    if p_mode != "DELETE"
    then
      let idx = 0
      for idx = 1 to rView.annual.getLength()
        let rView.annual[idx].employee_no = rView.employee.employee_no
        insert into annualleave values(rView.annual[idx].*)
      end for
    end if
  catch
    return "ERROR: " || SQLCA.SQLERRM
  end try

  return "OK"

end function





#############################################################################
#
#! view_Clear()
#+ view_Clear employee data set view
#+
#+ @code
#+ call view_Clear()
#
#############################################################################
private function view_Clear()

  initialize rView.employee to NULL
  call rView.pay.clear()
  call rView.annual.clear()
  call rView.sick.clear()
  
end function



#############################################################################
#
#! selection_Defaults
#+ Initialize the Selection Control parameters
#+
#+ @code
#+ call selection_Defaults()
#
#############################################################################
private function selection_Defaults()

  define
    r_sel Selection.t_selection,
    i integer

  # Save in case this was set first
  let r_sel.View_Refresh = Selection.rCurrent.View_Refresh
  
  -- Base query
  let r_sel.select = "employee_no, surname, firstname, position"
  let r_sel.from = " employee"
  let r_sel.default.orderBy = "1"
  
  --%this should be a dictionary, so we know the types
  --%should .select be built form these columns?
  let i = 0
  let r_sel.options.use[i:=i+1].column = "employee_no"
  let r_sel.options.use[i].name = "Employee No"
  let r_sel.options.use[i].selected = TRUE
  
  let r_sel.options.use[i:=i+1].column = "surname"
  let r_sel.options.use[i].name = "Surname"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "firstname"
  let r_sel.options.use[i].name = "First Name"
  let r_sel.options.use[i].selected = TRUE
  
  let r_sel.options.use[i:=i+1].column = "middlenames"
  let r_sel.options.use[i].name = "Middle Names"
  let r_sel.options.use[i].selected = TRUE
    
  let r_sel.options.use[i:=i+1].column = "preferredname"
  let r_sel.options.use[i].name = "Preferred Name"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "title_id"
  let r_sel.options.use[i].name = "Title ID"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "birthdate"
  let r_sel.options.use[i].name = "Birth Date"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "address1"
  let r_sel.options.use[i].name = "Address 1"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "address2"
  let r_sel.options.use[i].name = "Address 2"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "address3"
  let r_sel.options.use[i].name = "Address 3"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "address4"
  let r_sel.options.use[i].name = "Address 4"
  let r_sel.options.use[i].selected = TRUE  

  let r_sel.options.use[i:=i+1].column = "country_id"
  let r_sel.options.use[i].name = "Country ID"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "postcode"
  let r_sel.options.use[i].name = "Post Code"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "phone"
  let r_sel.options.use[i].name = "Phone"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "mobile"
  let r_sel.options.use[i].name = "Mobile"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "email"
  let r_sel.options.use[i].name = "Email"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "position"
  let r_sel.options.use[i].name = "Position"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "taxnumber"
  let r_sel.options.use[i].name = "Tax Number"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "base"
  let r_sel.options.use[i].name = "Base"
  let r_sel.options.use[i].selected = TRUE

  let r_sel.options.use[i:=i+1].column = "basetype"
  let r_sel.options.use[i].name = "Base Type"
  let r_sel.options.use[i].selected = TRUE
  
  
  let r_sel.options.matchCase = FALSE
  let r_sel.options.matchWord = FALSE

  let r_sel.where = Selection.Filter("")
  --% Set by caller:  let r_sel.List_Refresh = function list_Refresh
  let r_sel.Data_Refresh = function Select

  let Selection.rCurrent.* = r_sel.*
  
end function



#############################################################################
#
#! country_Get
#+ Get record for a country by country_id
#+
#+ @code
#+ call country_Get("AU")
#
#############################################################################
private function country_Get(p_countryid like country.country_id) returns record like country.*
  define
    r_country record like country.*

  foreach c_country using p_countryid into r_country.*
  end foreach

  return r_country.*
  
end function    
