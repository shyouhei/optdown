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

require_relative 'expr'
require_relative 'matcher'

# @see http://spec.commonmark.org/0.28/#list-items
class Optdown::ListItem
  using Optdown::Matcher::Refinements

  attr_reader :type   # @return [:bullet, :ordered] type of it.
  attr_reader :marker # @return [String] leading list marker.
  attr_reader :order  # @return [String] item order, if any.

  private

  def re # easy typing
    Optdown::EXPR
  end

  def calc_width md
    str = md['li2'] rescue md['li']
    if md['li:normal']  then return str.length
    elsif md['li:pre']  then return str.length
    elsif md['li:eol']  then return str.length + 1
    elsif md['li:task'] then
      # `-    [ ] foo`
      #  ^^^^^^^^ : str
      #  ^^^^^    : what we need this case
      return str.length - 3
    end
  end

  def handle_types width, md
    # > When both a thematic break and a list item are possible interpretations
    # > of a line, the thematic break takes precedence
    # @see http://spec.commonmark.org/0.28/#thematic-breaks
    #
    # > If there is any ambiguity between an interpretation of indentation as a
    # > code block and as indicating that  material belongs to a list item, the
    # > list item interpretation takes precedence
    # @see https://github.github.com/gfm/#indented-code-blocks
    filler       = /#{re}\G\g<LINE:blank>*\g<SP>*(?!\g<hr>)/o
    if b         = md['li:bullet'] then
      @type      = md['li:task'] ? :task : :bullet
      @checked   = /x/i =~ md['li:task'] if @type == :task
      @marker    = b
      e          = Regexp.escape b
      @same_type = /(?=#{filler}#{e}\g<li:train>)/
    else
      @type      = :ordered
      @marker    = md['li:mark']
      @order     = md['li:num']
      e          = Regexp.escape @marker
      @same_type = /(?=#{filler}\g<li:num>#{e}\g<li:train>)/
    end
  end

  def eat_following_lines width, md, str
    re     = /#{Optdown::EXPR}\G/o
    indent = /#{re}\g<SP>{#{width}}(?!\g<LINE:blank>)/
    lazy   = /#{re}(?=\g<SP>{,#{width-1}}(?!\g<SP>|\g<EOL>))/
    cutter = /#{re}(?=\g<SP>{,#{width-1}}\g<p:cutter>)/
    dedent = /#{re}(?=\g<LINE:blank>*\g<SP>{,#{width-1}}(?!\g<SP>|\g<EOL>))/

    if md['li:eol'] and str.match?(%r/#{re}\G\g<LINE:blank>{2,}/o) then
      # > A list item can begin with at most one blank line.
      # @see http://spec.commonmark.org/0.28/#list-items
      return []
    else
      lines  = [ str.gets ]
    end

    until str.eos? do
      case str
      # An empty  list item cannot  interrupt a  paragraph while an  empty list
      # item can follow  a paragraph and a paragraph can  be lazy.  There seems
      # to be a  conflict in the spec's  language.  I'd like to  follow the two
      # examples.  They are thought to represent intentions.
      #
      # @see http://spec.commonmark.org/0.28/#example-248
      # @see http://spec.commonmark.org/0.28/#example-276
      when indent then
        lines << str.gets
      when lazy then
        break if str.match? @same_type
        break if str.match? %r/#{re}\G\g<li>/o # ...?
        break if str.match? cutter
        lines << Optdown::Paragraph::PAD
        lines << str.gets
      when dedent then
        break
      else
        lines << str.gets
      end
    end
    return lines
  end

  # (see Optdown::Blocklevel#initialize)
  def initialize str, ctx
    @blank_seen = false
    @children   = nil
    md          = str.last_match
    md          = str.match %r/#{re}\G(?<li2>\g<SP>*\g<li>)/o unless md['li']
    width       = calc_width md

    handle_types width, md
    return if str.eos?

    lines = eat_following_lines width, md, str

    @children = Optdown::Blocklevel.from_lines lines, ctx
  end

  public

  # (see Optdown::List#tight?)
  def tight?
    return @children.tight?
  end

  # Only a list item of the same tipe can follow this.
  #
  # @return [Regexp] pattern that allows the same type.
  def same_type_expr
    return @same_type
  end

  # @return [true, false] if the task is checked (makes sense for task item).
  def checked?
    (defined? @checked) and @checked
  end

  # (see Optdown::Blocklevel#accept)
  def accept visitor, tightp: false
    inner = visitor.visit @children, tightp: tightp
    return visitor.visit_list_item self, inner
  end
end
