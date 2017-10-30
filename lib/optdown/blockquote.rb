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

# @see http://spec.commonmark.org/0.28/#block-quotes
class Optdown::Blockquote
  using Optdown::Matcher::Refinements

  attr_reader :children # (see Optdown::Blocklevel#children)

  # (see Optdown::Blocklevel#initialize)
  def initialize str, ctx
    lines = [ ]
    until str.eos? do
      line = str.gets
      lines << line
      unless line.match? %r/#{Optdown::EXPR}\G
        # :FIXME: this is mostly okay but inaccurate.
        ( \g<LINE:blank> | \g<hr> | \g<tag:cutter> |
          \g<pre:fenced> | \g<pre:indented> | \g<atx> )
      /xo then
        until str.match? %r/#{Optdown::EXPR}\G\g<p:cutter>/o do
          lines << Optdown::Paragraph::PAD
          lines << str.gets
        end
      end
      break unless str.match %r/#{Optdown::EXPR}\G\g<blockquote>/o
    end
    @children = Optdown::Blocklevel.from_lines lines, ctx
  end

  # (see Optdown::Blocklevel#accept)
  def accept visitor, tightp: false
    inner = visitor.visit @children
    return visitor.visit_blockquote self, inner
  end
end
