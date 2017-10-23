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
require_relative 'xprintf'
require_relative 'token'

# Parses inline elements
class Optdown::Inline
  using Optdown::XPrintf

  attr_reader :children # @return [Array] description TBW.

  # Inline elements cannot  be parsed linearly because of  link resoltuion.  We
  # need to  first tokenize  the input as  a series of  tokens, then  after all
  # inlines are tokenized, start understanding them as trees.
  #
  # @see http://spec.commonmark.org/0.28/#example-540
  # @see http://spec.commonmark.org/0.28/#example-541
  # @see http://spec.commonmark.org/0.28/#example-542
  # @param str [Matcher]      target to scan.
  # @return    [Array<Token>] str split into tokens.
  def self.tokenize str
    a = []
    until str.eos? do
      b4, md = str.advance %r/
        #{Optdown::EXPR} # ORDER MATTERS HERE
        \g<escape+> | \g<entity> | \g<code> | \g<auto> | \g<auto:GH> |
        \g<tag> | \g<br> | \g<link> | \g<flanker:and> | \g<flanker:or> |
        \g<table:delim>
      /xo

      if b4 and not b4.empty? then
        tok = Optdown::Token.new :cdata, b4
        a << tok
      end

      next unless md
      text = md[0].dup
      # :FIXME: We  need a  more appropriate  place than  here to  exercise the
      # "extended autolink path validation" maneuver.
      #
      # @see https://github.github.com/gfm/#extended-autolink-path-validation
      if md['auto:GH:path']                      and
        /\)\z/ =~ text                           then
        while text.count('(') != text.count(')') and
              text.chomp!(')')                   do
          str.ungetc
        end
      end
      tok = Optdown::Token.new nil, md, text
      a << tok
    end
    return a
  end

  # Understand the tokenized series.
  def parse
    @children.map! do |t|
      next t unless Optdown::Token === t
      case t.yylex
      when :'break'    then next Optdown::Newline.new t
      when :'escape'   then next Optdown::Escape.new t
      when :'entity'   then next Optdown::Entity.new t
      when :'code'     then next Optdown::CodeSpan.new t
      when :'tag'      then next Optdown::RawHTML.new t
      when :'autolink' then next Optdown::Autolink.new t
      else                  next t
      end
    end
    # This order of flanker reduction is very important.
    #
    # > - The brackets in link text bind more tightly than markers for emphasis
    # >   and strong emphasis.
    #
    # @see http://spec.commonmark.org/0.28/#links
    Optdown::Link.parse @children, @parser
    Optdown::Flanker.parse @children, @parser
    @children.compact!
  end

  # Inline elements  tends to be consist  of multiple lines.  Instead  of parse
  # them evey lines we would like to first merge them, then parse.
  #
  # @param lines [Array]  lines of inlines
  # @param ctx   [Parser] parsing context.
  # @return      [Inline] generated node.
  def self.from_lines lines, ctx
    str = Optdown::Matcher.join lines
    ary = tokenize str
    return new ary, ctx
  end

  # Also, there  are cases when  inline elements are  whitespace-stripped. This
  # utility handle such situations.
  #
  # @param line  [Matcher] a line of inlines
  # @param ctx   [Parser]  parsing context.
  # @return      [Inline]  generated node.
  def self.from_stripped line, ctx
    str = Optdown::Matcher.new line.to_s.strip
    ary = tokenize str
    return new ary, ctx
  end

  def initialize ary, ctx
    @children = ary
    @parser   = ctx
    @parser.define_inline self
  end
end
