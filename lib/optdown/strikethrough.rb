#! /your/favourite/path/to/ruby
# -*- mode: ruby; coding: utf-8; indent-tabs-mode: nil; ruby-indent-level: 2 -*-
# -*- frozen_string_literal: false -*-
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

require_relative 'flanker'

# @see https://github.github.com/gfm/#strikethrough-extension-
class Optdown::Strikethrough < Optdown::Flanker
  def self.opener? tok
    return super && tok.yylval['flanker:run:~']
  end

  def self.closer? tok
    return super && tok.yylval['flanker:run:~']
  end

  # strilethrough allow mismatching number of tildes.
  def self.reduce tokens, iopen, iclose, ctx
    range  = iopen..iclose
    body   = tokens[range].compact
    t1     = body.shift
    t2     = body.pop
    recur body, ctx
    node   = new t1, body, t2
    tokens.fill nil, range
    tokens[iopen, 3] = [node]
    tokens.compact!    
  end

  # (see Optdown::Inline#accept)
  def accept visitor
    elems = @children.map {|i| visitor.visit i }
    return visitor.visit_strikethrough self, elems
  end

  def initialize open, body, close
    @children = body
  end
end
