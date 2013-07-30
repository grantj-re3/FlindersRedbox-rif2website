#--
# Copyright (c) 2013, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 

##############################################################################
# A class which has convenience methods for various html elements.
class HtmlHelper

  # Default list of html attributes to apply to an html element.
  # ATTR[HtmlElementNameSym][AttrNameSym] = Array of attr. values for this AttrName
  # Eg. Invoking self.open_element('body') with the following attributes:
  #   ATTR = {
  #     :body => {
  #       :class => ["myclass1", "myclass2"],
  #       :lang => ["en"],
  #     },
  #   }
  # will create the string '<body class="myclass1" class="myclass2" lang="en">'
  ATTR = {
    :tr => {
      :class => ["even"],
    },

    :td => {
      :class => ["rifFields"],
    },

    :th => {
      :class => ["rifFields highlightRifFields"],
      #:class => ["rifFields highlightOrgStructure"],
      :scope => ["col"],
    },
  }
  ATTR.default = {}  # Return an empty hash if ATTR[HtmlElementNameSym] not defined

  # Helper for <tr> element. Returns "<tr ATTR_LIST>...</tr>"
  # where ATTR_LIST is generated from a merger of ATTR[:tr] (if it exists)
  # and the attr argument.
  # * Argument _td_th_columns_: an array of strings; each string represents either
  #   a <td> element or a <th> element.
  # * Argument _child_td_: true if td_th_columns[] represents an array of <td>
  #   elements, or false otherwise (ie. an array of <th> elements).
  # * Argument _attr_: a hash of <tr> attributes to be merged with ATTR[:tr]
  # * Argument _wrap_in_: an array of html tags (as ruby symbols) which shall
  #   modify each item of text (within <td> or <th> elements) in this
  #   row  or these rows. Eg. wrap_in=[:strong, :em]
  def self.tr(td_th_columns, child_td=true, attr={}, wrap_in=[])
    tag = __method__
    attr_new = ATTR[:tr].merge(attr)
    tr_a = []
    tr_a << self.open_element(tag, attr_new)
    td_th_columns.each{|elem| tr_a << ( child_td ? self.td(elem, wrap_in) : self.th(elem, wrap_in) )}
    tr_a << self.close_element(tag) + "\n"
    tr_a.join
  end

  # Helper for <td> element. Returns "<td ATTR_LIST>...</td>"
  # where ATTR_LIST is generated from ATTR[:td] (if it exists).
  # * Argument _text_: the text to place within the <td> element.
  #   If text is an http or https URL it shall be wrapped in an <a> element
  #   so it behaves as a hyperlink.
  # * Argument _wrap_in_: an array of html tags (as ruby symbols) which shall
  #   modify the text. Eg. wrap_in=[:strong, :em]
  def self.td(text, wrap_in=[])
    tag = __method__
    if text.match('^(http|https)://\w')
      # Text is a URL. Convert it to a hyper-link.
      attr = ATTR[:a].merge( {:href => [text]} )
      str = self.open_element('a', attr) + self.wrap(text, wrap_in) + self.close_element('a')
    else
      str = self.wrap(text, wrap_in)
    end
    "#{self.open_element(tag)}#{str}#{self.close_element(tag)}"
  end

  # Helper for <th> element. Returns "<th ATTR_LIST>...</th>"
  # where ATTR_LIST is generated from ATTR[:th] (if it exists).
  # * Argument _text_: the text to place within the <th> element.
  # * Argument _wrap_in_: an array of html tags (as ruby symbols) which shall
  #   modify the text. Eg. wrap_in=[:strong, :em]
  def self.th(text, wrap_in=[])
    tag = __method__
    "#{self.open_element(tag)}#{self.wrap(text, wrap_in)}#{self.close_element(tag)}"
  end

  # Helper for arbitrary html elements. Returns "<ELEM ATTR_LIST>"
  # where ELEM is the value of the argument element_name and
  # where ATTR_LIST is generated from a merger of ATTR[:ELEM] (if it exists)
  # and the attr argument.
  # * Argument _element_name_: the html element name 
  #   Eg. For element_name='tr', this method will return '<tr ...>'
  # * Argument attr: a hash of <ELEM> attributes to be merged with ATTR[:ELEM]
  def self.open_element(element_name, attr=nil)
    attr ||= ATTR[element_name.to_sym]  # Default hash of html 'element_name' attributes
    attr_str = ''
    if attr
      attr.each{|name,values|
        if values
          values.each{|value|
            attr_str += " #{name}=\"#{value}\""
          }
        end
      }
    end
    "<#{element_name}#{attr_str}>"
  end

  # Helper for arbitrary html elements. Returns "</ELEM>"
  # where ELEM is the value of the argument element_name.
  # * Argument _element_name_: the html element name 
  #   Eg. For element_name='tr', this method will return '</tr>'
  def self.close_element(element_name)
    "</#{element_name}>"
  end

  # Wrap text in zero or more nested html tags as specified by
  # the symbols in the array wrap_in.
  # * Argument _text_: the text to place within the nested html tags.
  # * Argument _wrap_in_: an array of html tags (as ruby symbols) which shall
  #   modify the text. Eg. wrap_in=[:strong, :em]
  # Eg. For text = "my text"; wrap_in=[:strong, :em] this
  # method will return
  #   '<strong><em>my text</em></strong>'
  def self.wrap(text, wrap_in)
    pre = ''
    post = ''
    wrap_in.each{|e|
      pre += "<#{e}>"
      post = "</#{e}>" + post	# Close html tags in reverse order
    }
    "#{pre}#{text}#{post}"
  end

end  # class HtmlHelper

