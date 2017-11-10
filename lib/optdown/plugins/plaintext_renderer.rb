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

# GFM compatible HTML renderer.
class Optdown::PlaintextRenderer < Optdown::Renderer
  # Visit a blocklevel.
  #
  # @param leafs [Array] leaf node visiting result.
  # @return      [Array] leaf result.
  def visit_blocklevel _, leafs
    return leafs
  end

  # Visit a thematic break.
  #
  # @return [String] the verbatim input.
  def visit_thematic_break hr;
    return hr.entity
  end

  # Visit a link definition.
  #
  # @return [String] an empty string.
  def visit_link_definition _, _
    return ''
  end

  # Visit a blockquote.
  #
  # @param inner [Array] leaf node visiting result.
  # @return      [Array] leaf result.
  def visit_blockquote _, inner
    return indent '> ', inner
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
    case li.type
    when :bullet then
      ret = indent '  ', inner
      ret.sub! '  ', '- '
      return ret
    when :ordered then
      mark = li.marker + ' '
      pad  = ' ' * mark.length
      ret  = indent pad, inner
      ret.sub! pad, mark
      return ret
    when :task then
      ret = indent '  ', inner
      if li.checked? then
        ret.sub! '  ', '- [x] '
      else
        ret.sub! '  ', '- [ ] '
      end
      return ret
    else
      rprintf RuntimeError, 'unsupported list type %s', list.type
    end
  end

  # Visit an HTML block.
  #
  # @param tag   [BlockHTML] block html node.
  # @return      [Array]     nothing to do.
  def visit_blockhtml tag
    return tag.html.to_s
  end

  # Visit a code block.
  #
  # @param pre   [IndentedCodeBlock, FencedCodeBlock] code block node.
  # @return      [Array]                              nothing to do.
  def visit_code_block pre
    return indent '    ', pre.pre.to_s
  end

  # Visit a heading.
  #
  # @param h     [ATXHeading, SetextHeading] heading node.
  # @param inner [Array]    leaf node visiting result.
  # @return      [Array]    leaf result.
  def visit_heading h, inner
    case h.level
    when 1 then
      return inner + "\n" + "=" * inner.length
    when 2 then
      return inner + "\n" + "-" * inner.length
    else
      return "#" * h.level + " " + inner + "\n"
    end
  end

  # Visit a table.
  #
  # @param table [Table] Table node.
  # @param thead [Array] first line leaf node visiting result.
  # @param tbody [Array] visiting results for 3rd line and beyond.
  # @return      [Array] leaf result.
  # def visit_table table, thead, tbody
  #   # sorry, not yet.
  #   # TBW
  # end

  # Visit a paragraph.
  #
  # @param paragraph [Paragraph]   paragraph node.
  # @param tightp    [true, false] paragraph tightness.
  # @param inner     [Object]      leaf node visiting result.
  # @return          [Object]      leaf result.
  def visit_paragraph paragraph, tightp, inner
    if tightp then
      return inner + "\n"
    else
      return inner + "\n\n"
    end
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
    return token.to_s
  end

  # Visit an escape.
  #
  # @param escape [Escape] terminal token.
  # @return       [Array]  nothing to do.
  def visit_escape escape
    return escape.entity
  end

  # Visit an entity.
  #
  # @param entity [Entity] terminal token.
  # @return       [Array]  nothing to do.
  def visit_entity entity
    return entity.entity
  end

  # Visit a code span.
  #
  # @param span [CodeSpan] terminal token.
  # @return     [Array]    nothing to do.
  def visit_code_span span
    return span
  end

  # Visit a raw html.
  #
  # @param tag [RawHTML] terminal token.
  # @return    [Array]   nothing to do.
  def visit_raw_html tag
    return tag.entity
  end

  # Visit an autolink.
  #
  # @param url [AutoLink] terminal token.
  # @return    [Array]    nothing to do.
  def visit_auto_link url
    return url.display
  end

  # Visit an image.
  #
  # @param img    [Link::Img] Img node.
  # @param label  [Array]     leaf node visiting result.
  # @param title  [Array]     leaf node visiting result.
  # @return       [Array]     leaf result.
  def visit_image img, label, title
    return label
  end

  # Visit a link.
  #
  # @param link   [Link::A] Link node.
  # @param label  [Array]   leaf node visiting result.
  # @param title  [Array]     leaf node visiting result.
  # @return       [Array]   leaf result.
  def visit_link link, label, title
    return label
  end

  # Visit an emphasis.
  #
  # @param emphasis [Emphasis] Emphasis node.
  # @param leafs  [Array]  leaf node visiting result.
  # @return       [Array]  leaf result.
  def visit_emphasis emphasis, leafs
    return leafs
  end

  # Visit a strikethrough.
  #
  # @param st     [Strikethrough] Strikethrough node.
  # @param leafs  [Array]  leaf node visiting result.
  # @return       [Array]  leaf result.
  def visit_strikethrough st, leafs
    return leafs
  end

  private

  def idnent pad, lines
    return lines.gsub %r/#{Optdown::EXPR}\g<BOL>/o, pad
  end
end
