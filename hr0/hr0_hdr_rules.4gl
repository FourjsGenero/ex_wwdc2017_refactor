GLOBALS "hr0_hdr_global.4gl"
GLOBALS "hr0_dtl_global.4gl"

DEFINE
  m_initialized BOOLEAN

#
# Employee_Select: Set employee selection
#
FUNCTION Employee_Select(p_where)

  DEFINE
    p_where STRING,
    l_query STRING

    
  LET l_query = "SELECT employee_no, surname, firstname FROM employee WHERE ",
    p_where
  PREPARE q_select FROM l_query
  DECLARE c_empList CURSOR WITH HOLD FOR q_select

  IF NOT m_initialized
  THEN
    LET m_initialized = TRUE
    DECLARE c_employee CURSOR FOR
      SELECT * FROM employee WHERE employee_no = ?
  END IF
  
END FUNCTION



#
# Valid_*: Validation functions
#
FUNCTION Valid_FirstName()
    IF g_emp.firstname IS NULL THEN
        RETURN FALSE, "Firstname must be entered"
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_MiddleNames()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Surname()
    IF g_emp.surname IS NULL THEN
        RETURN FALSE, "Surname must be entered"
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_PreferredName()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Title()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Gender()
    IF g_emp.gender MATCHES "[MF]" THEN
        #OK
    ELSE
        RETURN FALSE, "Gender must either be (M)ale or (F)emale"
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Birthdate()

    IF g_emp.birthdate IS NULL THEN
        RETURN FALSE, "Birthdate must be entered"
    END IF
    IF g_emp.birthdate > TODAY THEN
        RETURN FALSE, "Birthdate must be before today"
    END IF
    IF g_emp.birthdate < "01/01/1900" THEN
        RETURN FALSE, "Birthdate must be on or after 1/1/1900"
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Address1()
    IF g_emp.address1 IS NULL THEN
        RETURN FALSE, "Address must be entered"
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Address2()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Address3()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Address4()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_PostCode()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Country()

  -- get country record
  SELECT *
  FROM country
  WHERE country_id = g_emp.country_id
  IF status = NOTFOUND
  THEN
    RETURN FALSE, "Invalid country ID"
  END IF
  
  RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Phone()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Mobile()
    RETURN TRUE, ""
END FUNCTION

FUNCTION Valid_Employee()
    
    IF NOT valid_postcode_country_combination() THEN
        RETURN FALSE, "Postcode must be valid for country", "postcode"
    END IF
    RETURN TRUE, "", ""
END FUNCTION

FUNCTION Valid_PostCode_Country_Combination()

  DEFINE
    l_postcode STRING,
    l_length INTEGER

  LET l_postcode = NVL(g_emp.postcode,"")
  LET l_postcode = l_postcode.trim()

  -- get country record
  SELECT postcode_length
  INTO l_length
  FROM country
  WHERE country_id = g_emp.country_id
  IF status = NOTFOUND
  THEN
    LET l_length = 6
  END IF

  -- Verify postcode is correct length for country
  IF l_postcode.getLength() != l_length
  THEN
    RETURN FALSE
  END IF

  RETURN TRUE

END FUNCTION




#
# Employee_New: Setup defaults for a New employee
#
FUNCTION Employee_New()

  DEFINE
    max_no LIKE employee.employee_no

  INITIALIZE g_emp.* TO NULL

  SELECT MAX(employee_no)
  INTO max_no
  FROM employee
  
  LET g_emp.employee_no = NVL(max_no, 1) + 1
  LET g_emp.country_id = "Australia"
  LET g_emp.birthdate = TODAY
  LET g_emp.title_id = "Mr"
  LET g_emp.gender = "M"
  LET g_emp.phone = "+61"
  LET g_emp.mobile = "+61"

  LET g_empdet.employee_no = g_emp.employee_no
  LET g_empdet.annual_balance = 0
  LET g_empdet.base = 0
  LET g_empdet.basetype = ""
  LET g_empdet.sick_balance = 0
  LET g_empdet.startdate = TODAY
    
END FUNCTION


#
# Employee_Get: Get records for an employee number
#
FUNCTION Employee_Get(p_recNo)

  DEFINE
    p_recNo INTEGER,
    r_emp RECORD LIKE employee.*

  
  FOREACH c_employee USING ga_empList[p_recNo].employee_no INTO r_emp.*
    EXIT FOREACH
  END FOREACH

  LET g_emp.employee_no = r_emp.employee_no
  LET g_emp.firstname = r_emp.firstname
  LET g_emp.middlenames = r_emp.middlenames
  LET g_emp.surname = r_emp.surname
  LET g_emp.preferredname = r_emp.preferredname
  LET g_emp.title_id = r_emp.title_id
  LET g_emp.gender = r_emp.gender
  LET g_emp.birthdate = r_emp.birthdate
  LET g_emp.address1 = r_emp.address1
  LET g_emp.address2 = r_emp.address2
  LET g_emp.address3 = r_emp.address3
  LET g_emp.address4 = r_emp.address4
  LET g_emp.postcode = r_emp.postcode
  LET g_emp.country_id = r_emp.country_id
  LET g_emp.mobile = r_emp.mobile
  LET g_emp.phone = r_emp.phone

  LET g_empdet.employee_no = r_emp.employee_no
  LET g_empdet.name = r_emp.firstname, " ", r_emp.surname
  LET g_empdet.position = r_emp.position
  LET g_empdet.annual_balance = r_emp.annual_balance
  LET g_empdet.base = r_emp.base
  LET g_empdet.basetype = r_emp.basetype
  LET g_empdet.sick_balance = r_emp.sick_balance
  LET g_empdet.startdate = r_emp.startdate
  LET g_empdet.taxnumber = r_emp.taxnumber

END FUNCTION


#
# Employee_Add
#
FUNCTION Employee_Add()

  INSERT INTO employee
    (
    employee_no,
    firstname,
    middlenames,
    surname,
    preferredname,
    title,
    birthdate,
    gender,
    address1,
    address2,
    address3,
    address4,
    country,
    postcode,
    phone,
    mobile,
    email,
    startdate,
    position,
    taxnumber,
    base,
    basetype,
    sick_balance,
    annual_balance
    )
  VALUES
    (
    emp.employee_no,
    emp.firstname,
    emp.middlenames,
    emp.surname,
    emp.preferredname,
    emp.title,
    emp.birthdate,
    emp.gender,
    emp.address1,
    emp.address2,
    emp.address3,
    emp.address4,
    emp.country,
    emp.postcode,
    emp.phone,
    emp.mobile,
    "",
    TODAY,
    "New",
    "New",
    0,
    "New",
    0,
    0
    )
  LET g_empCount = g_empCount + 1
  LET ga_empList[g_empCount].employee_no = g_emp.employee_no
  LET g_empIdx = g_empCount

  CALL EmpDet_Upsert("INSERT")
  
END FUNCTION



#
# Employee_Update
#
FUNCTION Employee_Update()

  UPDATE employee
  SET
    employee_no = g_emp.employee_no,
    firstname = g_emp.firstname,
    middlenames = g_emp.middlenames,
    surname = g_emp.surname,
    preferredname = g_emp.preferredname,
    title_id = g_emp.title_id,
    birthdate = g_emp.birthdate,
    gender = g_emp.gender,
    address1 = g_emp.address1,
    address2 = g_emp.address2,
    address3 = g_emp.address3,
    address4 = g_emp.address4,
    country_id = g_emp.country_id,
    postcode = g_emp.postcode,
    phone = g_emp.phone,
    mobile = g_emp.mobile,
    email = "", #%TBD
    startdate = g_empdet.startdate,
    position = g_empdet.position,
    taxnumber = g_empdet.taxnumber,
    base = g_empdet.base,
    basetype = g_empdet.basetype,
    sick_balance = g_empdet.sick_balance,
    annual_balance = g_empdet.annual_balance
  WHERE employee_no = g_emp.employee_no

  CALL EmpDet_Upsert("UPDATE")
  
END FUNCTION



#
# Employee_Delete
#
FUNCTION Employee_Delete()

  DEFINE i INTEGER

  DELETE FROM employee
  WHERE employee_no = g_emp.employee_no
  IF status != 0
  THEN
    CALL EmpDet_Upsert("DELETE")
    RETURN
  END IF
  
  FOR i = g_empIdx TO (g_empCount-1)
    LET ga_empList[i].* = ga_empList[i+1].*
  END FOR
  
  INITIALIZE ga_empList[g_empCount].* TO NULL
  LET g_empCount = g_empCount -1
  LET g_empIdx = g_empIdx -1
  IF g_empIdx < 1 THEN
    LET g_empIdx = 1
  END IF
  
END FUNCTION



#
# EmpList_Load
#
FUNCTION EmpList_Load(p_where)

  DEFINE
    p_where STRING,

    r_emp RECORD LIKE employee.*

    
  CALL Employee_Select(p_where)

  LET g_empCount = 0
  FOREACH c_empList INTO r_emp.employee_no, r_emp.surname, r_emp.firstname
      LET ga_empList[g_empCount:=g_empCount+1].employee_no = r_emp.employee_no
      LET ga_empList[g_empCount].surname = r_emp.surname
      LET ga_empList[g_empCount].firstname = r_emp.firstname
  END FOREACH
  LET g_empIdx = 1
  
END FUNCTION




   
   
    
