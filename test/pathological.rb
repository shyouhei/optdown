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
require 'json'

# @see https://github.com/github/cmark/blob/master/test/pathological_tests.py
class TC_Pathological < Test::Unit::TestCase
  @@subject = Optdown::HTMLRenderer.new
  @@parser  = Optdown::Parser.new
  data(
    'nested strong emph' => [
      ("*a **a " * 1024) + "b" + (" a** a*" * 1024),
      %r{(<em>a <strong>a ){1024}b( a</strong> a</em>){1024}}
    ],
    'many emph closers with no openers' => [
      ("a_ " * 1024),
      /(a_ ){1023}a_/
    ],
    'many emph openers with no closers' => [
      ("_a " * 1024),
      /(_a ){1023}_a/
    ],
    'many link closers with no openers' => [
      ("a]" * 1024),
      /(a\]){1024}/
    ],
    'many link openers with no closers' => [
      ("[a" * 1024),
      /(\[a){1024}/
    ],
    'mismatched openers and closers' => [
      ("*a_ " * 1024),
      /(\*a_ ){1023}\*a_/
    ],
    'openers and closers multiple of 3' => [
      ("a**b" + ("c* " * 1024)),
      /a\*\*b(c\* ){1023}c\*/
    ],
    'link openers and emph closers' => [
      ("[ a_" * 1024),
      /(\[ a_){1024}/
    ],
    'hard link/emph case' => [
      "**x [a*b**c*](d)",
      %r{\*\*x <a href="d">a<em>b\*\*c</em></a>}
    ],
    'nested brackets' => [
      ("[" * 1024) + "a" + ("]" * 1024),
      /\[{1024}a\]{1024}/
    ],
    'nested block quotes' => [
      (("> " * 1024) + "a"),
      /(<blockquote>\n){1024}/
    ],
    'U+0000 in input' => [
      "abc\u0000de\u0000",
      /abc\ufffd?de\ufffd?/
    ],
    'backticks' => [
      (1..1024).map{|x| "e" + "`" * x }.join(""),
      %r{^<p>[e`]*</p>\n$}
    ],
  )

  test '#render' do |(src, expected)|
    dom      = @@parser.parse src
    actual   = @@subject.render dom
    assert_match expected, actual
  end
end
