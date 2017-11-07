#
# Selection.4gl: Module for managing Query Selection sets
#


##########################################################################
#
# TYPES
#
##########################################################################

-- Search Options
public type t_searchOptions
  record
    matchCase boolean,
    matchWord boolean,
    use dynamic array of
      record
        selected boolean,
        column string,
        name string,
        type string
      end record
  end record

public type t_selectDefault
  record
    orderBy string,
    join string
  end record

public type tf_listRefresh function(po_dialog ui.Dialog)
  
-- Selection %%rename Query
public type t_selection
  record
    select string,
    from string,
    where string,
    orderBy string,
    desc boolean,
    count integer,
    default t_selectDefault,
    options t_searchOptions,
    Data_Refresh function(),
    View_Refresh function(po_dialog ui.Dialog)
  end record

public constant
  k_AutoSearchLimit = 100


-- Local Data
public define
  rCurrent t_selection

-- a table description %%% Replace with 
{
DEFINE fields DYNAMIC ARRAY OF RECORD
    name STRING, -- a column name
    type STRING  -- a column type
END RECORD
}
  
##########################################################################
#
# PUBLIC FUNCTIONS
#
##########################################################################


#
# % Class model - These use internal storage for the package
#

# Options_Dialog
public function Options_Dialog()

  call xOptions_Dialog(rCurrent.options.*)
    returning rCurrent.options.*
    
end function

#Filter
public function Filter(p_match string) returns string

  return xFilter(rCurrent.*, p_match)

end function

#Query_String or SQL or QuerySQL
public function SQL(p_select string)
  returns string

  return xSQL(rCurrent.*, p_select)

end function

#Refresh
public function Refresh()

  call xRefresh(rCurrent.*)
  
end function



#
# % Below are for use caller's storage or an instance - %TBD
# PRIVATE for the moment, unless we need them
#

#
#! xOptions_Dialog
#+ Set search options to match case, word and choose which columns to include
#

private function xOptions_Dialog(pr_options t_searchOptions)

  define
    r_saved t_searchOptions

  -- Save options before in case of Cancel
  let r_saved.* = pr_options.*
  
  open window w_searchOptions with form "Selection_SearchOptions"
    attributes(STYLE="dialog")

  dialog attributes(unbuffered)

    input array pr_options.use from sca_columns.*
    end input

    input by name pr_options.matchCase, pr_options.matchWord
      attributes(without defaults)
    end input

    on action close
      let pr_options.* = r_saved.*
      exit dialog
      
    on action cancel
      let pr_options.* = r_saved.*
      exit dialog
      
    on action accept
      exit dialog
  end dialog
  
  close window w_searchOptions

  return pr_options.*

end function



#
#! xFilter
#+ Set selection where clause from search filter criteria 
#+
#+ @param p_match   Match wildcard pattern
#+
#+ @code
#+ call Selection.Filter(r_selection.*, "A*")
#
# Options for Advanced?
#   match first or any
#   choose specific fields or all
#   ignore case
#

private function xFilter(pr_selection, p_match)

  define
    pr_selection t_selection,
    p_match string,
    l_cond, l_or, l_any, l_where string,
    l_col integer

  let l_where = ""

  #
  # to match any case
  #  upper(column) matches upper(p_match)
  # if match specific string, remove the "*"
  #
  if p_match.getLength()
  then
    -- match specific word?
    let l_any = iif(pr_selection.options.matchWord, "", "%")
    
    -- for each filterable column, add to Where clause
    let l_or = " "
    for l_col = 1 to pr_selection.options.use.getLength()
      if pr_selection.options.use[l_col].selected
      then
        if pr_selection.options.matchCase
        then
          let l_cond = l_or, pr_selection.options.use[l_col].column, "||'' like '", l_any, p_match, l_any, "'"
        else
          let l_cond = l_or, "upper(", pr_selection.options.use[l_col].column, "||'') like upper('", l_any, p_match, l_any, "')"
        end if
        let l_where = l_where.append(l_cond)
        let l_or = " or "
      end if
    end for
  end if

  return l_where
  
end function




#
#! xSQL
#+ Return SQL query for a selection set 
#+
#+ @param pr_selection  Selection set
#+ @param p_select      "data", "count"
#+
#+ @code
#+ define p_query string
#+ ...
#+ let p_query =  Selection.xSQL(pr_selection.*, "data")
#

private function xSQL(pr_selection, p_select)

  define
    pr_selection t_Selection,
    p_select string,

    l_orderBy, l_where, l_and, l_query string


  let l_orderBy = NVL(pr_selection.orderBy, pr_selection.default.orderBy)

  let l_where = iif(pr_selection.default.join.getLength(), SFMT("(%1)", pr_selection.default.join), "")
  let l_and = iif(l_where.getLength(), " and ", " ")
  let l_where = l_where.append(iif(pr_selection.where.getLength(), l_and || "(" || pr_selection.where || ")", ""))


  let l_query =
    "select ", pr_selection.select,
    " from ", pr_selection.from,
    iif(l_where.getLength(), " where ", ""), l_where
    
  case p_select.toUpperCase()
  when "COUNT"
    let l_query = "select count(*) from (", l_query, ")"
  otherwise
    let l_query =  l_query,
      " ", iif(l_orderBy.getLength(), "order by " || l_orderBy, ""),
      " ", iif(pr_selection.desc, " desc", "")
  end case

  return l_query
    
end function



#
#! xRefresh
#+ Selection refresh 
#+
#+ @param pr_selection  Selection set
#+
#+ @code
#+ define p_query string
#+ ...
#+ call Selection.xRefresh(pr_selection.*)
#

private function xRefresh(pr_selection t_selection)

  call pr_selection.Data_Refresh()
  
end function


#
#! SortKey_Fix
#+ Fix the sort key if it has an underscore prefix, used if column already exists
#+
#+ @param p_key   Raw sort key
#+
#+ @code
#+ let Selection.rCurrent.orderBy = Selection.SortKey_Fix(dialog.getSortKey(k_screenList))
#
public function SortKey_Fix(p_key string) returns string

  while p_key matches "_*"
    let p_key = p_key.subString(2,p_key.getLength())
  end while

  return p_key
  
end function






#
# Adapted from $FGLDIR/demo/dbbrowser/dbbrowser.4gl
#
private function createDisplayArrayForm(tabName)
    define tabName string
    define i int
    define colName, colType string
    define f ui.Form
    define w ui.Window

    define window, form, grid, table, formfield, edit  om.DomNode

    let w = ui.Window.getCurrent()
    let f = w.createForm("test")
    let form = f.getNode()

    --
    let window = form.getParent()
    call window.setAttribute("text", tabName)
    --
    let grid = form.createChild("Grid")
    call grid.setAttribute("width", 1)
    call grid.setAttribute("height", 1)
    let table = grid.createChild("Table")
    call table.setAttribute("doubleClick", "update")
    call table.setAttribute("tabName", tabName)
    call table.setAttribute("pageSize", 10)
    call table.setAttribute("gridWidth", 1)
    call table.setAttribute("gridHeight", 1)
    for i = 1 to rCurrent.options.use.getLength()
        let formfield = table.createChild("TableColumn")
        let colName = rCurrent.options.use[i].column
        let colType = rCurrent.options.use[i].type
        call formfield.setAttribute("text", colName)
        call formfield.setAttribute("colName", colName)
        call formfield.setAttribute("name", tabName || "." || colName)
        call formfield.setAttribute("sqlType", colType)
        --CALL formfield.setAttribute("fieldId", i)
        call formfield.setAttribute("tabIndex", i + 1)
        let edit = formfield.createChild("Edit")
        call edit.setAttribute("width", bestWidth(colType))
    end for
    --CALL form.writeXml("test.42f")
end function


private function bestWidth(t)
    define t string
    define i, j, len int
    if (i := t.getIndexOf('(', 1)) > 0 then
        if (j := t.getIndexOf(',', i + 1)) == 0 then
            let j = t.getIndexOf(')', i + 1)
        end if
        let len = t.subString(i + 1, j - 1)
        let t = t.subString(1, i - 1)
    end if
    case t
    when "BOOLEAN"  return 1
    when "TINYINT"  return 4
    when "SMALLINT" return 6
    when "INTEGER"  return 11
    when "BIGINT"   return 20
    when "SMALLFLOAT" return 14
    when "FLOAT"   return 14
    when "STRING"  return 20
    when "DECIMAL" return iif(len is null, 16, LEN + 2)
    when "MONEY"   return iif(len is null, 16, LEN + 2)
    when "CHAR"    return iif(len is null, 1, iif (len > 20, 20, len))
    when "VARCHAR" return iif(len is null, 1, iif (len > 20, 20, len))
    when "DATE"    return 10
    otherwise
        return 20
    end case
end function


private function describeTable(tabName)
    define tabName string
    define h base.SqlHandle
    define i int

    let h = base.SqlHandle.create()
    call h.prepare("select * from " || tabName)
    call h.open()
    call rCurrent.options.use.clear()
    for i = 1 to h.getResultCount()
        let rCurrent.options.use[i].column = h.getResultName(i)
        let rCurrent.options.use[i].name = rCurrent.options.use[i].column
        let rCurrent.options.use[i].type = h.getResultType(i)
    end for
    call h.close()
end function


##########################################################################
#
# DIALOGS
#
##########################################################################

#
#! Search
#+ Search dialog box
#+
#+ @code
#+ subdialog Selection.Search
#
public dialog Search()

  define
    l_search string

    
    #
    # Search
    #
    input by name l_search

      before input
        --%%% just for call confirm_Save
        -- do we really need a callback for context change?
        call rCurrent.View_Refresh(dialog)
        
      on change l_search
        -- Only do this when row count > limit?
        -- this is not practical unless data set is moderate
        if rCurrent.count < k_AutoSearchLimit
        then
          let rCurrent.where = Filter(l_search)
          call rCurrent.View_Refresh(dialog)
        end if

      after input
        let rCurrent.where = Filter(l_search)
        call rCurrent.View_Refresh(dialog)

      on action b_search
        call Options_Dialog()
    end input
    
end dialog

{
public dialog Find()

  define
    l_find string

    
    #
    # Search
    #
    input by name l_find

      after input
        ### Find NEXT
        --% let rCurrent.where = iFilter(l_find)
        call mF_listFind(dialog)
        --% call List_Refresh(ra_users, dialog)

      on action b_prev
        ### Find PREV
        
      on action b_search
        call Options_Dialog()
    end input
    
end dialog
}

##########################################################################
#
# UNIT TESTS
#
##########################################################################

#
# 1. Options Settings
# 2. Simgle Table
# 3. Multiple tables with a join
# 4. Mutliple tables with inner & outer joins
# 5. Apply Options
# 6. Apply Sort



