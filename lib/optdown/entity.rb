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

require_relative 'html5entity'

# @see http://spec.commonmark.org/0.28/#entity-references
class Optdown::Entity
  attr_reader :token  # @return [String] original representation.
  attr_reader :entity # @return [String] escaped entity.

  # @param tok [Token] terminal token.
  def initialize tok
    md      = tok.yylval
    @token  = md['entity']
    @entity = case
              when e = md['entity:hex']   then encode e.to_i(16)
              when e = md['entity:dec']   then encode e.to_i(10)
              when e = md['entity:named'] then
                f = Optdown::HTML5ENTITY.fetch e
                f['characters']
            # else
            #   what to do...?
              end
  end

  private

  # > Invalid Unicode code points will be replaced by the REPLACEMENT CHARACTER
  # > (U+FFFD).   For security  reasons, the  code  point U+0000  will also  be
  # > replaced by U+FFFD.
  def encode c
    return "\uFFFD" if c == 0
    return c.chr Encoding::UTF_8
  rescue RangeError
    return "\uFFFD"
  end
end
