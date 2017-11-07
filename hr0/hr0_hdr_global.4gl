SCHEMA hr

GLOBALS
DEFINE
  g_emp RECORD
    employee_no like employee.employee_no,
    firstname like employee.firstname,
    middlenames like employee.middlenames,
    surname like employee.surname,
    preferredname like employee.preferredname,
    title_id like employee.title_id,
    gender like employee.gender,
    birthdate like employee.birthdate,
    address VARCHAR(160),
    address1 like employee.address1,
    address2 like employee.address2,
    address3 like employee.address3,
    address4 like employee.address4,
    postcode like employee.postcode,
    country_id like employee.country_id,
    phone like employee.phone,
    mobile like employee.mobile,
    email like employee.email
  END RECORD,

  ga_empList DYNAMIC ARRAY OF
    RECORD
      employee_no like employee.employee_no,
      surname like employee.surname,
      firstname like employee.firstname
    END RECORD,

  g_empIdx INTEGER,
  g_empCount INTEGER,
  g_version STRING

END GLOBALS
