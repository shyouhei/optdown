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

# @see http://spec.commonmark.org/0.28/#html-blocks
class Optdown::BlockHTML
  using Optdown::XPrintf

  attr_reader :html # @return [Matcher] the HTML content.

  # (see Optdown::Blocklevel#initialize)
  def initialize str, ctx
    md    = str.last_match
    open  = str[0]
    re    = Optdown::EXPR # easy typing.
    case
    when md['tag:start1'] then term = /#{re}\g<tag:end1>/o
    when md['tag:start2'] then term = /#{re}\g<tag:end2>/o
    when md['tag:start3'] then term = /#{re}\g<tag:end3>/o
    when md['tag:start4'] then term = /#{re}\g<tag:end4>/o
    when md['tag:start5'] then term = /#{re}\g<tag:end5>/o
    when md['tag:start6'] then term = nil
    when md['tag:start7'] then term = nil
    else rprintf RuntimeError, "logical bug: unknown match %p", md
    end

    # > If the first line meets both the start condition and the end condition,
    # > the block will contain just that line.
    #
    # @see http://spec.commonmark.org/0.28/#html-blocks
    list = []
    line = Optdown::Matcher.join [ open, str.gets ] # the first line.
    loop do
      list << line
      break if str.eos?
      break if term and line.match? term
      break if (! term) and str.match? %r/#{re}\G\g<LINE:blank>/o
      line = str.gets
    end
    @html = Optdown::Matcher.join list
  end

  # (see Optdown::Blocklevel#accept)
  def accept visitor, tightp: false
    return visitor.visit_blockhtml self
  end
end
