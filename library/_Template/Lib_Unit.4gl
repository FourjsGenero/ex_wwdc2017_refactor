#
# Lib_Unit.4gl   Main & Unit Test Module for App
#

import FGL Lib


#
# Main: Unit Test
#

main
  
  call Run("MENU")
  
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
        command "Test1"
        on action cancel
          exit menu
      end menu

    when "TEST1"

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