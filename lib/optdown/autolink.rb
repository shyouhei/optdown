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


# http://spec.commonmark.org/0.28/#autolinks
class Optdown::Autolink
  attr_reader :href    # @return [String] the link.
  attr_reader :display # @return [String] the content.

  # @param tok [Token] terminal token.
  def initialize tok
    md = tok.yylval
    case
    when md['auto:URI']      then @href = md['auto:URI']
    when md['auto:mail']     then @href = 'mailto:' + md['auto:mail']
    when md['auto:GH:www']   then @href = 'http://' + tok.to_s
    when md['auto:GH:url']   then @href = tok.to_s
    when md['auto:GH:email'] then @href = 'mailto:' + tok.to_s
    end
    @display = md['auto:URI'] || md['auto:mail'] || tok.to_s
  end

  # (see Optdown::Inline#accept)
  def accept visitor
    return visitor.visit_auto_link self
  end
end
