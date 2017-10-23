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

require_relative 'test_helper'
require 'optdown'

class TC_Inline < Test::Unit::TestCase
  sub_test_case '.tokenize' do
    data(
      'empty' => ['', %i[]],
      'cdata' => ['foo', %i[cdata]],

      'entity1' => ['\\&amp;', %i[escape cdata]],
      'entity2' => ['\\\\&amp;', %i[escape entity]],
      'entity3' => ['&#x26;', %i[entity]],
      'entity4' => ['&#38;', %i[entity]],
      'entity5' => ['&amp', %i[cdata]],
      'entity6' => ['&#xFFFFFFFFF;', %i[cdata]],
      'entity7' => ['&varsubsetneqq;', %i[entity]],

      'code1' => ['`1`', %i[code]],
      'code2' => ['`` `2` ``', %i[code]],
      'code3' => ['\\``3``', %i[escape cdata]],
      'code4' => ['```7\\```', %i[code]],

      ' left !right 1' => ['***abc', %i[flanker cdata]],
      ' left !right 2' => ['  _abc,', %i[cdata flanker cdata]],
      ' left !right 3' => ['**"abc"', %i[flanker cdata]],
      ' left !right 4' => [' _"abc"', %i[cdata flanker cdata]],
      '!left  right 1' => ['abc***', %i[cdata flanker]],
      '!left  right 2' => ['abc_  ', %i[cdata flanker cdata]],
      '!left  right 3' => ['"abc"**', %i[cdata flanker]],
      '!left  right 4' => ['"abc"_ ', %i[cdata flanker cdata]],
      ' left  right 1' => [' abc***def ', %i[cdata flanker cdata]],
      ' left  right 2' => ['"abc"_"def"', %i[cdata flanker cdata]],
      '!left !right 1' => ['abc *** def', %i[cdata]],
      '!left !right 2' => ['a _ b', %i[cdata]],

      'emph1' => ['*foo*', %i[flanker cdata flanker]],

      'link1' => ['\\](foo)', %i[escape cdata]],
      'link2' => ['\\\\](foo)', %i[escape link]],
      'link3' => [']\\(foo)', %i[link escape cdata]],
      'link4' => ['](f\\)oo)', %i[link]],

      'html1' => ['\\<html>', %i[escape cdata]],
      'html2' => ['\\\\<html>', %i[escape tag]],
      'html3' => ['\\\\<tag x=\\>', %i[escape tag]],

      'auto1' => ['foo <http://www.example.com>', %i[cdata autolink]],
      'auto2' => ['foo <mailto:root@mput.dip.jp>', %i[cdata autolink]],
      'auto3' => ['foo www.example.com', %i[cdata autolink]],
      'auto4' => ['foo http://www.example.com', %i[cdata autolink]],
      'auto5' => ['foo root@mput.dip.jp', %i[cdata autolink]],

      'br1' => ["foo  \nbar", %i[cdata break cdata]],
      'br2' => ["foo\\\nbar", %i[cdata break cdata]],
      'br3' => ["foo \n bar", %i[cdata break cdata]]
    )

    test '.tokenize' do |(src, expected)|
      str = Optdown::Matcher.new src
      actual = Optdown::Inline.tokenize str
      assert_equal expected, actual.map(&:to_sym)
    end
  end

  sub_test_case '.parse' do
    data(
      'empty' => ['', nil],
      'cdata' => ['foo', %w[Token]],

      'escape1' => ['\\&amp;', %w[Escape Token]],
      'escape2' => ['\\\\&amp;', %w[Escape Entity]],

      'entityD' => ['&#x26;', %w[Entity]],
      'entityX' => ['&#38;', %w[Entity]],
      'entityE' => ['&varsubsetneqq;', %w[Entity]],
      'entity;' => ['&amp', %w[Token]],
      'entityo' => ['&#xFFFFFFFFF;', %w[Token]],

      'code1'  => ['`foo`bar', %w[CodeSpan Token]],
      'code2'  => ['`` ` ``foo', %w[CodeSpan Token]],
      'code3'  => ['```foo``', %w[Token]],
      'code\\' => ['`esc\\`foo', %w[CodeSpan Token]],

      'aster1'  => ['*foo*bar', %w[Aster Token]],
      'aster2'  => ['**foo**bar', %w[Aster Token]],
      'aster3'  => ['***foo*** bar', %w[Aster Token]],
      'aster3-' => ['***foo***bar', %w[Token Token Token Token]],
      'aster\\' => ['**\\***', %w[Aster]],

      'under1'  => ['_foo_ bar', %w[Under Token]],
      'under1-' => ['_foo_bar', %w[Token Token Token Token]],
      'under2'  => ['__foo__ bar', %w[Under Token]],
      'under3'  => ['___foo___ bar', %w[Under Token]],
      'under\\' => ['__\\___', %w[Under]],

      'tilde1'  => ['~foo~ bar', %w[Strikethrough Token]],
      'tilde2'  => ['~~foo~~ bar', %w[Strikethrough Token]],
      'tilde3'  => ['foo ~~~bar~~~', %w[Token Strikethrough]], # avoid fence
      'tilde\\' => ['~~\\~~~', %w[Strikethrough]],
      'tilden'  => ['~foo~~~ bar', %w[Strikethrough Token]],

      'link inline 1' => ['[foo](bar)', %w[A]],
      'link inline 2' => ['[foo](<bar>)', %w[A]],
      'link inline 3' => ['[foo](<bar> (baz))', %w[A]],
      'link inline 4' => ['[foo](<bar> "baz")', %w[A]],
      'link inline 5' => ["[foo](<bar> 'baz')", %w[A]],
      'link inline 6' => ["[foo](<bar>\n'baz')", %w[A]],
      'link inline 7' => ["[foo](<bar>\n\n'baz')", %w[Token Token Token Token RawHTML]],

      'link label 0'     =>  ['[foo][bar]', %w[Token Token Token Token Token Token]],
      'link label 1'     =>  ["[foo][bar]\n\n[bar]: bar", %w[A]],
      'link collapsed 0' =>  ["[foo][]: bar", %w[Token Token Token Token]],
      'link collapsed 1' =>  ["[foo][]: bar\n\n[foo]: bar", %w[A Token]],
      'link sc 0'        =>  ['[foo]', %w[Token Token Token]],
      'link sc 1'        =>  ["[foo]\n\n[foo]: bar", %w[A]],

      'auto1' => ['foo <http://www.example.com>', %w[Token Autolink]],
      'auto2' => ['foo <mailto:root@mput.dip.jp>', %w[Token Autolink]],
      'auto3' => ['foo www.example.com', %w[Token Autolink]],
      'auto4' => ['foo http://www.example.com', %w[Token Autolink]],
      'auto5' => ['foo root@mput.dip.jp', %w[Token Autolink]],

      'br1' => ["foo  \nbar", %w[Token Newline Token]],
      'br2' => ["foo\\\nbar", %w[Token Newline Token]],
      'br3' => ["foo \n bar", %w[Token Newline Token]]
    )

    @@parser = Optdown::Parser.new

    test '.new' do |(src, expected)|
      obj = @@parser.parse src
      actual = obj.children&.first&.children&.map{|i|/\w+\z/.match(i.class.to_s)[0]}
      if expected != actual then
        p obj.children
      end
      assert_equal expected, actual
    end
  end
end
