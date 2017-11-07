


#
# str: String functions
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
# sp: generate spaces
#

function sp(p_idx)

  define
    p_idx int

  return p_idx spaces

end function


#
# ts: generate tab spaces (based on sw=4)
#
function ts(p_idx)

  define
    p_idx int

  return p_idx * 4 spaces

end function


############################################################################
#
# _: for Localisation of Strings
#
############################################################################

public function _(p_string)
  define
    p_string string

  return p_string
end function
