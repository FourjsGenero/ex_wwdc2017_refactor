import FGL Common
import FGL UI
import FGL Selection
import FGL Employee

schema hr

private constant k_screenList = "emp_list"
private define
  ma_fields dynamic array of string





#############################################################################
#
#! Init
#+ Initialize the module
#+
#+ @code
#+ call Emp_View.Init()
#
#############################################################################
public function Init()
    
  defer interrupt
  defer quit
  options input wrap
  options field order form
  
  -- Set decorations
  -- call fgl_setTitle("Employees")
  call ui.interface.loadStyles("hr1")
  call ui.interface.loadActionDefaults("hr1")
  --%call ui.interface.loadTopMenu("opt")
  call ui.interface.loadToolBar("opt1")


  -- List of data entry screen fields or records
  let ma_fields[1] = "emp_hdr.*"
  let ma_fields[2] = "emp_dtl.*"
  let ma_fields[3] = "pay_scr.*"
  let ma_fields[4] = "sick_scr.*"
  let ma_fields[5] = "annual_scr.*"
  
  -- Note this initializes Selection.mr_selection
  call Employee.Init()
  
  -- Selection: Set list refresh function and override any defaults
  let Selection.rCurrent.View_Refresh = function view_Refresh
  
end function



#############################################################################
#
#! Show
#+ Show View of Employee
#+
#+ @code
#+ call Emp_View.Show()
#
#############################################################################
public function Show()

  call Init()
  call Selection.Refresh()


  -- Open and display Employee form
  open form f_employee from "Employee"
  display form f_employee

  -- Initialize lookups
  call UI.Combo_List("employee.title_id", "select title_id, description from title order by 1")
  call UI.Combo_List("employee.country_id", "select country_id, name from country order by 2")
  call UI.Node_Set(NULL, "Label", "text='*'", "color", "red")
  
  dialog attributes(unbuffered)

    -- Coalesce sub-dialogs
    subdialog list_Browse
    subdialog Selection.Search
    subdialog employee_Edit
    subdialog paySummary_Edit
    subdialog sickLeave_Edit
    subdialog annualLeave_Edit

    -- Initialize Dialog
    before dialog
      -- Set array length, status and Save button
      call dialog.setArrayLength(k_screenList, Selection.rCurrent.count)
      call record_Status(dialog)
      call document_Touched(dialog, NULL)

      -- If no records in list, then can only be here to Add
      if Selection.rCurrent.count < 1
      then
        call Employee.New()
        next field emp_hdr.firstname
      end if 

    -- Setup brackground monitoring of touched fields
    {%OPT
    on idle 1
      call document_Touched(dialog, NULL)
    }
      
    #
    # Common actions to all sub-dialogs
    #

    -- Navigation
    on action first
      if dialog.getCurrentRow(k_screenList) > 1
      then
        call row_Set(dialog, 1)
      end if
      
    on action previous
      if dialog.getCurrentRow(k_screenList) > 1
      then
        call row_Set(dialog, dialog.getCurrentRow(k_screenList) - 1)
      end if
      
    on action next
      if dialog.getCurrentRow(k_screenList) < Selection.rCurrent.count
      then
        call row_Set(dialog, dialog.getCurrentRow(k_screenList) + 1)
      end if
      
    on action last
      if dialog.getCurrentRow(k_screenList) < Selection.rCurrent.count
      then
        {
        call row_Set(dialog, UI.Page_Row("NEXT", dialog.getCurrentRow(k_screenList),
          fgl_dialog_getBufferLength(), Selection.rCurrent.count))
        }
        call row_Set(dialog, Selection.rCurrent.count)
      end if
      
    -- Document actions
    on action query
      call Query(dialog)

    on action new --%attribute(image="new-active")
      call Employee.New()  

    on action trash
      call confirm_Delete(dialog)
      
    on action save
      message "Saving ..."
      if Employee.Put() = "OK"
      then
        call document_Touched(dialog, FALSE)
      end if
      message "Saved"

    on action cancel
      message "Cancel"
      call confirm_Cancel(dialog)


    -- Get out of here
    on action close
      call confirm_Save(dialog)
      exit dialog
      
  end dialog
  
end function



#############################################################################
#
#! Query
#+ Query by Example in the Form, updates the Selection set
#+
#+ @code
#+ call Emp_View.Query()
#
#############################################################################
public function Query(po_dialog ui.Dialog)

  define
    l_sql string

  -- In case touched
  call confirm_Save(po_dialog)

  -- Query by Form
  construct l_sql on employee.* from emp_hdr.*, emp_dtl.*
    on action cancel attributes(defaultView=YES)
      return      
  end construct

  -- Apply selection filter
  let Selection.rCurrent.where = l_sql
  call view_Refresh(po_dialog)
    
end function




#
# PRIVATE
#



#
# DIALOGS
#

#
#! list_Browse
#+ Browse through List of employees
#+
#+ @code
#+ subdialog list_Browse
#
private dialog list_Browse()

  define
    l_count integer

    
  display array Employee.aList to emp_list.* attributes(count=-1)

    before display
      call confirm_Save(dialog)
      
    before row
      call Employee.Get(Employee.ListItem_Key(arr_curr()))
      call record_Status(dialog)

    on sort
      -- Refresh selection set query
      let Selection.rCurrent.orderBy = Selection.SortKey_Fix(dialog.getSortKey(k_screenList))
      let Selection.rCurrent.desc = dialog.isSortReverse(k_screenList)
      call Selection.Refresh()

    on fill buffer
      let l_count = Employee.List_Load(fgl_dialog_getBufferStart(), fgl_dialog_getBufferLength())

    on action accept
      -- First field of Document page
      next field emp_hdr.firstname

  end display
    
end dialog

    

#
#! employee_Edit
#+ Edit the current Employee
#+
#+ @code
#+ subdialog employee_Edit(TRUE)
#

private dialog employee_Edit()
  
  define
    ok boolean,
    l_field string,
    l_error string,
    field_name string

  input Employee.rView.employee.* from emp_hdr.*, emp_dtl.*
    attributes(without defaults=true)

    on change firstname, middlenames, surname, preferredname, title_id,
      birthdate, gender, address1, address2, address3, address4,
      country_id, postcode, phone, mobile, email, startdate, position,
      taxnumber, base, basetype, sick_balance, annual_balance
      call document_Touched(dialog, TRUE)

    {%%% Web
    after field firstname, middlenames, surname, preferredname, title_id,
      birthdate, gender, address1, address2, address3, address4,
      country_id, postcode, phone, mobile, email, startdate, position,
      taxnumber, base, basetype, sick_balance, annual_balance
      
      -- Get current field and validate
      let l_field = dialog.getCurrentItem()
      call Employee.Valid_Field(l_field)
        returning ok, l_error
      if not ok
      then
        error l_error
        call dialog.nextField(l_field)
      end if
      %%%}
      
    after input
      -- as we Validate everything HERE:
      call Employee.Valid_Record() returning ok, l_error, field_name
      if not ok
      then
        error l_error
        call dialog.nextField(field_name)
      end if

  end input
  
end dialog


#
#! paySummary_Edit
#+ Edit Pay Summary
#+
#+ @code
#+ subdialog paySummary_Edit
#
private dialog paySummary_Edit()

  input array Employee.rView.pay from pay_scr.*
    attributes (without defaults)

    before input
      call Employee.Base_Set()
      
    on change pay_date, pay_amount
      call Employee.Base_Set()
      call document_Touched(dialog, TRUE)

    after delete
      call Employee.Base_Set()
      call document_Touched(dialog, TRUE)

  end input 
  
end dialog


#
#! sickLeave_Edit
#+ Edit Sick Leave
#+
#+ @code
#+ subdialog sickLeave_Edit
#
dialog sickLeave_Edit()

  input array Employee.rView.sick from sick_scr.*
    attributes (without defaults)
    
    before input
      call Employee.SickLeave_Balance()
      
    on change sick_date, sick_adjustment, sick_runningbalance 
      call Employee.SickLeave_Balance()
      call document_Touched(dialog, TRUE)
      
    after delete
      call Employee.SickLeave_Balance()
      call document_Touched(dialog, TRUE)
  end input
        
end dialog


#
#! annualLeave_Edit
#+ Edit Annual Leave
#+
#+ @code
#+ subialog annualLeave_Edit
#
dialog annualLeave_Edit()
      
  input array Employee.rView.annual from annual_scr.*
    attributes (without defaults)

    before input
      call Employee.AnnualLeave_Balance()
      
    on change annual_date, annual_adjustment, annual_runningbalance
      call Employee.AnnualLeave_Balance()
      call document_Touched(dialog, TRUE) 
      
    after delete
      call Employee.AnnualLeave_Balance()
      call document_Touched(dialog, TRUE)
  end input 

end dialog




#
#! row_Set
#+ Set the current row in list view
#+
#+ @param po_control  Controller dialog
#+ @param p_row       Row to set as current
#+
#+ @code
#+ define ra_line dynamic array of t_ZoneLine
#+ ...
#+ call row_Set(dialog) 
#
private function row_Set(po_dialog ui.Dialog, p_row INTEGER)

  define
    l_row integer
    
  call confirm_Save(po_dialog)
  --% let l_row = po_dialog.visualToArrayIndex(k_screenList, p_row)
  --% let l_row = po_dialog.arrayToVisualIndex(k_screenList, p_row)
  --% let l_row = Employee.ListItem_Key(p_row)
  call po_dialog.setCurrentRow(k_screenList, p_row)
  call Employee.Get(Employee.ListItem_Key(p_row))
  call record_Status(po_dialog)
        
end function



#
#! view_Refresh
#+ Refresh the View due to new search criteria
#+
#+ @param po_dialog     Controller dialog object
#+
#+ @code
#+ define ra_companies dynamic array of t_CompanyLine,
#+   l_search string
#+ ...
#+ on change l_search
#+   call view_Refresh(dialog)
#

private function view_Refresh(po_dialog ui.Dialog)

  define  
    r_view Employee.t_View,
    l_row integer,
    l_count integer

    
  call confirm_Save(po_dialog)
  call Selection.Refresh()
  call po_dialog.setArrayLength(k_screenList, Selection.rCurrent.count)
  let l_count = Employee.List_Load(fgl_dialog_getBufferStart(), fgl_dialog_getBufferLength())
  call record_Status(po_dialog)

  -- Refresh data for current row
  let l_row = po_dialog.getCurrentRow(k_screenList)
  call Employee.Get(iif(l_row, Employee.ListItem_Key(l_row), 0))
        
end function


#
#! record_Status
#+ Display status of the current selection set, ie. record n of m
#+
#+ @param po_control    Contoller dialog
#+
#+ @code
#+ call record_Status(dialog)
#

private function record_Status(po_control ui.Dialog)

  message sfmt("Record %1 of %2", po_control.getCurrentRow(k_screenList),
    po_control.getArrayLength(k_screenList))

end function



#
#! confirm_Cancel
#+ Check if modified and Prompt user to confirm to discard changes
#+
#+ @param po_dialog  Controller dialog object
#+
#+ @code
#+ call confirm_Cancel(dialog)
#

private function confirm_Cancel(po_dialog ui.Dialog)

  if UI.Fields_Touched(po_dialog, ma_fields, NULL)
  then
    if fgl_WinQuestion("Discard Changes?",
      "The current document has been modified.\nDo you wish to discard these changes?",
      "yes",
      "no|yes",
      "question",
      FALSE) =  "yes"
    then
      message "Discarding ..."
      call Employee.Get(rView.employee.employee_no)
      call document_Touched(po_dialog, FALSE)
      message "Changes discarded"
    end if
  end if

end function



#
#! confirm_Delete
#+ Dialog to confirm if record is to be deleted
#+
#+ @param po_dialog   Controller dialog object
#+
#+ @returnType        Boolean
#+ @return            TRUE if record was deleted
#+
#+ @code
#+ call confirm_Delete(dialog)
#

private function confirm_Delete(po_dialog ui.Dialog)

  define
    l_row integer
    --% ,l_deleted boolean


  --% let l_deleted = FALSE
  if fgl_WinQuestion("Delete Employee?",
    "Do you wish to Delete this employee and all related data?",
    "yes",
    "no|yes",
    "question",
    FALSE) =  "yes"
  then
    message "Deleting ..."
    if Employee.Delete(Employee.rView.employee.employee_no) = "OK"
    then
      # remove line and repositon to next or previous record
      let l_row = po_dialog.getCurrentRow(k_screenList)
      call document_Touched(po_dialog, FALSE)
      --% call Selection.Refresh()
      --% call po_dialog.deleteRow(k_screenList, l_row)
      call view_Refresh(po_dialog)
      call po_dialog.setCurrentRow(k_screenList, l_row)
      --% let l_deleted = TRUE
    end if
    message ""
  end if

  --% call document_Touched(po_dialog, FALSE)

  --% return l_deleted
end function



#
#! confirm_Save
#+ Check if record needs to be saved and prompt user to confirm
#+
#+ @param po_dialog  Controller dialog object
#+
#+ @code
#+ call confirm_Save(dialog)
#

private function confirm_Save(po_dialog ui.Dialog)

  if UI.Fields_Touched(po_dialog, ma_fields, NULL)
  then
    if fgl_WinQuestion("Unsaved Document",
      "The current document has been modified.\nDo you wish to Save this document?",
      "yes",
      "no|yes",
      "question",
      FALSE) =  "yes"
    then
      message "Saving ..."
      if Employee.Put() = "OK"
      then
        message "Employee saved"
      end if
    else
      call Employee.Get(rView.employee.employee_no)
      message "Changes discarded"
    end if
    call document_Touched(po_dialog, FALSE)
  end if

end function


#
#! document_Touched
#+ Update the status of whether the doc has been modified
#+ and activating or de-activating the Save/Cancel buttons
#+
#+ @param po_dialog   Controller dialog object
#+ @param p_state     State to set (TRUE or FALSE) or NULL if status quo
#+ ...
#+ call document_Touched(dialog, FALSE)
#
private function document_Touched(po_dialog ui.Dialog, p_state boolean)

  define
    l_state boolean,
    l_void string


  -- Reset touched state if state defined
  if p_state is not NULL
  then
    let l_void = UI.Fields_Touched(po_dialog, ma_fields, p_state)
  end if
  
  -- Set Save/Cancel button active according to state of document
  let l_state = UI.Fields_Touched(po_dialog, ma_fields, NULL)
  call po_dialog.setActionActive("save", l_state)
  call po_dialog.setActionActive("cancel", l_state)
  
end function
