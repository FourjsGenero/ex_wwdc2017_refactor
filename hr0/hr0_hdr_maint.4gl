GLOBALS "hr0_hdr_global.4gl"
GLOBALS "hr0_dtl_global.4gl"

DEFINE
  m_initialized BOOLEAN

MAIN
  DEFINE
    l_confirm CHAR(1),
    l_form STRING,
    l_next INTEGER


  DEFER INTERRUPT
  DEFER QUIT
  OPTIONS INPUT WRAP
  OPTIONS FIELD ORDER FORM

  DATABASE hr
  CALL Employee_Select("1=0")
  
  ### Get form version ###
  LET g_version = "GUI"
  IF NUM_ARGS()
  THEN
    LET g_version = ARG_VAL(1)
  END IF
  IF fgl_getenv("FGLGUI") = "0"
  THEN
    LET g_version = "TUI"
  END IF
  LET l_form = "hr0_hdr_", g_version

  OPEN FORM f_maintenance FROM l_form
  DISPLAY FORM f_maintenance

  call ui_ComboList("employee.title_id", "select title_id, description from title order by 1")
  call ui_ComboList("employee.country_id", "select country_id, name from country order by 2")

  LET g_empCount = 0
  
  MENU ""
    BEFORE MENU
      IF g_empCount > 0 THEN
        SHOW OPTION "Update","Trash","First","Previous","Next","Last","ViewDetails"
      ELSE
        HIDE OPTION "Update","Trash","First","Previous","Next","Last","ViewDetails"
      END IF
          
    COMMAND "Query"
      CALL Employee_Query()
      IF g_empCount > 0 THEN
        CALL Employee_Get(1)
        CALL Employee_View()
        SHOW OPTION "Update","Trash","First","Previous","Next","Last","ViewDetails"
      ELSE
        HIDE OPTION "Update","Trash","First","Previous","Next","Last","ViewDetails"
      END IF
          
    COMMAND "Add"
      CALL Employee_New()
      CALL Employee_Edit(TRUE)
      IF g_empCount > 0 THEN
        SHOW OPTION "Update","Trash","First","Previous","Next","Last","ViewDetails"
      ELSE
        HIDE OPTION "Update","Trash","First","Previous","Next","Last","ViewDetails"
      END IF
          
    COMMAND "Update"
      CALL Employee_Edit(FALSE)

    COMMAND "Trash"
    
      # Promnpt to delete
      MENU "Delete Employee?"
        COMMAND "No"
          LET l_confirm = "N"
          EXIT MENU
        COMMAND "Yes"
          LET l_confirm = "Y"
          EXIT MENU
      END MENU
      IF l_confirm = "Y" THEN
        CALL Employee_Delete()
        
        IF g_empCount > 0 THEN
          CALL Employee_Get(g_empIdx)
          SHOW OPTION "Update","Trash","First","Previous","Next","Last","ViewDetails"
        ELSE
          INITIALIZE g_emp.* TO NULL
          LET g_empIdx = 0
          HIDE OPTION "Update","Trash","First","Previous","Next","Last","ViewDetails"
        END IF

        CALL Employee_View()
      END IF

    COMMAND "Browse" "Browse through list of selected records"
      LET l_next = Employee_List(g_version, g_empIdx)
      IF l_next > 0
      THEN
        LET g_empIdx = l_next
        CALL Employee_Get(g_empIdx)
        CALL Employee_View()
      END IF
      
    COMMAND "First"
      LET g_empIdx = 1
      CALL Employee_Get(g_empIdx)
      CALL Employee_View()

    COMMAND "Previous"
      IF g_empIdx > 1 THEN
          LET g_empIdx = g_empIdx - 1
      END IF
      CALL Employee_Get(g_empIdx)
      CALL Employee_View()

    COMMAND "Next"
      IF g_empIdx < g_empCount THEN
          LET g_empIdx = g_empIdx + 1
      END IF
      CALL Employee_Get(g_empIdx)
      CALL Employee_View()

    COMMAND "Last"
      LET g_empIdx = g_empCount
      CALL Employee_Get(g_empIdx)
      CALL Employee_View()

    COMMAND "ViewDetails"
      CALL Employee_Detail("VIEW")
        
    COMMAND "Exit"
      EXIT MENU
  END MENU

END MAIN





#
# Employee_Query:  Query By Example
#
FUNCTION Employee_Query()

  DEFINE
    l_sql STRING

  CONSTRUCT l_sql ON
    employee_no,
    firstname,
    middlenames,
    surname,
    preferredname, 
    title_id,
    gender, 
    birthdate,
    address1,
    address2,
    address3,
    address4,
    postcode,
    country_id,
    phone,
    mobile,
    email
  FROM 
    employee_no,
    firstname,
    middlenames,
    surname,
    preferredname,
    title_id,
    gender,
    birthdate,
    address1,
    address2,
    address3,
    address4,
    postcode,
    country_id,
    phone,
    mobile,
    email

    AFTER CONSTRUCT
      IF int_flag THEN
          EXIT CONSTRUCT
      END IF
  END CONSTRUCT
  
  IF int_flag THEN
    LET int_flag = 0
    LET l_sql = "1=0"
  END IF
  CALL EmpList_Load(l_sql)
    
END FUNCTION



    

#
# Employee_Edit: Edit employee record
#
FUNCTION Employee_Edit(p_add)
  DEFINE p_add BOOLEAN
  
  DEFINE
    ok SMALLINT,
    error_text CHAR(80),
    field_name STRING

  INPUT BY NAME g_emp.* ATTRIBUTES(WITHOUT DEFAULTS=TRUE)

    AFTER FIELD firstname
      CALL Valid_FirstName() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD firstname
      END IF

    AFTER FIELD middlenames
      CALL Valid_MiddleNames() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD middlenames
      END IF

    AFTER FIELD surname
      CALL Valid_Surname() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD surname
      END IF

    AFTER FIELD preferredname
      CALL Valid_PreferredName() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD preferredname
      END IF

    AFTER FIELD title_id
      CALL Valid_Title() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD title
      END IF

    AFTER FIELD birthdate
      CALL Valid_BirthDate() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD birthdate
      END IF

    AFTER FIELD gender
      CALL Valid_Gender() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD gender
      END IF

    AFTER FIELD address1
      CALL Valid_Address1() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD address1
      END IF

    AFTER FIELD address2
      CALL Valid_Address2() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD address2
      END IF

    AFTER FIELD address3
      CALL Valid_Address3() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD address3
      END IF

    AFTER FIELD address4
      CALL Valid_Address4() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD address4
      END IF

    AFTER FIELD postcode
      CALL Valid_Postcode() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD postcode
      END IF

    AFTER FIELD country_id
      CALL Valid_Country() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD country
      END IF

    AFTER FIELD phone
      CALL Valid_Phone() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD phone
      END IF

    AFTER FIELD mobile
      CALL Valid_Mobile() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD mobile
      END IF

    AFTER FIELD email
      CALL Valid_Email() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD email
      END IF
      
    AFTER INPUT
      IF int_flag THEN
        EXIT INPUT
      END IF
  
      CALL Valid_FirstName() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD firstname
      END IF

    
      CALL Valid_MiddleNames() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD middlenames
      END IF

   
      CALL Valid_Surname() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD surname
      END IF

   
      CALL Valid_PreferredName() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD preferredname
      END IF

   
      CALL Valid_Title() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD title
      END IF


      CALL Valid_BirthDate() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD birthdate
      END IF

   
      CALL Valid_Gender() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD gender
      END IF

   
      CALL Valid_Address1() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD address1
      END IF

   
      CALL Valid_Address2() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD address2
      END IF


      CALL Valid_Address3() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD address3
      END IF

   
      CALL Valid_Address4() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD address4
      END IF

   
      CALL Valid_PostCode() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD postcode
      END IF

   
      CALL Valid_Country() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD country
      END IF

   
      CALL Valid_Phone() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD phone
      END IF

      
      CALL Valid_Mobile() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD mobile
      END IF

      
      CALL Valid_Email() RETURNING ok, error_text
      IF NOT ok THEN
        ERROR error_text
        NEXT FIELD email
      END IF

      
      CALL Valid_Employee() RETURNING ok, error_text, field_name
      IF NOT ok THEN
        ERROR error_text
        CALL DIALOG.nextField(field_name)
        CONTINUE INPUT
      END IF

      ### Edit details ###
      CALL Employee_Detail("EDIT")
      
      ### Upsert ###
      IF p_add THEN
        CALL Employee_Add()
      ELSE
        CALL Employee_Update()
      END IF

  END INPUT
  
  LET int_flag = FALSE
  
END FUNCTION



#
# Employee_View: Display employee record
#
FUNCTION Employee_View()

    DISPLAY g_emp.* TO emp_scr.*
    
END FUNCTION



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

function Valid_Email()
  define
    l_email string,
    l_user string,
    l_domain string


  -- Split address into user and domain
  let l_email = g_emp.email
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
  LET g_empdet.basetype = "SAL"
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
  LET g_emp.email = r_emp.email

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
    title_id,
    birthdate,
    gender,
    address1,
    address2,
    address3,
    address4,
    country_id,
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
    g_emp.employee_no,
    g_emp.firstname,
    g_emp.middlenames,
    g_emp.surname,
    g_emp.preferredname,
    g_emp.title_id,
    g_emp.birthdate,
    g_emp.gender,
    g_emp.address1,
    g_emp.address2,
    g_emp.address3,
    g_emp.address4,
    g_emp.country_id,
    g_emp.postcode,
    g_emp.phone,
    g_emp.mobile,
    g_emp.email,
    TODAY,
    "New",
    "0",
    0,
    "SAL",
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
    email = g_emp.email,
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



