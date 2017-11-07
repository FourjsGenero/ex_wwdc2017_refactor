#
# List_Test.4gl    List Management Unit Tests
#

import FGL Common
import FGL List

&include "../../Include/Types.4gh"



#
# Main: Unit Test
#

main

  call Run("MENU")
  
end main



#
#! Run
#
public function Run(p_request)

  define
    p_request string


  case p_request.toUpperCase()

    when "MENU"
      menu "List"
        command "Add Users"
          call Test_List1()
        command "Add or Delete Profile"
          call Test_List2()
        command "Add Profile"
          call Test_List3()
        command "Add Team"
          call Test_List4()
        command "Delete Snapshot"
          call Test_List5()
        command "Alert View Selection"
          call Test_List6()
        on action cancel
          exit menu
      end menu

    when "LIST1"
      call Test_List1()
    when "LIST2"
      call Test_List2()
    when "LIST3"
      call Test_List3()
    when "LIST4"
      call Test_List4()
    when "LIST5"
      call Test_List5()
    when "LIST6"
      call Test_List6()
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

-- %LIST 1: Add Users --
private function Test_List1()

  define
    pa_item dynamic array of t_item,
    p_idx integer

  # some test data
  for p_idx = 1 to 10
    let pa_item[p_idx].selected = FALSE
    let pa_item[p_idx].name = SFMT("User %1", p_idx)
  end for

  call List.Dialog_Select("Add Users to",
    "BMS Global Alert: Account Manager Alert",
    "Add", pa_item)

  for p_idx = 1 to 10
    if pa_item[p_idx].selected
    then
      display pa_item[p_idx].name
    end if
  end for

end function




-- %LIST 2: Add or Delete Profile --
private function Test_List2()

  define
    pa_item dynamic array of t_item,
    p_idx integer

  # some test data
  for p_idx = 1 to 10
    let pa_item[p_idx].selected = FALSE
    let pa_item[p_idx].name = SFMT("Profile %1", p_idx)
  end for

  call List.Dialog_DDSelect("Add or Delete Profile",
    "Platform and Appliance Menu",
    "Add", TRUE,  pa_item)

  for p_idx = 1 to 10
    if pa_item[p_idx].selected
    then
      display pa_item[p_idx].name
    end if
  end for

end function



-- %LIST 3: Add Profile -- 
private function Test_List3()

  define
    pa_item dynamic array of t_item,
    p_idx integer

  for p_idx = 1 to 10
    let pa_item[p_idx].selected = FALSE
    let pa_item[p_idx].name = SFMT("Profile %1", p_idx)
  end for

  call List.Dialog_Select("Add Profile", "Platform and appliance menu",
    "Add", pa_item)

end function



-- %LIST 4: Add Team --
private function Test_List4()

  define
    pa_item dynamic array of t_item,
    p_idx integer

  for p_idx = 1 to 10
    let pa_item[p_idx].selected = FALSE
    let pa_item[p_idx].name = SFMT("Team %1", p_idx)
  end for

  call List.Dialog_Select("Add Team", "GPaaS: NOC: NOC Sysads",
    "Add", pa_item)

end function




-- %LIST 5: Delete Snapshot --
private function Test_List5()

  define
    pa_item dynamic array of t_item,
    p_idx integer

  for p_idx = 1 to 10
    let pa_item[p_idx].selected = FALSE
    let pa_item[p_idx].name = SFMT("Snapshot %1", p_idx)
  end for

  call List.Dialog_Select("Delete Snapshot", "GPaas Global Alert Snapsho",
    "Delete", pa_item)

end function




-- %LIST 6: Alert View Selection --
private function Test_List6()

  define
    pa_item dynamic array of t_item,
    p_idx integer


  # test data
  let pa_item[1].name = "Global Settings"
  let pa_item[2].name = (1),"GPaaS"
  let pa_item[3].name = ts4(2),"BMS (list of named options, only one can be selected at a time"
  let pa_item[4].name = ts4(2),"Net Global Settings"

  let pa_item[5].name = "BMS-UK1 (named platform for the selected platform"
  let pa_item[6].name = ts4(1),"GPaaS Profiles (if any)"
  let pa_item[7].name = ts4(2),"Noc Alerts (named list of GPaaS applied profiles)"
  let pa_item[8].name = ts4(1),"BMS Profiles (if any)"
  let pa_item[9].name = ts4(2),"Noc Alerts (named list of BMS applied profiles)"
  let pa_item[10].name = ts4(2),"BMS-ULK Overrides"
  let pa_item[11].name = ts4(2),"Final Platform Settings"

  for p_idx = 1 to pa_item.getLength()
    let pa_item[p_idx].selected = FALSE
  end for

  call List.Dialog_Select("Alert View", "", "OK", pa_item)

  for p_idx = 1 to 10
    if pa_item[p_idx].selected
    then
      display pa_item[p_idx].name
    end if
  end for

end function






