SCHEMA hr

GLOBALS
DEFINE
  g_emp RECORD
    employee_no INTEGER,
    firstname CHAR(30),
    middlenames CHAR(30),
    surname CHAR(30),
    preferredname CHAR(30),
    title CHAR(10),
    gender CHAR(1),
    birthdate DATE,
    address VARCHAR(160),
    address1 CHAR(40),
    address2 CHAR(40),
    address3 CHAR(40),
    address4 CHAR(40),
    postcode CHAR(10),
    country CHAR(20),
    phone CHAR(20),
    mobile CHAR(20)
  END RECORD,

  ga_empList ARRAY[100] OF
    RECORD
      employee_no INTEGER
    END RECORD,

  g_empIdx INTEGER,
  g_empCount INTEGER,
  g_version STRING


END GLOBALS
