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
require_relative 'inline'

# @see https://github.github.com/gfm/#tables-extension-
class Optdown::Table
  using Optdown::Matcher::Refinements

  # Table  cells can  include pipes  by escaping.   Should be  tokenized before
  # splitting cells.
  #
  # @param line [Matcher]             table row.
  # @return     [Array<Array<Token>>] tokenized table cells.
  def self.split line
    return Optdown::Inline                               \
      . tokenize(line)                                   \
      . chunk {|t| t.yylex == :'table' and :_separator } \
      . map   {|_, i| i }                                \
      . to_a                                             \
  end

  # Header and  delimiter rows must  match in the  number of cells.   We cannot
  # check that criteria using regular expression (can we?). We cannot but check
  # here  by hand-written  logic  instead.  All  illegal  table-ish inputs  are
  # considered to be paragraphs.
  #
  # @param  (see Optdown::Blocklevel#initialize)
  # @return [Talbe]     peaceful creation of an instance.
  # @return [Paragraph] unmatched delimiter row.
  def self.new str, ctx
    tmp = str.dup
    tmp.match %r/#{Optdown::EXPR}\G\g<table>/o
    th  = split tmp['table:th']
    dr  = split tmp['table:dr']
    if th.length == dr.length then
      return super # ok
    else
      return Optdown::Paragraph.new str, ctx
    end
  end

  # (see Optdown::Blocklevel#initialize)
  def initialize str, ctx
    # at least 2 lines must be readable at this point.
    th  = str.match %r/#{Optdown::EXPR}
                       \G\g<table:open>\g<table:th>\g<table:close>/xo
    dr  = str.match %r/#{Optdown::EXPR}
                       \G\g<table:open>\g<table:dr>\g<table:close>/xo
    @th = self.class.split str[th, 'table:th']
    @th.map! {|i| Optdown::Inline.new i, ctx }
    str[dr, 'table:dr'].split('|').each_with_index do |i, j|
      @th[j] = [
        @th[j],
        case i
        when /\A\s*:-+:\s*\z/ then :center
        when /\A\s*:-+\s*\z/  then :left
        when /\A\s*-+:\s*\z/  then :right
        else                       nil
        end
      ]
    end

    # OK then, read until non-table.
    @td = []
    until str.eos? do
      case str
      when /#{Optdown::EXPR}\G\g<p:cutter>/o then break
      when /#{Optdown::EXPR}\G\g<table:open>\g<table:tr>\g<table:close>/o then
        tr = self.class.split str['table:tr']
        row = []
        @th.size.times {|i| row << Optdown::Inline.new(tr[i] || [], ctx) }
        @td << row
      end
    end
  end

  # Extracted list of align specifiers, for each columns.
  #
  # @return [Array<nil, :center, :left, :right>] align specifiers.
  def alignments
    return @th.map{|a| a[1] }
  end

  # (see Optdown::Blocklevel#accept)
  def accept visitor, tightp: false
    thead = @th.map {|i| visitor.visit i[0] }
    tbody = @td.map {|tr| tr.map {|td| visitor.visit td } }
    return visitor.visit_table self, thead, tbody
  end
end
