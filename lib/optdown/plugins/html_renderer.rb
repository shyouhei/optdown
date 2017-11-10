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

require_relative '../expr'
require_relative '../renderer'
require_relative '../link_title'
require_relative 'plaintext_renderer'
require_relative 'houdini_compat'

# GFM compatible HTML renderer.
class Optdown::HTMLRenderer < Optdown::Renderer
  include Optdown::HoudiniCompat

  Newline = Object.new
  private_constant :Newline

  # Render HTML
  #
  # @param node [Object] AST node.
  # @return     [String] node, in HTML.
  def render node
    return tagfilter visit(node)                \
      . flatten                                 \
      . lazy                                    \
      . chunk {|i| i == Newline }               \
      . map   {|_, b| b         }               \
      . map   {|b| b[0] == Newline ? "\n" : b } \
      . force                                   \
      . join                                    \
      . sub %r/\A\n+/, ''
  end

  private

  # Tag filter extension not enabled right now.
  # See https://github.github.com/gfm/ and search  for instance `<script`. Many
  # lines hit.  It seems the extension is a joke.
  def tagfilter str
    return str # .gsub %r/<(
    #   title | textarea | style | xmp | iframe | noembed | noframes |
    #   script | plaintext
    # )/xi do
    #   next "&lt;#$1"
    # end
  end

  public

  # Visit a blocklevel.
  #
  # @param leafs [Array] leaf node visiting result.
  # @return      [Array] leaf result.
  def visit_blocklevel _, leafs
    return leafs
  end

  # Visit a thematic break.
  #
  # @return [String] the "<hr/>" string.
  def visit_thematic_break *;
    return [ Newline, '<hr />', Newline ]
  end

  # Visit a link definition.
  #
  # @return [String] an empty string.
  def visit_link_definition _, _
    return Newline # or...?
  end

  # Visit a blockquote.
  #
  # @param inner [Array] leaf node visiting result.
  # @return      [Array] rendered blockquote.
  def visit_blockquote _, inner
    return [ Newline, '<blockquote>', Newline, inner, '</blockquote>', Newline]
  end

  # Visit a list.
  #
  # @param list  [List]  list node.
  # @param items [Array] leaf node visiting result.
  # @return      [Array] rendered list.
  def visit_list list, items
    case list.type
    when :bullet, :task then
      return [ Newline, '<ul>', Newline, items, '</ul>', Newline ]
    when :ordered then 
      start = list.start
      if start == '1' then
        return [ Newline, '<ol>', Newline, items, '</ol>', Newline ]
      else
        return [ Newline, '<ol start="', start, '">', Newline,
                 items, '</ol>', Newline ]
      end
    else
      rprintf RuntimeError, 'unsupported list type %s', list.type
    end
  end

  # Visit a list item.
  #
  # @param li    [ListItem] list item node.
  # @param inner [Array]    leaf node visiting result.
  # @return      [Array]    rendered list item.
  def visit_list_item li, inner
    ret = [ '<li>' ]

    if li.type == :task then
      if li.checked? then
        ret << '<input checked="" disabled="" type="checkbox"> '
      else
        ret << '<input disabled="" type="checkbox"> '
      end
    end
    ret << [ inner, '</li>', Newline ]
    return ret
  end

  # Visit an HTML block.
  #
  # @param tag   [BlockHTML] block html node.
  # @return      [String]    verbatim input.
  def visit_blockhtml tag
    return [ Newline, tag.html.to_s.chomp, Newline ]
  end

  # Visit a code block.
  #
  # @param pre   [IndentedCodeBlock, FencedCodeBlock] code block node.
  # @return      [Array]                              rendered code.
  def visit_code_block pre
    if i = pre.info then
      md = i.match %r/#{Optdown::EXPR}(?<lang>\g<^WS>+)/o
      lang0 = i[md, 'lang']
      lang1 = Optdown::LinkTitle.new lang0
      lang2 = visit lang1
      tag = ['<pre><code class="language-', lang2, '">']
    else
      tag = '<pre><code>'
    end
    esc = escape_tag pre.pre
    return [ Newline, tag, esc, '</code></pre>', Newline ]
  end

  # Visit a heading.
  #
  # @param h     [ATXHeading, SetextHeading] heading node.
  # @param inner [Array]                     leaf node visiting result.
  # @return      [Array]                     rendered heading.
  def visit_heading h, inner
    return [ Newline, '<h', h.level, '>',
             inner, '</h', h.level, '>', Newline ]
  end

  # Visit a table.
  #
  # @param table [Table] Table node.
  # @param thead [Array] first line leaf node visiting result.
  # @param tbody [Array] visiting results for 3rd line and beyond.
  # @return      [Array] rendered table.
  def visit_table table, thead, tbody
    al = table.alignments
    ha = visit_table_internal al, [ thead ], 'th'
    ba = visit_table_internal al, tbody, 'td'
    ret = [
      '<table>', Newline,
      '<thead>', Newline,
      ha, Newline,
      '</thead>'
    ]
    unless tbody.empty? then
      ret << [ Newline, '<tbody>', Newline, ba, '</tbody>' ]
    end
    ret << [ '</table>', Newline ]
    return ret
  end

  # Visit a paragraph.
  #
  # @param paragraph [Paragraph]   paragraph node.
  # @param tightp    [true, false] paragraph tightness.
  # @param inner     [Object]      leaf node visiting result.
  # @return          [Object]      rendered paragraph.
  def visit_paragraph paragraph, tightp, inner
    if tightp then
      return inner
    else
      return [ Newline, '<p>', inner, '</p>', Newline ]
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
  # @param token [Token]  terminal token.
  # @return      [String] verbatim input.
  def visit_token token
    return escape_tag token.yytext
  end

  # Visit a newline.
  #
  # @param br [Newline] terminal token.
  # @return   [String]  newline, or a "<br/>"
  def visit_newline br
    case br.type when :hard then
      return '<br />', Newline
    else
      return Newline
    end
  end

  # Visit an escape.
  #
  # @param escape [Escape] terminal token.
  # @return       [String] unescaped entity.
  def visit_escape escape
    # for instance `\<` shall render `&lt;`
    return escape_tag escape.entity
  end

  # Visit an entity.
  #
  # @param entity [Entity] terminal token.
  # @return       [String] the entity as-is. 
  def visit_entity entity
    # for instance `&#x22;` shall render `&quot;`
    return escape_tag entity.entity
  end

  # Visit a code span.
  #
  # @param span [CodeSpan] terminal token.
  # @return     [Array]    rendered code.
  def visit_code_span span
    ent = escape_tag span.entity
    return [ '<code>', ent, '</code>']
  end

  # Visit a raw html.
  #
  # @param tag [RawHTML] terminal token.
  # @return    [String]  verbatim input.
  def visit_raw_html tag
    return tag.entity
  end

  # Visit an autolink.
  #
  # @param url [AutoLink] terminal token.
  # @return    [Array]    rendered link.
  def visit_auto_link url
    href = escape_href url.href
    disp = escape_tag  url.display
    return [ '<a href="', href, '">', disp, '</a>']
  end

  # Visit an image.
  #
  # @param img    [Link::Img] Img node.
  # @param label  [Array]     leaf node visiting result.
  # @param title  [Array]     leaf node visiting result.
  # @return       [Array]     rendered image.
  def visit_image img, label, title
    # `label` and `title` not used due to its HTML tags
    dest = escape_href img.attr[:dest]
    ret  = [ '<img src="', dest, '"' ]
    if label then
      # > in rendering  to HTML,  only the  plain string  content of  the image
      # > description be used.
      #
      # So the HTML-rendered `label` variable cannot be used herein.
      plain   = Optdown::PlaintextRenderer.new.render img.attr[:label]
      escaped = escape_tag plain
      ret << [ ' alt="', escaped, '"' ]
    end
    ret << [ ' title="', title, '"' ] if title
    ret << ' />'
    return ret
  end

  # Visit a link.
  #
  # @param link   [Link::A] Link node.
  # @param label  [Array]   leaf node visiting result.
  # @param title  [Array]   leaf node visiting result.
  # @return       [Array]   rendered link.
  def visit_link link, label, title
    dest = escape_href link.attr[:dest]
    ret  = [ '<a href="', dest, '"' ]
    ret << [ ' title="', title, '"' ] if title
    ret << [ '>', label, '</a>' ]
    return ret
  end

  # Visit a link title.
  #
  # @param title    [LinkTitle] Link title node.
  # @param children [Array]     leaf node visiting result.
  # @return         [Array]     rendered title.
  def visit_link_title title, children
    return children
  end

  # Visit an emphasis.
  #
  # @param emphasis [Emphasis] Emphasis node.
  # @param leafs    [Array]    leaf node visiting result.
  # @return         [Array]    rendered emphasis.
  def visit_emphasis emphasis, leafs
    # According to  the rule #14  of the  spec, `***` is  `<em><strong>` rather
    # than `<em><em><em>`.
    ret = leafs
    lv = emphasis.level
    while lv > 1 do
      ret = [ '<strong>', ret, '</strong>' ]
      lv -= 2
    end
    if lv.odd?
      ret = [ '<em>', ret, '</em>' ]
    end
    return ret
  end

  # Visit a strikethrough.
  #
  # @param st     [Strikethrough] Strikethrough node.
  # @param leafs  [Array]         leaf node visiting result.
  # @return       [Array]         rendered strikethrough.
  def visit_strikethrough st, leafs
    return ['<del>', leafs, '</del>']
  end

  private

  def visit_table_internal x, y, t
    flag = false
    ret  = []
    y.each do |tr|
      if flag then
        ret << Newline
      else
        flag = true
      end
      z = tr.map.with_index do |td, i|
        case x[i] when NilClass then
          tag = ['<', t, '>']
        else
          tag = [ '<', t, ' align="', x[i], '">' ]
        end
        next [ tag, td, '</', t, '>', Newline ]
      end
      ret << [ '<tr>', Newline, z, '</tr>' ]
    end
    return ret
  end
end
