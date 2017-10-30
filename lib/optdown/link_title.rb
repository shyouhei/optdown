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
require_relative 'expr'
require_relative 'inline'

# The spec  does not  list this  kind of elements,  but includes  the following
# line:
#
# > Backslash escapes and  entity and numeric character references  may be used
# > in titles
#
# So  it should  mean  the titles  are  _structured_, not  flat  simple set  of
# characters.
class Optdown::LinkTitle

  # @param str [String] the title to parse.
  def initialize str
    s = Optdown::Matcher === str ? str : Optdown::Matcher.new(str)
    @children = Optdown::Inline.tokenize s
    @children.map! do |t|
      case t.yylex
      when :'escape' then next Optdown::Escape.new t
      when :'entity' then next Optdown::Entity.new t
      else                next t
      end
    end
  end

  # custom renderer does not make sense for link destination, which is a URL.
  def plain
    return @children.map {|t|
      case t
      when Optdown::Token  then next t.yytext
      when Optdown::Escape then next t.entity
      when Optdown::Entity then next t.entity
      end
    }.join
  end

  # (see Optdown::Inline#accept)
  def accept visitor
    return visitor.visit_link_title self, @children.map{|i| visitor.visit i }
  end
end
