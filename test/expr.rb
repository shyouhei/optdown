#! /your/favourite/path/to/ruby
# -*- mode: ruby; coding: utf-8; indent-tabs-mode: nil; ruby-indent-level: 2 -*-
# -*- frozen_string_literal: true-*-
# -*- warn_indent: true-*-

# Copyright (c) 2017 Urabe, Shyouhei
#
# Permission is hereby granted, free of  charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies  of the  Software, and to  permit  persons to  whom  the Software  is
# furnished to do so, subject to the following conditions:
#
#         The above copyright notice and this permission notice shall be
#         included in all copies or substantial portions of the Software.
#
# THE SOFTWARE  IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY  KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT  NOT LIMITED  TO THE  WARRANTIES OF  MERCHANTABILITY,
# FITNESS FOR A  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO  EVENT SHALL THE
# AUTHORS  OR COPYRIGHT  HOLDERS  BE LIABLE  FOR ANY  CLAIM, DAMAGES OR  OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative 'test_helper'
require 'optdown'

class TC_Expr < Test::Unit::TestCase

  # This regular expression  is the heart of this library.   Bugs in it results
  # in catastrophic situation.  We have to test it extensively.
  test 'EXPR' do
    assert_kind_of Regexp, Optdown::EXPR
  end

  def self.check expr
    test 'EXPR' do |(src, expected)|
      str = Optdown::Matcher.new(src)
      assert_equal expected, str.match?(expr)
    end
  end

  sub_test_case 'thematic break' do
    data(
      '01'  => ['-', false],
      '02'  => ['--', false],
      '03'  => ['---', true],
      '04'  => ['----', true],
      '_'   => ['___', true],
      '*'   => ['***', true],
      '+'   => ['+++', false],
      ' '   => ['- - -', true],
      'mix' => ['- + -', false],
      'p'   => ['foo', false],
      'tag' => ['<foo>', false],
      'li'  => ['+ foo', false],
      'bq'  => ['> foo', false]
    )
    check(/#{Optdown::EXPR}\G\g<hr>/o)
  end

  sub_test_case 'atx heading' do
    data(
      '01'        => ['# foo', true],
      '02'        => ['## foo', true],
      '03'        => ['### foo', true],
      '04'        => ['#### foo', true],
      '05'        => ['##### foo', true],
      '06'        => ['###### foo', true],
      '07'        => ['####### foo', false],
      'train'     => ['## foo ############    ', true],
      'mixed'     => ['# f # o # o #', true],
      'esc1'      => ['\# foo', false],
      'esc2'      => ['# foo #\#\#\#\#\#', true],
      'empty'     => ['#', true],
      'space'     => ['#             foo', true],
      'paragraph' => ["foo\nbar\n\nbaz\n", false],
      'tag'       => ["<html>\n===", false],
      'list'      => ["+ foo\n===", false],
      'bq'        => ["> foo\n===", false],
      'h2'        => ["--\nfoo\n---", false],
      'ul'        => [" -\nfoo\n---", false]
    )
    check(/#{Optdown::EXPR}\G\g<atx>/o)
  end

  sub_test_case 'setext heading' do
    data(
      '1'         => ["foo\n===", true],
      '2'         => ["foo\n---", true],
      'multiline' => ["foo\nbar\nbaz\n---", true],
      'indent'    => ["   foo\n===", true],
      'pre'       => ["    foo\n===", false],
      'paragraph' => ["foo\nbar\n\nbaz\n", false]
    )
    check(/#{Optdown::EXPR}\G\g<sh>/o)
  end

  sub_test_case 'indented code block' do
    data(
      'ok'  => ['    foo', true],
      'ng'  => ['   foo', false],
      'tab' => ["\tfoo", true],
      'mix' => [" \t foo", true]
    )
    check(/#{Optdown::EXPR}\G\g<pre:indented>/o)
  end

  sub_test_case 'fenced code block' do
    data(
      '0~'   => ['~~~', true],
      '0`'   => ['```', true],
      '`4'   => ['````', true],
      '`2'   => ['``foo', false],
      'i0'   => ['```foo', true],
      'i1'   => ['``` foo', true],
      'i2'   => ['```  foo', true],
      'i3'   => ['```   foo', true],
      'i4'   => ['```    foo', true],
      'i+'   => ['``` foo:bar baz  ', true],
      'list' => ['+ foo', false],
      'bq'   => ['> foo', false]
    )
    check(/#{Optdown::EXPR}\G\g<pre:fenced>/o)
  end

  sub_test_case 'html block' do
    sub_test_case 'distinguisher' do
      data(
        '1'      => ['<pre><code>foo</code></pre>', true],
        '2'      => ['<!-- foo -->', true],
        '3'      => ['<?xml version="1.0" encoding="UTF-8"?>', true],
        '4'      => ['<!DOCTYPE html>', true],
        '5'      => ['<![CDATA[<br />]]>', true],
        '6'      => ['<html>', true],
        '7'      => ['<svg>', true],
        'list'   => ['+ foo', false],
        'bq'     => ['> foo', false]
      )
      check(/#{Optdown::EXPR}\G\g<tag:block>/o)
    end

    sub_test_case 'cutter' do
      data(
        '1'      => ['<pre><code>foo</code></pre>', true],
        '2'      => ['<!-- foo -->', true],
        '3'      => ['<?xml version="1.0" encoding="UTF-8"?>', true],
        '4'      => ['<!DOCTYPE html>', true],
        '5'      => ['<![CDATA[<br />]]>', true],
        '6'      => ['<html>', true],
        '7'      => ['<svg>', false],
        'list'   => ['+ foo', false],
        'bq'     => ['> foo', false]
      )
      check(/#{Optdown::EXPR}\G\g<tag:cutter>/o)
    end
  end

  sub_test_case 'link definition' do
    data(
      'empty'    => ['', false],
      'garbage'  => ['abc', false],
      'minimal'  => ['[x]:<>', true],
      'nl1'      => ["[foo\nbar]:<>", true],
      'dest'     => ['[x]: y', true],
      'dest<>'   => ['[x]: <y>', true],
      'dest()'   => ['[x]: y(z(w))', true],
      'title'    => ['[x]: y "z"', true],
      'garbage2' => ['[x]: y "z" w', false]
    )
    check(/#{Optdown::EXPR}\G\g<link:def>/o)
  end

  sub_test_case 'list item' do
    sub_test_case 'distinguisher' do
      data(
        '0-'  => ['- foo', true],
        '0+'  => ['+ foo', true],
        '0*'  => ['* foo', true],
        '0)'  => ['1) foo', true],
        '0.'  => ['1. foo', true],
        '0#'  => ['. foo', false],
        '1#'  => ['0. foo', true],
        '2#'  => ['00. foo', true],
        '3#'  => ['000. foo', true],
        '4#'  => ['0000. foo', true],
        '5#'  => ['00000. foo', true],
        '6#'  => ['000000. foo', true],
        '7#'  => ['0000000. foo', true],
        '8#'  => ['00000000. foo', true],
        '9#'  => ['000000000. foo', true],
        'X#'  => ['0000000000. foo', false],
        'tab' => ["-\tfoo", true],
        't0'  => ['-foo', false],
        't1'  => ['- foo', true],
        't2'  => ['-  foo', true],
        't3'  => ['-   foo', true],
        't4'  => ['-    foo', true],
        't5'  => ['-     foo', true],
        'e0'  => ['-', true],
        'e1'  => ['- ', true],
        'e2'  => ['-  ', true],
        'e3'  => ['-   ', true],
        'e4'  => ['-    ', true],
        'e5'  => ['-     ', true],
        '#0'  => ['1.', true],
        '#1'  => ['1. ', true],
        '#2'  => ['1.  ', true],
        '#3'  => ['1.   ', true],
        '#4'  => ['1.    ', true],
        '#5'  => ['1.     ', true],
        '.0'  => ['0. 0', true],
        '.1'  => ['1. 1', true],
        '.2'  => ['2. 2', true],
        '.3'  => ['3. 3', true],
        '.4'  => ['4. 4', true],
        '.5'  => ['5. 5', true],
        '.6'  => ['6. 6', true],
        '.7'  => ['7. 7', true],
        '.8'  => ['8. 8', true],
        '.9'  => ['9. 9', true]
      )
      check(/#{Optdown::EXPR}\G\g<li>/o)
    end

    sub_test_case 'cutter' do
      # THIS DATA IS DIFFERENT FROM ABOVE.
      data(
        '0-'  => ['- foo', true],
        '0+'  => ['+ foo', true],
        '0*'  => ['* foo', true],
        '0)'  => ['1) foo', true],
        '0.'  => ['1. foo', true],
        '0#'  => ['. foo', false],
        '1#'  => ['0. foo', false],
        '2#'  => ['00. foo', false],
        '3#'  => ['000. foo', false],
        '4#'  => ['0000. foo', false],
        '5#'  => ['00000. foo', false],
        '6#'  => ['000000. foo', false],
        '7#'  => ['0000000. foo', false],
        '8#'  => ['00000000. foo', false],
        '9#'  => ['000000000. foo', false],
        'X#'  => ['0000000000. foo', false],
        'tab' => ["-\tx", true],
        't0'  => ['-x', false],
        't1'  => ['- x', true],
        't2'  => ['-  x', true],
        't3'  => ['-   x', true],
        't4'  => ['-    x', true],
        't5'  => ['-     x', true],
        'e0'  => ['-', false],
        'e1'  => ['- ', false],
        'e2'  => ['-  ', false],
        'e3'  => ['-   ', false],
        'e4'  => ['-    ', false],
        'e5'  => ['-     ', false],
        '#0'  => ['1.', false],
        '#1'  => ['1. ', false],
        '#2'  => ['1.  ', false],
        '#3'  => ['1.   ', false],
        '#4'  => ['1.    ', false],
        '#5'  => ['1.     ', false],
        '.0'  => ['0. 0', false],
        '.1'  => ['1. 1', true],
        '.2'  => ['2. 2', false],
        '.3'  => ['3. 3', false],
        '.4'  => ['4. 4', false],
        '.5'  => ['5. 5', false],
        '.6'  => ['6. 6', false],
        '.7'  => ['7. 7', false],
        '.8'  => ['8. 8', false],
        '.9'  => ['9. 9', false]
      )
      check(/#{Optdown::EXPR}\G\g<li:cutter>/o)
    end
  end

  sub_test_case 'table' do
    data(
      'empty'    => ['', false],
      'garbage'  => ['abc', false],
      'minimal'  => ["|foo|\n|-|", true],
      '2td'      => ["foo|bar\n|-|-", true],
      'tr NG1'   => ["foo\n-\nbar\n", false],
      'tr OK'    => ["foo\n-|\nbar\n", true],
      'tr NG2'   => ["foo\n- |\nbar\n", false],
      'li'       => ["|foo|\n- |", false ],
    )
    check(/#{Optdown::EXPR}\G\g<table>/o)
  end

  sub_test_case 'escape' do
    data(
      'empty'   => ['', false],
      'garbage' => ['abc', false],
      'punct'   => ['\\[', true],
      'alpha'   => ['\\A', false],
      'numeric' => ['\\0', false],
      'the $'   => ['\\$', true], # cf https://bugs.ruby-lang.org/issues/12577
      'the \\'  => ['\\\\', true],
      'unicode' => ["\\\u2026", false],
      'many\\'  => ['\\\\\[', true]
    )
    check(/#{Optdown::EXPR}\g<escape+>/o)
  end

  sub_test_case 'entity' do
    data(
      'empty'    => ['', false],
      'garbage'  => ['abc', false],
      'hex'      => ['&#x26;', true],
      'dec'      => ['&#38;', true],
      'named'    => ['&amp;', true],
      'missing;' => ['&amp', false],
      'overflow' => ['&#xFFFFFFFFF;', false],
      'HTML5'    => ['&varsubsetneqq;', true]
    )
    check(/#{Optdown::EXPR}\g<entity>/o)
  end

  sub_test_case 'code_span' do
    data(
      'empty'   => ['', false],
      'garbage' => ['abc', false],
      '1'       => ['`1`', true],
      '2'       => ['`` `2` ``', true],
      '\\`'  => ['```3\\```', true]
    )
    check(/#{Optdown::EXPR}\g<code>/o)
  end

  sub_test_case '*' do
    data(
      'empty'          => ['', false],
      'garbage'        => ['abc', false],
      ' left !right 1' => ['***abc', true],
      ' left !right 3' => ['**"abc"', true],
      '!left  right 1' => ['abc***', true],
      '!left  right 3' => ['"abc"**', true],
      ' left  right 1' => [' abc***def ', true],
      '!left !right 1' => ['abc *** def', false]
    )
    check(/#{Optdown::EXPR}\g<flanker:or>/o)
  end

  sub_test_case '_' do
    data(
      'empty'          => ['', false],
      'garbage'        => ['abc', false],
      ' left !right 2' => ['  _abc', true],
      ' left !right 4' => [' _"abc"', true],
      '!left  right 2' => ['abc_  ', true],
      '!left  right 4' => ['"abc"_ ', true],
      ' left  right 2' => ['"abc"_"def"', true],
      '!left !right 2' => ['a _ b', false]
    )
    check(/#{Optdown::EXPR}\g<flanker:or>/o)
  end

  sub_test_case 'link' do
    data(
      "empty"     => ["", false, ''],
      "garbage"   => ["abc", false, 'abc'],
      "\\ 1"      => ["\\\\[foo", true, 'foo'],
      "\\ 2"      => ["\\\\](foo)", true, ''],
      "\\ 3"      => ["]\\(foo)", true, '\\(foo)'],
      "\\ 4"      => ["](f\\)oo)", true, ''],
      "["         => ['foo [', true, ''],
      "!["        => ['foo ![', true, ''],
      "]"         => ['foo]', true, ''],
      "][]"       => ['foo][]', true, ''],
      "dempty"    => ['foo]()', true, ''],
      "dest bare" => ['foo](bar)', true, ''],
      "dest ()"   => ['foo](b(a(r)))', true, ''],
      "dest (+)"  => ['foo](b(a(r))', true, '(b(a(r))'],
      "dest (-)"  => ['foo](b(a(r))))', true, ')'],
      "dest (ok)" => ['foo](b(a\\(r))', true, ''],
      "dest <>"   => ['foo](<bar>)', true, ''],
      "dest <()>" => ['foo](<(bar)>)', true, ''],
      "dest <\\>" => ['foo](<\\>>)', true, ''],
      "title 1"   => ["foo]('bar')", true, ''],
      "title 2"   => ['foo]("bar")', true, ''],
      "title 3"   => ['foo](bar (baz))', true, ''],
      "titleng"   => ['foo](<bar>"baz")', true, '(<bar>"baz")'], # https://github.com/commonmark/cmark/issues/229
      "ref"       => ['foo][bar]', true, '[bar]']
    )

    test 'EXPR' do |(src, expected, remain)|
      re  = /#{Optdown::EXPR}\g<link>/o
      assert_equal expected, !!re.match?(src)
      if expected then
        md = re.match src
        assert_equal remain, md.post_match
      end
    end
  end

  sub_test_case 'raw html' do
    data(
      "empty"   => ["", false],
      "garbage" => ["abc", false],
      "open"    => ['<foo />', true],
      "close"   => ['</foo>', true],
      "comment" => ['<!-- foo -->', true],
      "XML"     => ['<?xml ?>', true],
      "doctype" => ['<!DOCTYPE html>', true],
      "cdata"   => ['<![CDATA[<foo> ]]>', true],
      "attr0"   => ['<a x=0>', true],
      "attr1"   => ["<a x='1'>", true],
      "attr2"   => ['<a x="2">', true],
      "nl"      => ["<p\nid=1>", true],
      "lack>"   => ['<a href=', false],
      "lack'"   => [%,<a x='1">,, false],
      "missing" => ['<![CDATA[foo ]>', false],
    )
    check(/#{Optdown::EXPR}\g<tag>/o)
  end
end
