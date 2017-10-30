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

# DOM top level. It seems the only thing that the spec says about such thing is
# the following:
#
# > # Blocks and inlines
# >
# > We can think of a document as a sequence of blocks -- (snip).
#
# @see http://spec.commonmark.org/0.28/#blocks-and-inlines
class Optdown::Blocklevel
  using Optdown::Matcher::Refinements

  attr_reader :children # @return [Array] description TBW.

  # Utility constructor to join the lines before calling new.
  # @param lines [Array<Matcher>] target lines to join.
  # @param ctx   [Parser]         parser context.
  def self.from_lines lines, ctx
    str = Optdown::Matcher.join lines
    return new str, ctx
  end

  # Parse the argument to construct AST.
  #
  # @note In contrast to inline elements  who need clear separation of tokenize
  #       and parse, blocklevel elements can be parsed in sequence.
  # @param str [Matcher] target to scan.
  # @param ctx [Parser]  parser context.
  def initialize str, ctx
    @children   = []
    @blank_seen = false
    re          = Optdown::EXPR # easy typing.
    until str.eos? do
      case str # ORDER MATTERS HERE
      when /#{re} \G \g<LINE:blank>+  /xo then k = nil
      when /#{re} \G \g<hr>           /xo then k = Optdown::ThematicBreak
      when /#{re} \G \g<link:def>     /xo then k = Optdown::LinkDef
      when /#{re} \G \g<blockquote>   /xo then k = Optdown::Blockquote
      when /#{re} \G \g<li>           /xo then k = Optdown::List
      when /#{re} \G \g<tag:block>    /xo then k = Optdown::BlockHTML
      when /#{re} \G \g<pre:fenced>   /xo then k = Optdown::FencedCodeBlock
      when /#{re} \G \g<pre:indented> /xo then k = Optdown::IndentedCodeBlock
      when /#{re} \G \g<atx>          /xo then k = Optdown::ATXHeading
      when /#{re} \G (?= \g<sh>    )  /xo then k = Optdown::SetextHeading
      when /#{re} \G (?= \g<table> )  /xo then k = Optdown::Table
      else                                     k = Optdown::Paragraph
      end

      if k then
        node = k.new str, ctx
        @children << node
      else
        @blank_seen = !@children.empty? && !str.eos?
      end
    end
  end

  # Makes sense when this blocklevel is inside of a list item.
  #
  # @return [true]  it is.
  # @return [false] it isn't.
  def tight?
    return ! @blank_seen
  end

  # Traverse the tree
  #
  # @param visitor [Renderer]   rendering visitor.
  # @param tightp  [true,false] tightness.
  # @return        [Object]     visitor visiting result.
  def accept visitor, tightp: false
    inner = @children.map {|i| visitor.visit i, tightp: tightp }
    return visitor.visit_blocklevel self, inner
  end
end
