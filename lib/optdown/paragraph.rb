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
require_relative 'deeply_frozen'

# @see http://spec.commonmark.org/0.28/#paragraphs
class Optdown::Paragraph
  using Optdown::DeeplyFrozen
  using Optdown::Matcher::Refinements

  # Paragraph continuations shall construct paragraphs, not other block levels.
  # For instance  "> foo\n ====" shall  not be  an h2  inside of  a blockquote.
  # This constant sneaks into parsed DOM trees to prevent such misconceptions.
  PAD = deeply_frozen_copy_of Optdown::Matcher.new("\t\t")

  # (see Optdown::Blocklevel#initialize)
  def initialize str, ctx
    a = [ str.gets ] # at least one line shall be there.
    a << str.gets until str.match? %r/#{Optdown::EXPR}\G\g<p:cutter>/o
    b = trim a
    @children = Optdown::Inline.from_lines b, ctx
  end

  private

  # > The paragraph’s  raw content  is formed by  concatenating the  lines and
  # > removing initial and final whitespace.
  #
  # So we have to trim the input here.
  #
  # @see http://spec.commonmark.org/0.28/#paragraphs
  def trim a
    a.map! do |i|
      i.match %r/#{Optdown::EXPR}\A\g<WS+>/o
      i.read
    end
    a[-1], = a[-1].advance %r/#{Optdown::EXPR}\g<WS+>\z/o
    return a
  end

  public

  # @todo description TBW.
  def children
    @children&.children
  end

  # (see Optdown::Blocklevel#accept)
  def accept visitor, tightp: false
    inner = visitor.visit @children
    return visitor.visit_paragraph self, tightp, inner
  end
end
