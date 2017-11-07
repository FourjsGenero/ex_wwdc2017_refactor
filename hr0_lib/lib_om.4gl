############################################################################
#
# lib_om Index
#
# PUBLIC
#! om_ElementAttribGet
#! om_ElementAttribSet
#! om_ElementCreate
#! om_ElementDelete
#! om_FormNode
#! om_NodeAttribGet
#! om_NodeAttribSet
#! om_NodeFind
#! om_NodeSelect
#! om_NodeListSelect
#! om_UInode
#! om_WindowNode
#
# PRIVATE
#! loc_Init
#
############################################################################

private define
    md_aui    om.DomNode,
    md_doc    om.DomDocument




#
# DomDoc Element Functions
#

#############################################################################
#
#! om_ElementAttribGet
#+ Get attribute of a DomDoc element
#+
#+ @param p_elementID   Element ID of a DomNode
#+ @param p_attrib      Attribute of node
#+
#+ @returnType          String
#+ @return              Value of attribute
#+
#+ @code
#+ define p_value string
#+ let p_value = om_ElementAttribGet(100, "color")
#
#############################################################################

public function om_ElementAttributeGet(p_elementID, p_attrib)

  define
    p_elementID    integer,
    p_attrib       string,

    d_node         om.DomNode


  call loc_Init()

  let d_node = md_doc.getElementByID(p_elementID)
  return d_node.getAttribute(p_attrib)

end function




#############################################################################
#
#! om_ElementAttribSet
#+ Set attribute of an DomDoc element
#+
#+ @param p_elementID     Element ID of DomNode
#+ @param p_attrib        Attribute of node
#+ @param p_value         Value to set attribute to
#+
#+ @code
#+ call om_ElementAttribSet(100, "color", "red")
#
#############################################################################

public function om_ElementAttribSet(p_elementID, p_attrib, p_value)

  define
    p_elementID   integer,
    p_attrib      string,
    p_value       string,

    d_node    om.DomNode


  call loc_Init()

  let d_node = md_doc.getElementByID(p_elementID)
  call d_node.setAttribute(p_attrib, p_value)

end function




#############################################################################
#
#! om_ElementCreate
#+ Creates a DomDoc element
#+
#+ @param p_parentID  Element ID of parent DomNode
#+ @param p_tagName   Tagname of node to create
#+
#+ @returnType        integer
#+ @return            Element ID of DomNode
#+
#+ @code
#+ define p_nodeId integer
#+ let p_nodeId = om_ElementCreate(100, "StartMenuGroup")
#
#############################################################################

public function om_ElementCreate(p_parentID, p_tagName)

  define
    p_parentID  integer,
    p_tagName   string,

    d_parent    om.DomNode,
    d_child     om.DomNode


  call loc_Init()

  let d_parent = md_doc.getElementByID(p_parentID)
  let d_child = d_parent.createChild(p_tagName)

  return d_child.getID()

end function




#############################################################################
#
#! om_ElementDelete
#+ Deletes a DomDoc element and its children
#+
#+ @param p_parentID    Element ID of parent DomNode
#+
#+ @code
#+ call om_ElementDelete(100)
#
#############################################################################

public function om_ElementDelete(p_parentID)

  define
    p_parentID  integer,

    d_parent    om.DomNode


  call loc_Init()

  let d_parent = md_doc.getElementByID(p_parentID)
  call md_doc.removeElement(d_parent)

end function




############################################################################
#
#! om_FormNode
#+ Return the node for a form, defaults to current form
#+
#+ @param p_name  Name of the form, NULL defaults to current form
#+
#+ @returnType    om.DomNode
#+ @return        DomNode if found, otherwise NULL
#+
#+ @code
#+ define d_form om.DomNode
#+ let d_form = om_FormNode("customerForm")
#
############################################################################

public function om_FormNode(p_name)

  define
    p_name    string,

    d_parent  om.DomNode,
    d_child   om.DomNode


  if p_name is NULL
  then
    ### Look for current window ###
    let d_parent = om_WindowNode(NULL)
    if d_parent is NULL
    then
      return NULL
    end if

    ### See the oldies ###
    let d_child = d_parent.getFirstChild()

    ### Hunt for sibling Form ###
    while d_child is not NULL
      if d_child.getTagName() = "Form"
      then
        return d_child
      end if

      let d_child = d_child.getNext()
    end while
  else
    ### Now hunt everywhere for matching form ###
    return om_NodeFind(NULL, "Form", "name", p_name)
  end if

  return NULL

end function




#############################################################################
#
#! om_NodeAttribGet
#+ Get attribute of first node that matches XPath query
#+
#+ @param d_parent    DomNode of parent to search from,
#+                    NULL defaults to root node of UI
#+ @param p_xpath     XPath to node
#+ @param p_attrib    Style attribute
#+
#+ @returnType        String
#+ @return            Attribute value of the Node
#+
#+ @code
#+ define d_root om.DomNode, p_hidden boolean, p_file string
#+ let d_root = om_WindowNode("w_customer")
#+ let p_hidden = om_NodeAttribGet(d_root, "//FormField[@name='id']", "hidden")
#+ let p_file = om_NodeAttribGet(NULL, "/UserInterface/StyleList", "fileName")
#
#############################################################################

public function om_NodeAttribGet(d_parent, p_xpath, p_attrib)

  define
    d_parent    om.DomNode,
    p_xpath     string,
    p_attrib    string,

    d_list      om.NodeList,
    d_node      om.DomNode,
    p_idx       integer


{
  ### Default node is great ancestor ###
  if d_parent is NULL
  then
    call loc_Init()
    let d_parent = md_aui
  end if

  ### Hunt for matching nodes ###
  LET d_list = d_parent.selectByPath(p_xpath)
--%d display "xpath:", p_path,":"
--%d display "matched:", d_list.getLength()

  ### Set attribute ###
  for p_idx = 1 to d_list.getLength()
    let d_node = d_list.item(p_idx)
    return d_node.getAttribute(p_attrib)
  end for
}

  ### Node for first item returned by XPath query ###
  let d_node = om_NodeSelect(d_parent, p_xpath)
  if d_node is not NULL
  then
    return d_node.getAttribute(p_attrib)
  end if

  return ""

end function




#############################################################################
#
#! om_NodeAttribSet
#+ Set attribute of nodes that match XPath query
#+
#+ @param d_parent    DomNode of parent to search from,
#+                    NULL defaults to root node of UI
#+ @param p_xpath     XPath to node
#+ @param p_attrib    Style attribute
#+ @param p_value     Value to set attribute to
#+
#+ @code
#+ call om_NodeAttribSet(d_parent, p_xpath, p_attrib, p_value)
#
#############################################################################

public function om_NodeAttribSet(d_parent, p_xpath, p_attrib, p_value)

  define
    d_parent    om.DomNode,
    p_xpath     string,
    p_attrib    string,
    p_value     string,

    d_list      om.NodeList,
    d_node      om.DomNode,
    p_idx       integer


{
  ### Default node is great ancestor ###
  if d_parent is NULL
  then
    call loc_Init()
    let d_parent = md_aui
  end if

  ### Hunt for matching nodes ###
  LET d_list = d_parent.selectByPath(p_xpath)
--%d display "xpath:", p_path,":"
--%d display "matched:", d_list.getLength()

  ### Set attribute ###
  for p_idx = 1 to d_list.getLength()
    let d_node = d_list.item(p_idx)
--%d   display "Set ", p_attrib, " = ", p_value
    call d_node.setAttribute(p_attrib, p_value)
  end for
}

  ### Node list for XPath query ###
  let d_list = om_NodeListSelect(d_parent, p_xpath)

  ### Set all matching attributes ###
  for p_idx = 1 to d_list.getLength()
    let d_node = d_list.item(p_idx)
    call d_node.setAttribute(p_attrib, p_value)
  end for

end function




############################################################################
#
#! om_NodeFind
#+ Find first Node matching Tag and Attribute starting from a root Node
#+
#+ @param d_parent    DomNode of parent to search from,
#+                    NULL defaults to root node of UI
#+ @param p_tag       XML tag name
#+ @param p_attrib    Attribute to match, typically name, text or colName
#+ @param p_value     Matching value - can be metachar (wildcard) string
#+   
#+ @returnType        om.DomNode
#+ @return            DomNode if found, otherwise NULL
#+
#+ @code
#+ define d_aui, d_node om.DomNode
#+ let d_aui = ui.Interface.getRootNode()
#+ let d_node = om_NodeFind(d_aui, "Form", "name", "custForm")
#
# Limitations:
#   Only find first matching node, hopefully that should be unique enough
#   Recursive, probably more efficient to use Xpath with om_NodeSelect()
#
############################################################################

public function om_NodeFind(d_parent, p_tag, p_attrib, p_value)

  define
    d_parent  om.DomNode,
    p_tag     string,
    p_attrib  string,
    p_value   string,

    d_child   om.DomNode,
    p_nodeTag char(40),
    p_nodeValue char(80)


  ### Default node is great ancestor ###
  if d_parent is NULL
  then
    call loc_Init()
    let d_parent = md_aui
  end if

  ### Check if matching class, attribute matches value ###
  let p_nodeValue = d_parent.getAttribute(p_attrib)
  let p_nodeTag = d_parent.getTagName()
  if p_nodeTag matches p_tag
    and p_nodeValue matches p_value
  then
    return d_parent
  end if

  ### OK, then check the kids ###
  let d_parent = d_parent.getFirstChild()
  while d_parent is not NULL

    let d_child = om_NodeFind(d_parent, p_tag, p_attrib, p_value)
    if d_child is not NULL
    then
      return d_child
    end if

    let d_parent = d_parent.GetNext()
  end while

  return NULL

end function





#############################################################################
#
#! om_NodeSelect
#+ Get first Node matching XPath query
#+
#+ @param d_root     Root node to search from, defaults to UI node
#+ @param p_path     XPath to node
#+
#+ @returnType      om.DomNode
#+ @return          Returns first Node that matches the XPath expression
#+
#+ @code
#+ define d_win, d_menu om.DomNode
#+ let d_win = om_WindowNode("")
#+ let d_menu = om_NodeListFind(d_win, "//Form/TopMenu")
#+ let d_menu = om_NodeListFind(NULL, "//Window/Menu")
#
#############################################################################

public function om_NodeSelect(d_root, p_path)

  define
    d_root      om.DomNode,
    p_path      string,

    d_list      om.NodeList


  ### Get list of matching nodes ###
  let d_list = om_NodeListSelect(d_root, p_path)

  ### Return first match ###
  if d_list.getLength()
  then
    return d_list.item(1)
  else
    return NULL
  end if

end function




#############################################################################
#
#! om_NodeListSelect
#+ Gets a NodeList matching an XPath query
#+
#+ @param d_root    Root node to search from, defaults to UI node
#+ @param p_path    XPath expression
#+
#+ @returnType      om.NodeList
#+ @return          NodeList matching the XPath expression
#+
#+ @code
#+ define d_win om.DomNode, d_list om.NodeList
#+ let d_win = om_WindowNode(NULL)
#+ let d_list = om_NodeListFind(d_win, "//MenuAction")
#+ let d_list = om_NodeListFind(NULL, "//Style")
#
#############################################################################

public function om_NodeListSelect(d_root, p_path)

  define
    d_root      om.DomNode,
    p_path      string


  if d_root is NULL
  then
    call loc_Init()
    let d_root = md_aui
  end if

  return d_root.selectByPath(p_path)

end function




############################################################################
#
#! om_UInode
#+ Returns the AUI (Abstract User Interface) root Node
#+
#+ @returnType    om.DomNode
#+ @return        Node for the AUI root
#+
#+ @code
#+ define d_aui om.DomNode
#+ let d_aui = om_UInode()
#
############################################################################

public function om_UInode()

  call loc_Init()
  return md_aui

end function




############################################################################
#
#! om_WindowNode
#+ Returns window Node by name, default is the Node for the current window
#+
#+ @param p_name      Name of the window, NULL defaults to current window
#+
#+ @returnType        om.DomNode
#+ @return            DomNode if found, otherwise NULL
#+
#+ @code
#+ define d_win om.DomNode
#+ let d_win = om_WindowNode("")
#+ let d_win = om_WindowNode("customer")
#
############################################################################

public function om_WindowNode(p_name)

  define
    p_name    string,

    w_me      ui.Window,
    d_root    om.DomNode,
    d_doc     om.DomDocument


  if p_name.getLength()
  then
    ### Node for current window ###
    let w_me = ui.Window.getCurrent()
    return w_me.getNode()
  else
    ### Now hunt everywhere for matching form ###
    return om_NodeFind(NULL, "Window", "name", p_name)
  end if

end function





#
# PRIVATE
#


#############################################################################
#
#! loc_Init
#+ PRIVATE: Initialise private DOM tree objects for UI, call this to use
#+ md_doc or md_aui
#+
#+ @code
#+ call loc_Init()
#
#############################################################################

private function loc_Init()

  ### Set DOM tree objects for UI ###
  if md_doc is NULL
  then
    let md_doc = ui.Interface.getDocument()
    let md_aui = ui.Interface.getRootNode()
  end if

end function




