############################################################################
#
# OM. Index
#
# PUBLIC
#! Element_AttribGet
#! Element_AttribSet
#! Element_Create
#! Element_Delete
#! Form_Node
#! Node_AttribGet
#! Node_AttribSet
#! Node_Find
#! Node_Select
#! Node_ListSelect
#! UI_Node
#! Window_Node
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
#! Dom.Element_AttribGet
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
#+ let p_value = Dom.Element_AttribGet(100, "color")
#
#############################################################################

public function Element_AttributeGet(p_elementID, p_attrib)

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
#! Dom.Element_AttribSet
#+ Set attribute of an DomDoc element
#+
#+ @param p_elementID     Element ID of DomNode
#+ @param p_attrib        Attribute of node
#+ @param p_value         Value to set attribute to
#+
#+ @code
#+ call Dom.Element_AttribSet(100, "color", "red")
#
#############################################################################

public function Element_AttribSet(p_elementID, p_attrib, p_value)

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
#! Dom.Element_Create
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
#+ let p_nodeId = Dom.Element_Create(100, "StartMenuGroup")
#
#############################################################################

public function Element_Create(p_parentID, p_tagName)

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
#! Dom.Element_Delete
#+ Deletes a DomDoc element and its children
#+
#+ @param p_parentID    Element ID of parent DomNode
#+
#+ @code
#+ call Dom.Element_Delete(100)
#
#############################################################################

public function Element_Delete(p_parentID)

  define
    p_parentID  integer,

    d_parent    om.DomNode


  call loc_Init()

  let d_parent = md_doc.getElementByID(p_parentID)
  call md_doc.removeElement(d_parent)

end function




############################################################################
#
#! Dom.Form_Node
#+ Return the node for a form, defaults to current form
#+
#+ @param p_name  Name of the form, NULL defaults to current form
#+
#+ @returnType    om.DomNode
#+ @return        DomNode if found, otherwise NULL
#+
#+ @code
#+ define d_form om.DomNode
#+ let d_form = Dom.Form_Node("customerForm")
#
############################################################################

public function Form_Node(p_name)

  define
    p_name    string,

    d_parent  om.DomNode,
    d_child   om.DomNode


  if p_name is NULL
  then
    ### Look for current window ###
    let d_parent = Window_Node(NULL)
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
    return Node_Find(NULL, "Form", "name", p_name)
  end if

  return NULL

end function




#############################################################################
#
#! Dom.Node_AttribGet
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
#+ let d_root = Dom.Window_Node("w_customer")
#+ let p_hidden = Dom.Node_AttribGet(d_root, "//FormField[@name='id']", "hidden")
#+ let p_file = Dom.Node_AttribGet(NULL, "/UserInterface/StyleList", "fileName")
#
#############################################################################

public function Node_AttribGet(d_parent, p_xpath, p_attrib)

  define
    d_parent    om.DomNode,
    p_xpath     string,
    p_attrib    string,

    d_list      om.NodeList,
    d_node      om.DomNode,
    p_idx       integer


  ### Node for first item returned by XPath query ###
  let d_node = Node_Select(d_parent, p_xpath)
  if d_node is not NULL
  then
    return d_node.getAttribute(p_attrib)
  end if

  return ""

end function




#############################################################################
#
#! Dom.Node_AttribSet
#+ Set attribute of nodes that match XPath query
#+
#+ @param d_parent    DomNode of parent to search from,
#+                    NULL defaults to root node of UI
#+ @param p_xpath     XPath to node
#+ @param p_attrib    Style attribute
#+ @param p_value     Value to set attribute to
#+
#+ @code
#+ call Dom.Node_AttribSet(d_parent, p_xpath, p_attrib, p_value)
#
#############################################################################

public function Node_AttribSet(d_parent, p_xpath, p_attrib, p_value)

  define
    d_parent    om.DomNode,
    p_xpath     string,
    p_attrib    string,
    p_value     string,

    d_list      om.NodeList,
    d_node      om.DomNode,
    p_idx       integer


  ### Node list for XPath query ###
  let d_list = NodeList_Select(d_parent, p_xpath)

  ### Set all matching attributes ###
  for p_idx = 1 to d_list.getLength()
    let d_node = d_list.item(p_idx)
    call d_node.setAttribute(p_attrib, p_value)
  end for

end function




############################################################################
#
#! Dom.Node_Find
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
#+ let d_node = Dom.Node_Find(d_aui, "Form", "name", "custForm")
#
# Limitations:
#   Only find first matching node, hopefully that should be unique enough
#   Recursive, probably more efficient to use Xpath with Dom.Node_Select()
#
############################################################################

public function Node_Find(d_parent, p_tag, p_attrib, p_value)

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

    let d_child = Node_Find(d_parent, p_tag, p_attrib, p_value)
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
#! Dom.Node_Select
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
#+ let d_win = Dom.Window_Node("")
#+ let d_menu = Dom.NodeList_Find(d_win, "//Form/TopMenu")
#+ let d_menu = Dom.NodeList_Find(NULL, "//Window/Menu")
#
#############################################################################

public function Node_Select(d_root, p_path)

  define
    d_root      om.DomNode,
    p_path      string,

    d_list      om.NodeList


  ### Get list of matching nodes ###
  let d_list = NodeList_Select(d_root, p_path)

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
#! Dom.NodeList_Select
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
#+ let d_win = Dom.Window_Node(NULL)
#+ let d_list = Dom.NodeList_Find(d_win, "//MenuAction")
#+ let d_list = Dom.NodeList_Find(NULL, "//Style")
#
#############################################################################

public function NodeList_Select(d_root, p_path)

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
#! Dom.UI_Node
#+ Returns the AUI (Abstract User Interface) root Node
#+
#+ @returnType    om.DomNode
#+ @return        Node for the AUI root
#+
#+ @code
#+ define d_aui om.DomNode
#+ let d_aui = Dom.UI_Node()
#
############################################################################

public function UI_Node()

  call loc_Init()
  return md_aui

end function




############################################################################
#
#! Dom.Window_Node
#+ Returns window Node by name, default is the Node for the current window
#+
#+ @param p_name      Name of the window, NULL defaults to current window
#+
#+ @returnType        om.DomNode
#+ @return            DomNode if found, otherwise NULL
#+
#+ @code
#+ define d_win om.DomNode
#+ let d_win = Dom.Window_Node("")
#+ let d_win = Dom.Window_Node("customer")
#
############################################################################

public function Window_Node(p_name)

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
    return Node_Find(NULL, "Window", "name", p_name)
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




