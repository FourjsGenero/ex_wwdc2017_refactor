#
# Employee_Unit.4gl   Main & Unit Test Module for Employee
#

import FGL Common
import FGL Emp_View


#
# Main: Unit Test
#

main

  -- Open database, default monitoring
  if db_Open(NVL(fgl_getenv("DB"),"hr")) != 0
  then
    error "Unable to open database"
    exit program(1)
  end if
  
  call Run(ARG_VAL(1))
  
end main



#
#! Test_Run
#
public function Run(p_request)

  define
    p_request string


  case p_request.toUpperCase()

    when "MENU"
      menu "Menu"
        command "Employee"
          call Emp_View.Show()
        command "Test1"
        on action cancel
          exit menu
      end menu

    when "TEST1"
    
    otherwise
      --% close window screen
      call Emp_View.Show()

  end case

end function


#
#! Setup
#
private function Setup()

end function


#
#! Teardown
#
private function Teardown()

end function




##########################################################################
#
# UNIT TESTS
#
##########################################################################

private function Test1()

end function