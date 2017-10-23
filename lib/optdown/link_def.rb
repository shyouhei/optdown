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

# @see http://spec.commonmark.org/0.28/#link-reference-definitions
class Optdown::LinkDef
  attr_reader :dest  # @return [String] URL
  attr_reader :title # @return [String] title
  attr_reader :label # @return [String] label

  # @see http://spec.commonmark.org/0.28/#matches
  # @param str [String] label candidate.
  # @return    [String] normalized label string.
  def self.labelize str
    return str          \
      . to_s            \
      . downcase(:fold) \
      . gsub %r/#{Optdown::EXPR}\g<WS+>/o, ' '
  end

  # (see Optdown::Blocklevel#initialize)
  def initialize str, ctx
    @label = self.class.labelize str['link:label']
    dest   = str['link:dest']
    title  = str['link:title:2j'] ||
             str['link:title:1j'] ||
             str['link:title:0j']
    @dest  = dest && Optdown::LinkTitle.new(dest.to_s).plain
    @title = title && Optdown::LinkTitle.new(title.to_s)
    ctx.define_link self
  end
end
