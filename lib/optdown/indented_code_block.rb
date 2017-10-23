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

# @see http://spec.commonmark.org/0.28/#indented-code-block
class Optdown::IndentedCodeBlock
  using Optdown::Matcher::Refinements

  attr_reader :pre # @return [Matcher] verbatim contents.

  # (see Optdown::Blocklevel#initialize)
  def initialize str, ctx
    pre = [ str.gets ]

    until str.eos? do
      case str
      when /#{Optdown::EXPR}\G\g<pre:indented>/o then
        pre << str.gets
      when /#{Optdown::EXPR}\G(?=\g<LINE:blank>+\g<pre:indented>)/o then
        str.match %r/#{Optdown::EXPR}\G\g<indent>/o # cut space
        pre << str.gets
      else
        break
      end
    end

    # > Blank  lines preceding  or following  an  indented code  block are  not
    # > included in it
    # @see http://spec.commonmark.org/0.28/#indented-code-block
    @pre = Optdown::Matcher.join pre \
      .reverse                       \
      .drop_while(&:blank?)          \
      .reverse                       \
      .drop_while(&:blank?)

  end

  # @return [nil] makes sense for fenced one, not here.
  def info
    return nil
  end
end
