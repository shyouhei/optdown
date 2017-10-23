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

# @see http://spec.commonmark.org/0.28/#setext-headings
class Optdown::SetextHeading
  using Optdown::Matcher::Refinements

  attr_reader :level # return [Integer] heading level

  # This class is specified as "the lines of text must be such that, were they
  # not followed by the setext heading underline, they would be interpreted as
  # a paragraph" so we have to check that part here by actually deleting the
  # last line and parse it as a paragraph.
  #
  # @param  (see Optdown::Blocklevel#initialize)
  # @return [SetextHeading] peaceful creation of an instance.
  # @return [Blocklevel]    other classes are possible depending on contexts.
  # @return [nil]           ... or completely fails to parse, at worst.
  def self.new str, ctx
    ptr = str.dup
    ptr.match %r/
      #{Optdown::EXPR}\G (?<txt> \g<sh:body>+? ) (?= \g<sh:ul> )
    /xo
    cand  = Optdown::Blocklevel.new ptr['txt'], ctx
    ary   = cand.children
    klass = ary.first.class

    return klass.new str, ctx unless ary.length == 1
    return klass.new str, ctx unless klass == Optdown::Paragraph
    return super # OK, this is a valid setext heading.
  end

  # (see Optdown::Blocklevel#initialize)
  def initialize str, ctx
    a = []
    until str.eos? do
      case str when /#{Optdown::EXPR}\G\g<sh:ul>/o then
        break
      else
        a << str.gets
      end
    end
    b = Optdown::Matcher.join a
    @children = Optdown::Paragraph.new b, ctx

    if str.last_match.begin 'sh:lv1' then
      @level = 1
    else
      @level = 2
    end
  end
end
