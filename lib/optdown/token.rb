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

require_relative 'xprintf'

# Token is an  intermediate node that would eventually be  "reduce"-d into some
# other kind of inline nodes.
class Optdown::Token
  using Optdown::XPrintf

  attr_reader :yylex  # @return [Symbol] terminal symbol.
  attr_reader :yytext # @return [String] terminal physical text.
  attr_reader :yylval # @return [String] terminal value.

  alias to_sym yylex
  alias to_s   yytext

  # @param yylex  [Symbol]    terminal symbol.
  # @param yylval [String]    terminal value.
  def initialize yylex, yylval, yytext = yylval
    @yylval = yylval
    @yytext = yytext
    @yylex  = yylex || symbolize
  end

  # throw away the parsed symbol and convert into verbatim cdata.
  def cdataify
    return self.class.new :cdata, @yytext
  end

  # easy debug
  # @return [String] inspection.
  def inspect
    sprintf '%p%p', yytext, yylex
  end

  private

  def symbolize
    md = yylval
    case
    when md['br']            then return :'break'
    when md['a:left']        then return :'link'
    when md['a:right']       then return :'link'
    when md['auto']          then return :'autolink'
    when md['auto:GH']       then return :'autolink'
    when md['code']          then return :'code'
    when md['entity:dec']    then return :'entity'
    when md['entity:hex']    then return :'entity'
    when md['entity:named']  then return :'entity'
    when md['escape']        then return :'escape'
    when md['flanker:and']   then return :'flanker'
    when md['flanker:left']  then return :'flanker'
    when md['flanker:right'] then return :'flanker'
    when md['img:left']      then return :'link'
    when md['tag']           then return :'tag'
    when md['table:delim']   then return :'table'
    else rprintf RuntimeError, 'TBW: %p', md
    end
  end
end
