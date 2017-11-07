#
# List.4gl    List Management
#

import FGL Common
import FGL UI

--% &include "../../Include/Types.4gh"

##########################################################################
#
# PUBLIC TYPES
#
##########################################################################

public type t_item
  record
    selected  boolean,
    name      string,
    key       integer,
    idx       integer
  end record
public type ta_items dynamic array of t_item




##########################################################################
#
# PUBLIC FUNCTIONS
#
##########################################################################


#
#! Dialog_Select
#+ Dialog box to Select multiple items from a list
#
public function Dialog_Select(p_title, p_narrative, p_actionText, pa_item)
  define
    p_title string,
    p_narrative string,
    p_actionText string,
    pa_item ta_items,
    
    la_all, la_sel ta_items,
    l_search string,
    l_idx int


  ### Copy to local selection ALL and SEL (filtered) ###
  call List_Copy(pa_item, la_all, "")
  call List_Copy(pa_item, la_sel, "")

  ### Open window as dialog ###
  open window w_listSelect with form "List_Select"
    attributes(style="main2")
  call UI.Window_Title(p_title)
  display by name p_narrative

  ### mDialog with search, list ###
  dialog attribute(UNBUFFERED)

    input by name l_search
      before input
        call ButtonEdit_ContextActive(l_search)
      on change l_search
        call ButtonEdit_ContextActive(l_search)
        call List_Copy(la_all, la_sel, l_search)
    end input

    input array la_sel from sar_items.*
      on change selected
        # Save selection in full list
        let l_idx = dialog.getCurrentRow("sar_items")
        let la_all[la_sel[l_idx].idx].selected = la_sel[l_idx].selected
    end input

    before dialog
      call UI.Widget_Set("Button", "b_action", "text", p_actionText)

    on action b_clearsearch
      let l_search = ""
      call List_Copy(la_all, la_sel, l_search)
      call ButtonEdit_ContextActive(l_search)
      next field l_search

    on action b_selectall
      for l_idx = 1 to la_sel.getLength()
        let la_sel[l_idx].selected = TRUE
        let la_all[la_sel[l_idx].idx].selected = TRUE
      end for

    on action b_deselectall
      for l_idx = 1 to la_sel.getLength()
        let la_sel[l_idx].selected = FALSE
        let la_all[la_sel[l_idx].idx].selected = FALSE
      end for

    on action b_cancel
      exit dialog

    on action b_action
      call List_Copy(la_all, pa_item, "")
      exit dialog

  end dialog

  close window w_listSelect

end function



#
#! Dialog_DDSelect
#+ Dialog to Select multiple items, with Drag n Drop reorder
#
public function Dialog_DDSelect(p_title, p_narrative, p_actionText, p_drag, pa_item)
  define
    p_title string,
    p_narrative string,
    p_actionText string,
    p_drag boolean,
    pa_item ta_items,

    la_all, la_sel ta_items,
    l_search string,
    l_idx int,
    l_dragSeen boolean,
    o_dnd ui.DragDrop


  ### Copy to local selection ALL and SEL (filtered) ###
  call List_Copy(pa_item, la_all, "")
  call List_Copy(pa_item, la_sel, "")

  ### Open window as dialog ###
  open window w_listSelect with form "List_DDselect"
    attributes(style="main2")
  call UI.Window_Title(p_title)
  display by name p_narrative
  let l_dragSeen = FALSE

  ### mDialog with search, list ###
  dialog attribute(UNBUFFERED)

    input by name l_search
      before input
        call ButtonEdit_ContextActive(l_search)
      on change l_search
        call ButtonEdit_ContextActive(l_search)
        call List_Copy(la_all, la_sel, l_search)
    end input

    display array la_sel to sar_items.*
      before display
        call Dialog.setSelectionMode("sar_items", 1)
      #on change selected
        # Save selection in full list
      #  let l_idx = dialog.getCurrentRow("sar_items")
      #  let la_all[la_sel[l_idx].idx].selected = la_sel[l_idx].selected

      on key (' ')
        let l_idx = dialog.getCurrentRow("sar_items")
        let la_sel[l_idx].selected = not la_sel[l_idx].selected
        let la_all[la_sel[l_idx].idx].selected = la_sel[l_idx].selected

      on drag_start(o_dnd)
        let l_dragSeen = TRUE
      on drag_finished(o_dnd)
        let l_dragSeen = FALSE
      on drag_enter(o_dnd)
        if p_drag and not l_dragSeen
        then
          call o_dnd.setOperation(NULL)
        end if
      on drop(o_dnd)
        if p_drag
        then
          call o_dnd.dropInternal()
        end if
    end display

    before dialog
      call UI.Widget_Set("Button", "b_action", "text", p_actionText)

    on action b_clearsearch
      let l_search = ""
      call List_Copy(la_all, la_sel, l_search)
      call ButtonEdit_ContextActive(l_search)
      next field l_search

    on action b_selectall
      for l_idx = 1 to la_sel.getLength()
        let la_sel[l_idx].selected = TRUE
        let la_all[la_sel[l_idx].idx].selected = TRUE
      end for

    on action b_deselectall
      for l_idx = 1 to la_sel.getLength()
        let la_sel[l_idx].selected = FALSE
        let la_all[la_sel[l_idx].idx].selected = FALSE
      end for

    on action b_delete

    on action b_add

    on action b_cancel
      exit dialog

    on action b_ok
      call List_Copy(la_all, pa_item, "")
      exit dialog

  end dialog

  close window w_listSelect

end function



#
#! Copy
#+ Copy a list with optional filter
#
public function List_Copy(pa_src, pa_dst, p_filter)

  define
    pa_src, pa_dst ta_items,
    p_filter string,
    
    l_match string,
    l_sx, l_dx int


  ### set match criteria ###
  let l_match = p_filter.trim(), "*"

  ### Copy everyting across to dest if it matches including index to orig ###
  call pa_dst.clear()
  for l_sx = 1 to pa_src.getLength()
    if pa_src[l_sx].name.trim() matches l_match
    then
      call pa_dst.appendElement()
      let l_dx = pa_dst.getLength()
      let pa_dst[l_dx].name = pa_src[l_sx].name
      let pa_dst[l_dx].selected = pa_src[l_sx].selected
      let pa_dst[l_dx].idx = l_sx
    end if
  end for

end function


#
#! Item_Add
#+ Add an item to a list
#
public function Item_Add(pa_items, p_name, p_key, p_selected)

  define
    pa_items ta_items,
    p_name string,
    p_key integer,
    p_selected boolean,

    l_idx integer

  let l_idx = pa_items.getLength() + 1
  let pa_items[l_idx].name = p_name
  let pa_items[l_idx].key = p_key
  let pa_items[l_idx].selected = p_selected
  
end function




##########################################################################
#
# LOCAL
#
##########################################################################


#
# ButtonEdit_ContextActive: %%%TEMP DONT known where to put this yet
#
#

private function ButtonEdit_ContextActive(p_search)

  define
    p_search string
    

  if p_search.getLength()
  then
    call UI.ButtonEdit_ButtonActive("l_search", "delete", TRUE)
  else
    call UI.ButtonEdit_ButtonActive("l_search", "", FALSE)
  end if

end function

