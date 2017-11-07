#############################################################################
#
# lib_ui
#
# PUBLIC
#! ui_ComboList: set INCLUDE values in a Combo widget
#! ui_FieldGet: Get an attribute from a Field node in the current window
#! ui_FieldNode: Return node for a Form Field identified by name
#! ui_FieldSet: Set an attribute of a Field node in the current window
#! ui_ItemGet: Get an attribute from a Form Item in the current window
#! ui_ItemNode: Return Node for a Form Item in the current window
#! ui_ItemSet: Set an attribute of a Form Item in the current window
#! ui_NodeGet: Get an attribute from a Node in the current window
#! ui_NodeFind: Finds first Node matching Class and Name
#! ui_NodeSet: Set an attribute of a Node in the current window
#! ui_NodeListFind: Finds a List of Nodes matching Class and Name
#! ui_MenuAttach: Create and attach a Menu object
#! ui_TableSize: Sets maximum number of rows in table
#! ui_StyleGet: Get style attribute
#! ui_StyleSet: Set style attribute
#! ui_WidgetGet: Get an attribute from a Field Widget in the current window
#! ui_WidgetNode: Get Node for a Field Widget in the current window
#! ui_WidgetSet: Set an attribute of a Field Widget in the current window
#! ui_WindowTitle: Set the title bar text of the current window
#
# PRIVATE
#! loc_XPathExpr: returns an XPath expression for a class and name
#
#############################################################################

#
# class: Field, Widget, Node
#
# TableColumn, FormField: colName
# p_class could be simply "Field", "Column" or tag type or
#   FormField/Edit
# p_name could be name or expression eg. tag='abc"
#


# Actions
#   /UserInterface/LocalAction
#   /UserInterface/ActionDefaultList/ActionDefault
#   //Window/Menu/MenuAction
#   //Window/Dialog/LocalAction
#   //Window/Dialog/Action
#





#
# Combo:
#

############################################################################
#
#! ui_ComboList:
#+ Sets the INCLUDE values in a Combo widget
#+
#+ @param p_colName   Field or column name of combo widget
#+ @param p_query     SQL statement or a pipe (|) separated list of tuples
#+                    where each tuple may be value,description pair sep by (^)
#+
#+ @code
#+ call ui_ComboList("honorific", "Mr|Mrs|Miss|Ms")
#+ call ui_ComboList("state", "SELECT stateId, name FROM states")
#
############################################################################

public function ui_ComboList(p_colName, p_query)

  define
    p_colName string,
    p_query   string,

    p_key     string,
    p_value   string,
    p_end     integer,
    d_combo   ui.ComboBox,
    o_list    base.StringTokenizer


  ### Trim in case CHAR was passed ###
  let p_colName = p_colName.trim()
  let p_query = p_query.trim()

  ### Get node for ComboBox ###
  let d_combo = ui.ComboBox.forName(p_colName)
  if d_combo is NULL
  then
    return
  end if

  ### Clear previous items ###
  call d_combo.clear()

  ### Process according to what's in query ###
  if p_query.toUpperCase() matches "SELECT*FROM*"
  then
    ### Prepare query ###
    prepare q_comboList from p_query
    declare c_comboList cursor for q_comboList

    ### Get list of values ###
    foreach c_comboList into p_key, p_value
      if p_value is NULL
      then
        let p_value = p_key clipped
      end if
      call d_combo.addItem(p_key clipped, p_value clipped)
      let p_value = NULL
    end foreach
  else
    ### Query is simple list of values ###
    let o_list = base.StringTokenizer.create(p_query, "|")
    while o_list.hasMoreTokens()
      let p_value = o_list.nextToken()
      if p_value matches "*^*"
      then
        let p_end = p_value.getIndexOf("^", 1)
        let p_key = p_value.subString(1, p_end-1)
        let p_value = p_value.subString(p_end+1, length(p_value))
      else
        let p_key = p_value clipped
      end if
      call d_combo.addItem(p_key clipped, p_value clipped)
    end while
  end if

end function






#
# Fields: Form Field ops
#

#############################################################################
#
#! ui_FieldGet
#+ Get an attribute from a Field node in the current window
#+
#+ @param p_name    Name of field (either name=table.column or colName=column)
#+ @param p_attrib  Attribute of field
#+
#+ @returnType      String
#+ @return          Value of attribute
#+
#+ @code
#+ define p_value string
#+ let p_value = ui_FieldGet("customer.name", "varType")
#
#############################################################################

public function ui_FieldGet(p_name, p_attrib)

  define
    p_name    string,
    p_attrib  string,

    d_field   om.DomNode,
    p_value   string

{
  ### Look into current window ###
  let d_win = om_WindowNode(NULL)

  ### Try FormField first ###
  let p_value = ui_NodeGet(d_win, "FormField", p_name, p_attrib)
  if p_value.getLength() = 0
  then
    ### Otherwise try TableColumn ###
    let p_value = ui_NodeGet(d_win, "TableColumn", p_name, p_attrib)
  end if
}

  ### If Field node found, get attribute ###
  let d_field = ui_FieldNode(p_name)
  if d_field is not NULL
  then
    let p_value = d_field.getAttribute(p_attrib)
  end if

  return p_value

end function




#############################################################################
#
#! ui_FieldNode
#+ Return node for a Form Field identified by name
#+
#+ @param p_name  Name of field (either name=table.column or colName=column)
#+
#+ @returnType    om.DomNode
#+ @return        DomNode of FormField
#+
#+ @code
#+ define d_custid om.DomNode
#+ let d_custid = ui_FieldNode("custid")
#
#############################################################################

public function ui_FieldNode(p_name)

  define
    p_name    string,

    d_win     om.DomNode,
    d_field   om.DomNode


  ### Look into current window ###
  let d_win = om_WindowNode(NULL)

  ### Try FormField first ###
  let d_field = ui_NodeFind(d_win, "FormField", p_name)
  if d_field is NULL
  then
    ### Otherwise try TableColumn ###
    return ui_NodeFind(d_win, "TableColumn", p_name)
  else
    return d_field
  end if

end function




#############################################################################
#
#! ui_FieldSet
#+ Set an attribute of a Field node in the current window
#+
#+ @param p_name    Name of field (either name=table.column or colName=column)
#+ @param p_attrib  Attribute of field
#+ @param p_value   Value to set attribute to
#+
#+ @code
#+ call ui_FieldSet(p_name, p_attrib, p_value)
#
#############################################################################

public function ui_FieldSet(p_name, p_attrib, p_value)

  define
    p_name    string,
    p_attrib  string,
    p_value   string,

    d_field   om.DomNode

{
  ### Current window ###
  let d_win = om_WindowNode(NULL)

  ### Try both ###
  call ui_NodeSet(d_win, "FormField", p_name, p_attrib, p_value)
  call ui_NodeSet(d_win, "TableColumn", p_name, p_attrib, p_value)
}

  ### If Field node found, set attribute ###
  let d_field = ui_FieldNode(p_name)
  if d_field is not NULL
  then
    call d_field.setAttribute(p_attrib, p_value)
  end if

end function





#
# Item: Form Item ops
#

#############################################################################
#
#! ui_ItemGet
#+ Get an attribute from a Form Item in the current window
#+
#+ @param p_class   Class of Form Item (node tag: Eg. Table, Group, Grid, ...)
#+ @param p_name    Name attribute, MUST have NAME defined for Item in form spec
#+ @param p_attrib  Attribute of item
#+
#+ @returnType      String
#+ @return          Value of attribute
#+
#+ @code
#+ define p_value string
#+ let p_value = ui_ItemGet("Table", "t_list", "tabName")
#
#############################################################################

public function ui_ItemGet(p_class, p_name, p_attrib)

  define
    p_class   string,
    p_name    string,
    p_attrib  string

  return ui_NodeGet(om_WindowNode(NULL), p_class, p_name, p_attrib)

end function




#############################################################################
#
#! ui_ItemNode
#+ Return Node for a Form Item in the current window
#+
#+ @param p_class Class of Form Item (node tag: Eg. Table, Group, Grid, ...)
#+ @param p_name  Name attribute - MUST have NAME defined for Item in form spec
#+
#+ @returnType    om.DomNode
#+ @return        DomNode for the named Form Item
#+
#+ @code
#+ define d_table om.DomNode
#+ let d_table = ui_ItemNode("Table", "t_list")
#
#############################################################################

public function ui_ItemNode(p_class, p_name)

  define
    p_class   string,
    p_name    string

  return ui_NodeFind(om_WindowNode(NULL), p_class, p_name)

end function




#############################################################################
#
#! ui_ItemSet
#+ Set an attribute of a Form Item in the current window
#+
#+ @param p_class   Class of Form Item (node tag: Eg. Table, Group, Grid, ...)
#+ @param p_name    Name attribute, MUST have NAME defined for Item in form spec
#+ @param p_attrib  Attribute of item
#+ @param p_value   Value to set attribute to
#+
#+ @code
#+ call ui_ItemSet("Table", "t_list", "width", "38")
#
#############################################################################

public function ui_ItemSet(p_class, p_name, p_attrib, p_value)

  define
    p_class   string,
    p_name    string,
    p_attrib  string,
    p_value   string

  call ui_NodeSet(om_WindowNode(NULL), p_class, p_name, p_attrib, p_value)

end function





#
# Node: UI node
#

#############################################################################
#
#! ui_NodeGet
#+ Get an Attribute from a Node
#+
#+ @param d_root    Root node (NULL defaults to UI node) to search from
#+ @param p_class   Class of Form Item (node tag: Eg. Table, Group, Grid, ...)
#+ @param p_name    Name attribute, MUST have NAME defined for Item in form spec
#+ @param p_attrib  Attribute of item
#+
#+ @returnType      String
#+ @return          Value of attribute
#+
#+ @code
#+ define d_win om.DomNode, p_value string
#+ let d_win = om_WindowNode(NULL)
#+ let p_value = ui_NodeGet(d_win, "Group", "gPage", "text")
#
#############################################################################

public function ui_NodeGet(d_root, p_class, p_name, p_attrib)

  define
    d_root    om.DomNode,
    p_class   string,
    p_name    string,
    p_attrib  string


  ### Determine attribute field for name ###
  return om_NodeAttribGet(d_root,
    loc_XPathExpr("//", p_class, p_name), p_attrib)

end function




#############################################################################
#
#! ui_NodeFind
#+ Finds first Node matching Class (tag) and Name
#+
#+ @param d_root    Root node (defaults to UI node)
#+ @param p_class   Class of Form Item (node tag: Eg. Table, Group, Grid, ...)
#+ @param p_name    Name attribute, MUST have NAME defined for Item in form spec
#+
#+ @returnType      om.DomNode
#+ @return          First Node that matches
#+
#+ @code
#+ define d_win, d_group om.DomNode
#+ let d_win = om_WindowNode(NULL)
#+ let d_group = ui_NodeFind(d_win, "Group", "gPage")
#
#############################################################################

public function ui_NodeFind(d_root, p_class, p_name)

  define
    d_root    om.DomNode,
    p_class   string,
    p_name    string,

    d_list    om.NodeList


  ### get list of matching nodes ###
  return om_NodeSelect(d_root, loc_XPathExpr("//", p_class, p_name))

end function




#############################################################################
#
#! ui_NodeSet
#+ Set an attribute of a Node in the current window
#+
#+ @param d_root    Root node (defaults to UI node)
#+ @param p_class   Class of Form Item (node tag: Eg. Table, Group, Grid, ...)
#+ @param p_name    Name attribute, MUST have NAME defined for Item in form spec
#+ @param p_attrib  Attribute of item
#+ @param p_value   Value to set attribute to
#+
#+ @code
#+ define d_win om.DomNode
#+ let d_win = om_WindowNode(NULL)
#+ call ui_NodeSet(d_win, "Group", "gPage", "text", "Instances")
#
#############################################################################

public function ui_NodeSet(d_root, p_class, p_name, p_attrib, p_value)

  define
    d_root    om.DomNode,
    p_class   string,
    p_name    string,
    p_attrib  string,
    p_value   string


  call om_NodeAttribSet(d_root, loc_XPathExpr("//", p_class, p_name),
    p_attrib, p_value)

end function




#############################################################################
#
#! ui_NodeListFind
#+ Finds a List of Nodes matching Class and Name
#+
#+ @param d_root    Root node (defaults to UI node)
#+ @param p_class   Class of Form Item (node tag: Eg. Table, Group, Grid, ...)
#+ @param p_name    Name attribute, MUST have NAME defined for Item in form spec
#+
#+ @returnType      om.NodeList
#+ @return          NodeList of matched nodes
#+
#+ @code
#+ define d_win om.DomNode, d_list om.NodeList
#+ let d_win = om_WindowNode(NULL)
#+ let d_list = ui_NodeListFind(d_win, "LocalAction", "interrupt")
#
#############################################################################

public function ui_NodeListFind(d_root, p_class, p_name)

  define
    d_root    om.DomNode,
    p_class   string,
    p_name    string


  ### get list of matching nodes ###
  return om_NodeListSelect(d_root, loc_XPathExpr("//", p_class, p_name))

end function




#############################################################################
#
#! ui_MenuAttach
#+ Create and attach a Menu object
#+
#+ @param d_parent  DomNode of parent to attach menu object
#+ @param p_class   TopMenuGroup|TopMenuCommand|StartMenuGroup|StartMenuCommand
#+ @param p_text    Text for group
#+ @param p_image   Optional image
#+ @param p_cmd     Command (shell) to execute
#+
#+ @returnType      om.DomNode
#+ @return          DomNode of menu object
#+
#+ @code
#+ define d_menu, d_grp, d_cmd om.DomNode
#+ let d_menu = ui_ItemNode("TopMenu", "top")
#+ let d_grp = ui_MenuAttach(d_menu, "TopMenuGroup", "Config", "folder", "")
#+ let d_menu = ui_MenuAttach(d_grp, "TopMenuCommand", "Setup", "leaf", "teams")
#
#############################################################################

public function ui_MenuAttach(d_parent, p_class, p_text, p_image, p_cmd)

  define
    d_parent  om.DomNode,
    p_class   string,
    p_text    string,
    p_cmd     string,
    p_image   string,

    p_type    string,
    p_attrib  string,
    d_child   om.DomNode


  ### Type of menu ###
  case p_class
  when "TopMenuGroup"
  when "TopMenuCommand"
    let p_attrib = "name"
  when "StartMenuGroup"
  when "StartMenuCommand"
    let p_attrib = "exec"
  otherwise
    return NULL
  end case

  let d_child = d_parent.createChild(p_class)
  call d_child.setAttribute("text", _(p_text))
  call d_child.setAttribute("image", p_image)
  if p_attrib.getLength()
  then
    call d_child.setAttribute(p_attrib, p_cmd)
  end if

  return d_child

end function




#
# Table
#

############################################################################
#
#! ui_TableSize
#+ Sets maximum number of rows in table
#+
#+ @param p_table   Name of table in current form
#+ @param p_rows    Number of rows
#+
#+ @code
#+ call ui_TableSize("t_list", 100)
#
############################################################################

public function ui_TableSize(p_table, p_rows)

  define
    p_table   string,
    p_rows    integer,

    d_win     om.DomNode


  ### Look into current window ###
  let d_win = om_WindowNode(NULL)

  call ui_NodeSet(d_win, "Table", p_table, "size", p_rows)

end function




#
# Style
#
# % Dynamically create Style & Attribute if it doesn't exist?
#

#############################################################################
#
#! ui_StyleGet
#+ Get Style Attribute
#+
#+ @param p_style   Style name
#+ @param p_attrib  Style attribute
#+
#+ @returnType      String
#+ @return          Style Attribute value
#+
#+ @code
#+ define p_value string
#+ let p_value = ui_StyleGet("Label.Heading", "fontFamily")
#
#############################################################################

public function ui_StyleGet(p_style, p_attrib)

  define
    p_style     string,
    p_attrib    string,

    d_aui       om.DomNode,
    p_path      string


  ### Look into AUI ###
  let d_aui = om_UInode()

  ### Hunt for matching style ###
  let p_path = loc_XPathExpr("//", "Style", p_style),
    loc_XPathExpr("/", "StyleAttribute", p_attrib)

  return om_NodeAttribGet(d_aui, p_path, "value")

end function




#############################################################################
#
#! ui_StyleSet
#+ Set Style Attribute
#+
#+ @param p_style   Style name
#+ @param p_attrib  Style attribute
#+ @param p_value   Value to set attribute to
#+
#+ @code
#+ call ui_StyleSet("Label.Heading", "fontFamily", "Helvetica")
#
#############################################################################

public function ui_StyleSet(p_style, p_attrib, p_value)

  define
    p_style     string,
    p_attrib    string,
    p_value     string,

    d_aui       om.DomNode,
    p_path      string


  ### Look into AUI ###
  let d_aui = om_UInode()

  ### Hunt for matching style ###
  let p_path = loc_XPathExpr("//", "Style", p_style),
    loc_XPathExpr("/", "StyleAttribute", p_attrib)

  call om_NodeAttribSet(d_aui, p_path, "value", p_value)

end function




#
# Widget
#

#############################################################################
#
#! ui_WidgetGet
#+ Get an attribute from a Field Widget in the current window
#+ Widget is typically a child of a FormField or TableColumn
#+
#+ @param p_class   Class - defaults to FormField/* or TableColumn/*
#+                  but can specify specific eg. TableColumn/Edit
#+ @param p_name    Name of field in primary node
#+ @param p_attrib  Attribute of field
#+
#+ @returnType      String
#+ @return          Value of attribute
#+
#+ define p_value string
#+ let p_value = ui_WidgetGet(NULL, "custid", "color")
#+ let p_value = ui_WidgetGet("TableColumn/Edit", "account", "format")
#
#############################################################################

public function ui_WidgetGet(p_class, p_name, p_attrib)

  define
    p_class     string,
    p_name      string,
    p_attrib    string,

    d_win       om.DomNode,
    d_widget    om.DomNode,
    p_fieldPath string,
    p_tablePath string


{
  ### default to a Field widget ###
  if p_class.getLength()
  then
    let p_fieldPath = p_class
    let p_tablePath = ""
  else
    let p_fieldPath = "FormField/*"
    let p_tablePath = "TableColumn/*"
  end if

  ### Look into current window ###
  let d_win = om_WindowNode(NULL)

  ### Try FormField first ###
  let p_value = ui_NodeGet(d_win, p_fieldPath, p_name, p_attrib)
  if p_value.getLength()
  then
    return p_value
  end if

  ### Otherwise try TableColumn ###
  if p_tablePath.getLength()
  then
    return ui_NodeGet(d_win, p_tablePath, p_name, p_attrib)
  end if
}

  ### Find widget node, and return attribute if found ###
  let d_widget = ui_WidgetNode(p_class, p_name)
  if d_widget is not NULL
  then
    return d_widget.getAttribute(p_attrib)
  else
    return ""
  end if

end function




#############################################################################
#
#! ui_WidgetNode
#+ Get Node for a Field Widget in the current window
#+ Widget is typically a child of a FormField or TableColumn
#+
#+ @param p_class   Class - defaults to FormField/* or TableColumn/*
#                   but can specify specific eg. TableColumn/Edit
#+ @param p_name    Name of field in primary node
#+
#+ @returnType      om.DomNode
#+ @return          Node for a Class of widget identified by Name
#+
#+ @code
#+ define d_cust om.DomNode 
#+ let d_cust = ui_WidgetNode("", "formonly.custid")
#+ let d_cust = ui_WidgetNode("FormField/ButtonEdit", "custid")
#
#############################################################################

public function ui_WidgetNode(p_class, p_name)

  define
    p_class     string,
    p_name      string,
    p_attrib    string,

    d_win       om.DomNode,
    d_node      om.DomNode,
    p_fieldPath string,
    p_tablePath string


  ### default to a Field widget ###
  if p_class.getLength()
  then
    let p_fieldPath = p_class
    let p_tablePath = ""
  else
    let p_fieldPath = "FormField/*"
    let p_tablePath = "TableColumn/*"
  end if

  ### Look into current window ###
  let d_win = om_WindowNode(NULL)
  let d_node = NULL

  ### Try FormField first ###
  let d_node = ui_NodeFind(d_win, p_fieldPath, p_name)

  ### Otherwise try TableColumn ###
  if d_node is NULL and p_tablePath.getLength()
  then
    let d_node = ui_NodeFind(d_win, p_tablePath, p_name)
  end if

  return d_node

end function




#############################################################################
#
#! ui_WidgetSet
#+ Set an attribute of a Field Widget in the current window
#+
#+ @param p_class   Class - defaults to FormField/* or TableColumn/*
#                   but can specify specific eg. TableColumn/Edit
#+ @param p_name    Name of field in primary node
#+ @param p_attrib  Attribute of field
#+ @param p_value   Value to set attribute to
#+
#+ @code
#+ call ui_WidgetSet("", "password", "isPassword", TRUE)
#+ call ui_WidgetSet("FormField/*", "password", "isPassword", TRUE)
#
#############################################################################

public function ui_WidgetSet(p_class, p_name, p_attrib, p_value)

  define
    p_class   string,
    p_name    string,
    p_attrib  string,
    p_value   string,

    d_win     om.DomNode,
    d_widget  om.DomNode,
    p_fieldPath string,
    p_tablePath string


{
  ### default to a Field widget ###
  if p_class.getLength()
  then
    let p_fieldPath = p_class
    let p_tablePath = ""
  else
    let p_fieldPath = "FormField/*"
    let p_tablePath = "TableColumn/*"
  end if

  ### Current window ###
  let d_win = om_WindowNode(NULL)

  ### Try both ###
  call ui_NodeSet(d_win, p_fieldPath, p_name, p_attrib, p_value)
  if p_tablePath.getLength()
  then
    call ui_NodeSet(d_win, p_tablePath, p_name, p_attrib, p_value)
  end if
}

  ### Find widget node, and return attribute if found ###
  let d_widget = ui_WidgetNode(p_class, p_name)
  if d_widget is not NULL
  then
    call d_widget.setAttribute(p_attrib, p_value)
  end if

end function






############################################################################
#
#! ui_WindowTitle
#+ Set the Title bar text of the current window
#+
#+ @param p_text  Window Text
#+
#+ @code
#+ call ui_WindowTitle("My Window")
#
############################################################################

public function ui_WindowTitle(p_text)

  define
    d_win     ui.Window,
    p_text    string  

  let d_win = ui.Window.getCurrent()

  if d_win is not NULL
  then
    call d_win.setText(_(p_text.trim()))
  end if

end function  





############################################################################
#
#! loc_XPathExpr
#+ PRIVATE: returns an XPath expression for a class and name
#+
#+ @param p_prefix  Prefix to this expression, typically "//" or "/"
#                   but could be a partial expression like "//Style/"
#+ @param p_class   Class (tag type) of node
#+ @param p_name    name, colName or attrib='value' expression
#+
#+ @param p_xpath   XPath expression
#+
#+ @code
#+ define p_xpath string
#+ let p_xpath =  ui_XPathExpr("", "Edit", "custid")
#+ let p_xpath =  ui_XPathExpr("/", "Window", "w_main")
#+ let p_xpath =  ui_XPathExpr("//Style", "StyleAttribute", "menuPosition")
#
############################################################################

private function loc_XPathExpr(p_prefix, p_class, p_name)

  define
    p_prefix    string,
    p_class     string,
    p_name      string,

    p_subClass  string,
    p_expr      string,
    p_xpath     string


  ### Is there a sub class? ###
  let p_subClass = ""
  if p_class matches "*/*"
  then
    call str_Split(p_class, "/")
      returning p_class, p_subClass
    if p_subClass.getLength()
    then
      let p_subClass = "/", p_subClass
    end if
  end if

  ### Determine attribute field for name ###
  case
  when p_name matches "*=*"
    ### attrib='value' override ###
    let p_expr = "@", p_name.Trim()
  when (p_class matches "FormField*" or p_class matches "TableColumn*")
    and p_name not matches "*.*"
    ### columnName only ###
    let p_expr = "@colName='", p_name.Trim(), "'"
  otherwise
    ### table.columnName ###
    let p_expr = "@name='", p_name.Trim(), "'"
  end case

  let p_xpath = p_prefix, p_class.Trim(), "[", p_expr, "]", p_subClass

  return p_xpath

end function
