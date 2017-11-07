#
# Com.4gl   Common library
#


import security

#
# db: database functions
#


#
#! db_Transact
#+ Database transactions: BEGIN, COMMIT or ROLLBACK work
#+ This is a wrapper to the FGL database functions in fgldbutl.4gl
#+
#+ @param p_transact    Transaction "BEGIN", "COMMIT", "ROLLBACK"
#+
#+ @returnType        Integer
#+ @return            status
#+
#+ @code
#+ if db_Transact("BEGIN") then
#+   ...
#+   let l_status = db_Transact("COMMIT")
#+   try
#+     -- ... some db transaction
#+     let l_status = db_Transact("COMMIT")
#+   catch
#+     let l_status = db_Transact("ROLLBACK")
#+   end try
#
public function db_Transact(p_transact)

  define
    p_transact string,
    l_status integer

  let p_transact = p_transact.toUpperCase()
  
  case p_transact.getCharAt(1)
  when "B"  #Begin
    let l_status = db_start_transaction()
  when "C"  #Commit
    let l_status = db_finish_transaction(TRUE)
  when "R"  #Rollback
    let l_status = db_finish_transaction(FALSE)
  otherwise
    return 100  #notfound
  end case

  return l_status
  
end function


#
#! db_Open
#+ Open a database
#+
#+ @param p_database    Database name
#+
#+ @returnType          Integer
#+ @return              status
#+
#+ @code
#+ if db_Open("monitoring") != 0 then
#+   error "unable to open database"
#

public function db_Open(p_database)

  define
    p_database string


  -- if no database specified look at env DB
  if p_database.getLength() = 0
  then
    let p_database = fgl_getenv("DB")
  end if

  -- still no database, then not found
  if p_database.getLength() = 0
  then
    return NOTFOUND
  end if

  -- close previous db and open this one
  try
    close database
  catch
  end try
  database p_database

  return status
  
end function



#
#! db_Connect
#+ Open a conection to a database
#+
#+ @param p_connect     Database name or connection string
#+ @param p_user        User ID
#+ @param p_password    Password
#+
#+ @returnType          Integer
#+ @return              status
#+
#+ @code
#+ if db_Connect("monitoring","ssykes","secret") != 0 then
#+   error "unable to connect to database"
#

public function db_Connect(p_connect, p_user, p_password)

  define
    p_connect, p_user, p_password string

  connect to p_connect user p_user using p_password

  return status
  
end function






#
# str: String functions
#


#
#! str_Hash
#+ Generate a hash from a string using a hash algorithm
#+
#+ @param p_algorithm   SHA1, SHA512, SHA384, SHA256, SHA224, MD5
#+ @param p_string      String to generate a hash for
#+
#+ @returnType          String
#+ @return              Hash of p_string
#+
#+ @code
#+ define p_hash string
#+ let p_hash = str_Hash("SHA1", "user@domain.com")
#


public function str_Hash(p_algorithm, p_string)

  define
    p_string, p_algorithm, l_hash string,
    o_digest security.Digest

  try
    let o_digest = security.Digest.CreateDigest(p_algorithm)
    call o_digest.AddStringData(p_string)
    let l_hash = o_digest.DoBase64Digest()
  catch
    let l_hash = NULL
  end try

  return l_hash
  
end function



#
#! str_Split
#+ Split string into two parts separated by a token character
#+
#+ @param p_str     String to split
#+ @param p_sep     Seprator strong or token
#+
#+ @returnType      String, String
#+ @return          String part on left side of separator
#+ @return          Srting part on right side of separator
#

public function str_Split(p_str, p_sep)

  define
    p_str   string,
    p_sep   char,

    p_len   int,
    p_idx   int,
    p_s1    string,
    p_s2    string


  let p_len = p_str.getLength()
  let p_idx = p_str.getIndexOf(p_sep, 1)

  if p_idx > 0
  then
    let p_s1 = p_str.subString(1, p_idx-1)
    let p_s2 = p_str.subString(p_idx+1, p_len)
  else
    let p_s1 = p_str
    let p_s2 = ""
  end if

  return p_s1, p_s2

end function


#
#! str_HasOnly
#+ String only has characters that matches pattern
#+
#+ @param p_pattern   Pattern to match
#+ @param p_string    String to analyse
#+
#+ @returnType        Boolean
#+ @return            TRUE if string HasOnly pattern
#+
#+ @code
#+ define p_phoneNumber string
#+ ...
#+ if str_HasOnly("[0-9]", p_phoneNumber) then ...
#

public function str_HasOnly(p_pattern, p_string)
  define
    p_string, p_pattern string,
    l_buffer base.StringBuffer,
    idx int

  -- empty cant match
  if p_string.getLength() < 1
  then
    return FALSE
  end if
  
  let l_buffer = base.StringBuffer.create()
  call l_buffer.append(p_string)

  -- check if any chars don't match
  for idx = 1 to l_buffer.getLength()
    if l_buffer.getCharAt(idx) not matches p_pattern
    then
      return FALSE
    end if
  end for

  return TRUE
  
end function




#
# Short hand/Convenience functions
# Used in sentential string construction
#



#
#! sp
#+ Generate a string containing a set number of spaces
#+
#+ @param p_spaces    Number of space characters to generate
#+
#+ @returnType        String
#+ @return            String containing p_spaces number of spaces
#+
#+ @code
#+ define p_label string
#+ let p_label = "AAA", sp(20), "BBB"
#

public function sp(p_spaces)

  define
    p_spaces int

  return p_spaces spaces

end function


#
#! ts4
#+ Generate a string containing a set number of 4 char wide tabs
#+
#+ @param p_tabs  Number of tabs to generate
#+
#+ @returnType    String
#+ @return        String containing p_tabs number of tabs
#+
#+ @code
#+ define p_label string
#+ let p_label = "AAA", ts4(3), "BBB"
#

function ts4(p_tabs)

  define
    p_tabs int

  return tab_stop(p_tabs, 4)

  end function


#
#! ts8
#+ Generate a string containing a set number of 8 char wide tabs
#+
#+ @param p_tabs  Number of tabs to generate
#+
#+ @returnType    String
#+ @return        String containing p_tabs number of tabs
#+
#+ @code
#+ define p_label string
#+ let p_label = "AAA", ts8(3), "BBB"
#

function ts8(p_tabs)

  define
    p_tabs int

  return tab_stop(p_tabs, 8)

end function


#
# tab_stop: generate tab spaces (based on sw=4)
#

#
#! tab_stop
#+ Generate a string containing a set number of 8 char wide tabs
#+
#+ @param p_tabs  Number of tabs to generate
#+ @param p_size  Width of each tab
#+
#+ @returnType    String
#+ @return        String containing p_tabs number of tabs
#+
#

private function tab_stop(p_tabs, p_size)

  define
    p_tabs, p_size int

  return p_tabs * p_size spaces

end function


############################################################################
#
# _: stub for Localisation of Strings
#
############################################################################

public function _(p_string)
  define
    p_string string

  return p_string
end function
