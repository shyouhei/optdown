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

require_relative '../deeply_frozen'

# GFM uses https://github.com/vmg/houdini for  escaping HTML tags. The routines
# work differently from what Ruby provides through CGI::Escape. We have to fill
# the gap.
module Optdown::HoudiniCompat
  using Optdown::DeeplyFrozen

  module_function

  TMAP = deeply_frozen_copy_of({
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
  # "'" => '&#x27;', # not enabled in GFM
  # '/' => '&#x2F;', # not enabled in GFM
  })
  TRE = deeply_frozen_copy_of Regexp.union(TMAP.keys.sort.reverse)

  private_constant :TMAP, :TRE

  # Escapes HTML tags
  # @param  str [String] target.
  # @return     [String] escaped content.
  def escape_tag str
    return str.to_s.gsub TRE, TMAP
  end

  HRE = deeply_frozen_copy_of %r/[^#{eval <<~'end'}]/n

  # This table from `static const char HREF_SAFE[]` in houdini_href_e.c.
  [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1,
    0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]                                                                          \
    . each_with_index                                                        \
    . each_with_object("".dup) {|(x, y), z| z << y.chr('binary') if x == 1 } \
    . gsub(%/[\[\-\]]/, '\\\\\\&')
  end

  private_constant :HRE

  # Escapes hrefs.
  #
  # @note   Don't  blame  @shyouhei  for  the   behaviour.  This  is  a  direct
  #         translation of https://github.com/vmg/houdini and nothing more.
  # @param  str [String] target.
  # @return     [String] escaped content.
  def escape_href str
    s = str.to_s
    e = s.encoding
    return s \
      . to_s   \
      . b      \
      . gsub(HRE) {|m|
        case m
        when '&' then '&amp;'
        when "'" then '&#x27;'
        else '%' + m.unpack('H2' * m.bytesize).join('%').upcase
        end
      }        \
      . force_encoding(e)
  end
end
