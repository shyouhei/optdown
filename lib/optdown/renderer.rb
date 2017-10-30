#! /your/favourite/path/to/ruby
# -*- mode: ruby; coding: utf-8; indent-tabs-mode: nil; ruby-indent-level: 2 -*-
# -*- frozen_string_literal: true -*-
# -*- warn_indent: true -*-

# Copyright (c) 2017 Urabe, Shyouhei
#
# Permission is hereby granted, free of  charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction,  including without limitation the rights
# to use,  copy, modify,  merge, publish,  distribute, sublicense,  and/or sell
# copies  of the  Software,  and to  permit  persons to  whom  the Software  is
# furnished to do so, subject to the following conditions:
#
#         The above copyright notice and this permission notice shall be
#         included in all copies or substantial portions of the Software.
#
# THE SOFTWARE  IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY  KIND, EXPRESS OR
# IMPLIED,  INCLUDING BUT  NOT LIMITED  TO THE  WARRANTIES OF  MERCHANTABILITY,
# FITNESS FOR A  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO  EVENT SHALL THE
# AUTHORS  OR COPYRIGHT  HOLDERS  BE LIABLE  FOR ANY  CLAIM,  DAMAGES OR  OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Renderer.
#
# This class is  not only the base  class of each custom renderers,  but also a
# null  renderer.  When  a  node is  passed  to  it an  empty  string would  be
# rendered.  Child classes shall override each visit_* methods.
class Optdown::Renderer

  # Render the  node.  In  this particular  class, it  returns an  empty string
  # after traversing the AST.
  #
  # @param node [Object] AST node.
  # @return     [Object] node's acceptance.
  def render node
    ary = visit node
    return [ ary ].join
  end

  # Visit a node.
  #
  # @param node [Object] AST node.
  # @return     [Object] node's acceptance.
  def visit node, **args
    node.accept self, **args
  end

  # @!group Methods that are expected to be overridden by child classes

  # Visit a blocklevel.
  #
  # @param block [Blocklevel] blocklevel node.
  # @param leafs [Array]      leaf node visiting result.
  # @return      [Array]      leaf result.
  def visit_blocklevel block, leafs
    return leafs
  end

  # Visit a thematic break.
  #
  # @param hr [ThematicBreak] thematic break node.
  # @return   [Array]         nothing to do.
  def visit_thematic_break hr
    return []
  end

  # Visit a link definition.
  #
  # @param ld    [LinkDef] link def node.
  # @param title [Array]   leaf node visiting result.
  # @return      [Array]   leaf result.
  def visit_link_definition ld, title
    return title
  end

  # Visit a blockquote.
  #
  # @param bq    [BlockQuote] blockquote node.
  # @param inner [Array]      leaf node visiting result.
  # @return      [Array]      leaf result.
  def visit_blockquote bq, inner
    return inner
  end

  # Visit a list.
  #
  # @param list  [List]  list node.
  # @param items [Array] leaf node visiting result.
  # @return      [Array] leaf result.
  def visit_list list, items
    return items
  end

  # Visit a list item.
  #
  # @param li    [ListItem] list item node.
  # @param inner [Array]    leaf node visiting result.
  # @return      [Array]    leaf result.
  def visit_list_item li, inner
    return inner
  end

  # Visit an HTML block.
  #
  # @param tag   [BlockHTML] block html node.
  # @return      [Array]     nothing to do.
  def visit_blockhtml tag
    return []
  end

  # Visit a code block.
  #
  # @param pre   [IndentedCodeBlock, FencedCodeBlock] code block node.
  # @return      [Array]                              nothing to do.
  def visit_code_block pre
    return []
  end

  # Visit a heading.
  #
  # @param h     [ATXHeading, SetextHeading] heading node.
  # @param inner [Array]                     leaf node visiting result.
  # @return      [Array]                     leaf result.
  def visit_heading h, inner
    return inner
  end

  # Visit a table.
  #
  # @param table [Table] Table node.
  # @param thead [Array] first line leaf node visiting result.
  # @param tbody [Array] visiting results for 3rd line and beyond.
  # @return      [Array] leaf result.
  def visit_table table, thead, tbody
    return thead && tbody
  end

  # Visit a paragraph.
  #
  # @param paragraph [Paragraph]   paragraph node.
  # @param tightp    [true, false] paragraph tightness.
  # @param inner     [Object]      leaf node visiting result.
  # @return          [Object]      leaf result.
  def visit_paragraph paragraph, tightp, inner
    return inner
  end

  # Visit an inline.
  #
  # @param inline [Inline] inline node.
  # @param leafs  [Array]  leaf node visiting result.
  # @return       [Array]  leaf result.
  def visit_inline inline, leafs
    return leafs
  end

  # Visit a token.
  #
  # @param token [Token] terminal token.
  # @return      [Array] nothing to do.
  def visit_token token
    return []
  end

  # Visit a newline.
  #
  # @param br [Newline] terminal token.
  # @return   [Array]   nothing to do.
  def visit_newline br
    return []
  end

  # Visit an escape.
  #
  # @param escape [Escape] terminal token.
  # @return       [Array]  nothing to do.
  def visit_escape escape
    return []
  end

  # Visit an entity.
  #
  # @param entity [Entity] terminal token.
  # @return       [Array]  nothing to do.
  def visit_entity entity
    return []
  end

  # Visit a code span.
  #
  # @param span [CodeSpan] terminal token.
  # @return     [Array]    nothing to do.
  def visit_code_span span
    return []
  end

  # Visit a raw html.
  #
  # @param tag [RawHTML] terminal token.
  # @return    [Array]   nothing to do.
  def visit_raw_html tag
    return []
  end

  # Visit an autolink.
  #
  # @param url [AutoLink] terminal token.
  # @return    [Array]    nothing to do.
  def visit_auto_link url
    return []
  end

  # Visit an image.
  #
  # @param img    [Img]   Img node.
  # @param label  [Array] leaf node visiting result.
  # @param title  [Array] leaf node visiting result.
  # @return       [Array] leaf result.
  def visit_image img, label, title
    return label
  end

  # Visit a link.
  #
  # @param link   [Link]  Link node.
  # @param label  [Array] leaf node visiting result.
  # @param title  [Array] leaf node visiting result.
  # @return       [Array] leaf result.
  def visit_link link, label, title
    return label
  end

  # Visit a link title.
  #
  # @param title    [LinkTitle] Link title node.
  # @param children [Array]     leaf node visiting result.
  # @return         [Array]     leaf result.
  def visit_link_title title, children
    return children
  end

  # Visit an emphasis.
  #
  # @param emphasis [Emphasis] Emphasis node.
  # @param leafs    [Array]    leaf node visiting result.
  # @return         [Array]    leaf result.
  def visit_emphasis emphasis, leafs
    return leafs
  end

  # Visit a strikethrough.
  #
  # @param st     [Strikethrough] Strikethrough node.
  # @param leafs  [Array]         leaf node visiting result.
  # @return       [Array]         leaf result.
  def visit_strikethrough st, leafs
    return leafs
  end

  # @!endgroup
end
