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

class TC_Blocklevel < Test::Unit::TestCase
  sub_test_case '.new' do
    data(
      'empty'  => ['', []],
      'p'      => ['foo', %w[Paragraph]],
      'table'  => ["foo|bar\n|-|-|\nfoo|bar\n", %w[Table]],
      'setext' => ["foo\n===", %w[SetextHeading]],
      'atx'    => ['### foo ###', %w[ATXHeading]],
      'pre'    => ['    foo', %w[IndentedCodeBlock]],
      'fence'  => ["```\nfoo\n```", %w[FencedCodeBlock]],
      'tag'    => ['<!-- foo -->', %w[BlockHTML]],
      'li'     => ['- foo', %w[List]],
      'quote'  => ['> foo', %w[Blockquote]],
      'link'   => ['[foo]: <bar> "baz"', %w[LinkDef]],
      'hr'     => ['--------', %w[ThematicBreak]],

      'link00'   => [%'[foo]:\n(bar)', %w[LinkDef]],
      'link01'   => [%"[foo]:\n'bar'", %w[LinkDef]],
      'link02'   => [%'[foo]:\n"bar"', %w[LinkDef]],
      'linkb'    => [%'[foo]:\nbar\n"baz"', %w[LinkDef]],
      'link<'    => [%'[foo]:\n<bar>', %w[LinkDef]],
      'link\n'   => [%'[foo]: <bar> "\nb\na\nz\n"', %w[LinkDef]],
      'link\n\n' => [%'[foo]: <bar> "\nb\n\na\nz\n"', %w[Paragraph Paragraph]],
      'link10'   => [%' [foo]:\n <bar>\n "baz"', %w[LinkDef]],
      'link20'   => [%'  [foo]:\n  <bar>\n  "baz"', %w[LinkDef]],
      'link30'   => [%'   [foo]:\n   <bar>\n   "baz"', %w[LinkDef]],
      'link40'   => [%'    [foo]:\n    <bar>\n    "baz"', %w[IndentedCodeBlock]],
      'link41'   => [%'[foo]:\n    <bar>\n    "baz"', %w[LinkDef]],

      'quote00'  => [%'>foo', %w[Blockquote]],
      'quote01'  => [%'> foo', %w[Blockquote]],
      'quote02'  => [%'>  foo', %w[Blockquote]],
      'quote03'  => [%'>   foo', %w[Blockquote]],
      'quote04'  => [%'>    foo', %w[Blockquote]],
      'quote n1' => [%'> foo\n> nbar\n', %w[Blockquote]],
      'quote n2' => [%'> foo\n\n> bar', %w[Blockquote Blockquote]],
      'quote l1' => [%'> foo\nbar\n', %w[Blockquote]],
      'quote l2' => [%'> foo\n- bar\n', %w[Blockquote List]],
      'quote l3' => [%'> foo\n1. bar\n', %w[Blockquote List]],
      'quote l4' => [%'> foo\n2. bar\n', %w[Blockquote]], # https://github.com/commonmark/cmark/issues/204
      'quote 01' => [%'>\nfoo', %w[Blockquote Paragraph]],

      'li -'   => [%'- foo', %w[List]],
      'li *'   => [%'* foo', %w[List]],
      'li +'   => [%'+ foo', %w[List]],
      'li [ ]' => [%'- [ ] foo', %w[List]],
      'li [x]' => [%'- [x] foo', %w[List]],
      'li 1'   => [%'1. foo', %w[List]],
      'li 0'   => [%'0. foo', %w[List]],
      'li 9'   => [%'9. foo', %w[List]],
      'li 9+'  => [%'1234567890. foo', %w[Paragraph]],
      'li hr'  => [%'- - -', %w[ThematicBreak]],
      'li i0'  => [%"- foo\n> bar", %w[List Blockquote]],
      'li i1'  => [%"- foo\n > bar", %w[List Blockquote]],
      'li i2'  => [%"- foo\n  > bar", %w[List]],
      'li i3'  => [%"- foo\n   > bar", %w[List]],
      'li i4'  => [%"- foo\n    > bar", %w[List]],
      'li n1'  => [%"- foo\n\nbar", %w[List Paragraph]],
      'li n2'  => [%"- foo\n\n- bar", %w[List]],
      'li n3'  => [%"- foo\n\n+ bar", %w[List List]],
      'li pre' => [%"-     \n\t  foo\n", %w[List]],
      'li eol' => [%"-\n  foo", %w[List]],
      'li p'   => [%"-    foo\n\n  foo\n", %w[List Paragraph]],

      'tag10' => ['<pre>foo</pre>', %w[BlockHTML]],
      'tag11' => ["<pre>\nfoo\n</pre>\nbar", %w[BlockHTML Paragraph]],
      'tag20' => ['<!-- foo -->', %w[BlockHTML]],
      'tag21' => ["<!--\nfoo\n-->\nbar", %w[BlockHTML Paragraph]],
      'tag30' => ['<?xml version="1.0"?>', %w[BlockHTML]],
      'tag31' => ["<?xmp\nversion='1.0'?>\nbar", %w[BlockHTML Paragraph]],
      'tag40' => ['<!DOCTYPE html>', %w[BlockHTML]],
      'tag41' => ["<!DOCTYPE\nhtml>\nbar", %w[BlockHTML Paragraph]],
      'tag50' => ['<![CDATA[<br />]]>', %w[BlockHTML]],
      'tag51' => ["<![CDATA[\n\n]]>\nbar", %w[BlockHTML Paragraph]],
      'tag60' => ['<html>', %w[BlockHTML]],
      'tag61' => ["<html>\nfoo\n</html>\n\nbar", %w[BlockHTML Paragraph]],
      'tag70' => ['<svg>', %w[BlockHTML]],
      'tag71' => ["<svg>\nfoo\n</svg>\n\nbar", %w[BlockHTML Paragraph]],
      'tag72' => ["<svg>foo</svg>\n\nbar", %w[Paragraph Paragraph]],

      'fence3'   => ["```\nfoo\n```\nfoo", %w[FencedCodeBlock Paragraph]],
      'fence4'   => ["````\nfoo\n````", %w[FencedCodeBlock]],
      'fence4+'  => ["````\nfoo\n```````````", %w[FencedCodeBlock]],
      'fence i1' => [" ```\nfoo\n ```", %w[FencedCodeBlock]],
      'fence i2' => ["  ```\nfoo\n  ```", %w[FencedCodeBlock]],
      'fence i3' => ["   ```\nfoo\n    ```", %w[FencedCodeBlock]],
      'fence i4' => ["    ```\nfoo\n    ```", %w[IndentedCodeBlock Paragraph]],

      'pre\t' => ["\tfoo\n", %w[IndentedCodeBlock]],
      'pre+'  => ["    foo\n  \n    bar", %w[IndentedCodeBlock]],

      'atx 0' => ['### foo', %w[ATXHeading]],
      'atx 1' => [' ### foo', %w[ATXHeading]],
      'atx 2' => ['  ### foo', %w[ATXHeading]],
      'atx 3' => ['   ### foo', %w[ATXHeading]],
      'atx 4' => ['    ### foo', %w[IndentedCodeBlock]],
      'atx t' => ['### foo #', %w[ATXHeading]],

      'setext p' => ["- foo\n====", %w[List]],
      'setext hr' => ["- foo\n----", %w[List ThematicBreak]],
      'setext bq' => ["> foo\n====", %w[Blockquote]],
      'setext 1' => [" foo\n----", %w[SetextHeading]],
      'setext 2' => ["  foo\n----", %w[SetextHeading]],
      'setext 3' => ["   foo\n----", %w[SetextHeading]],
      'setext 4' => ["    foo\n----", %w[IndentedCodeBlock ThematicBreak]],

      'table 0'  => ["foo|bar\n|-|-|\nfoo\n", %w[Table]],
      'table 1'  => [" foo|bar\n |-|-|\n foo\n", %w[Table]],
      'table 2'  => ["  foo|bar\n  |-|-|\n  foo\n", %w[Table]],
      'table 3'  => ["   foo|bar\n   |-|-|\n   foo\n", %w[Table]],
      'table 4'  => ["    foo|bar\n    |-|-|\n    foo\n", %w[IndentedCodeBlock]],
      'table -'  => ["|foo|\n|-|\nfoo\n", %w[Table]],
      'table :-' => ["|foo|\n|:-|\nfoo\n", %w[Table]],
      'table -:' => ["|foo|\n|-:|\nfoo\n", %w[Table]],
      'table ::' => ["|foo|\n|:-:|\nfoo\n", %w[Table]],
      'table hr' => ["|foo|\n|-|\n----", %w[Table ThematicBreak]],
      'table bq' => ["|foo|\n|-|\n> foo", %w[Table Blockquote]],
      'table li' => ["|foo|\n- |\nfoo", %w[Paragraph List]],
      'table h2' => ["|foo|\n---\nfoo", %w[SetextHeading Paragraph]],

      'p ul 1' => ["foo\n- bar", %w[Paragraph List]],
      'p ul 2' => ["foo\n-\nbar", %w[SetextHeading Paragraph]],
      'p ol 1' => ["foo\n1. bar", %w[Paragraph List]],
      'p ol 2' => ["foo\n2. bar", %w[Paragraph]],
    )

    @@parser = Optdown::Parser.new

    test '.new' do |(src, expected)|
      obj = @@parser.parse src
      actual = obj.children.map{|i|/\w+\z/.match(i.class.to_s)[0]}
      # if expected != actual then
      #   p obj.children
      # end
      assert_equal expected, actual
    end
  end
end
