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

require_relative 'matcher'
require_relative 'xprintf'

# Parser proper.
class Optdown::Parser
  using Optdown::XPrintf

  # This method has no params.  It exactly parses the GFM so no parameters are
  # there.
  def initialize
    @links = {}
    @inlines = []
  end

  # @param str [String]     target string to parse.
  # @return    [Blocklevel] parsed AST.
  def parse str
    @links.clear
    @inlines.clear
    m = Optdown::Matcher.new str
    b = Optdown::Blocklevel.new m, self
    # above parsing of blocklevel should have registered inlines
    @inlines.map(&:parse)
    return b
  end

  # @param link [LinkDef] definition body.
  # @return [void]
  def define_link link
    if @links[link.label] then
      # > If there  are multiple matching  reference link definitions,  the one
      # > that comes first  in the document is used.  (It  is desirable in such
      # > cases to emit a warning.)
      #
      # @see http://spec.commonmark.org/0.28/#matches
      wprintf "link %s defined more than once\n", link.label
    else
      @links[link.label] = link
    end
  end

  # @param label [Matcher] label string.
  # @return [LinkDef] corresponding definition.
  # @return [nil]     not found.
  def find_link_by label
    canon = Optdown::LinkDef.labelize label
    return @links[canon]
  end

  # @param inline [Inline] definition body.
  # @return [void]
  def define_inline inline
    @inlines << inline
  end

  # Because  this parser  object holds  complex object  graphs, its  inspection
  # output tends to become huge; normally not something readable by human eyes.
  # We would like to suppress a bit.
  def inspect
    '(parser)'
  end
end
