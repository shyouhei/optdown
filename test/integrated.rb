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

class TC_Integrated < Test::Unit::TestCase
  @@subject = Optdown::HTMLRenderer.new
  @@parser  = Optdown::Parser.new
  path      = File.expand_path 'spec.json', __dir__
  File.open path, 'r:utf-8' do |fp|
    # For this use of create_additions option:
    # @see https://www.ruby-lang.org/en/news/2013/02/22/json-dos-cve-2013-0269/
    json = JSON.parse fp.read, create_additions: false
    skip = [
      # known failing ones due to GH extensions
      579, 582, 583,
    ]
    hash = {}
    json.each do |h|
      next if skip.include? h['example']
      key = sprintf 'example %d at spec.json:%d', h['example'], h['start_line']
      hash[key] = h
    end
    data hash
  end

  test '#render' do |h|
    src      = h['markdown']
    expected = h['html']
    dom      = @@parser.parse src
    actual   = @@subject.render dom
    if expected != actual
      require 'pp'
      pp dom
    end
    assert_equal expected, actual
  end

  sub_test_case 'GFM plugins' do
    data(
      'table1' => [ <<~'begin', <<~'end' ],
        | foo | bar |
        | --- | --- |
        | baz | bim |
      begin
        <table>
        <thead>
        <tr>
        <th>foo</th>
        <th>bar</th>
        </tr>
        </thead>
        <tbody>
        <tr>
        <td>baz</td>
        <td>bim</td>
        </tr></tbody></table>
      end

      'table2' => [ <<~'begin', <<~'end' ],
        | abc | defghi |
        :-: | -----------:
        bar | baz
      begin
        <table>
        <thead>
        <tr>
        <th align="center">abc</th>
        <th align="right">defghi</th>
        </tr>
        </thead>
        <tbody>
        <tr>
        <td align="center">bar</td>
        <td align="right">baz</td>
        </tr></tbody></table>
      end

      'table3' => [ <<~'begin', <<~'end' ],
        | f\|oo  |
        | ------ |
        | b `\|` az |
        | b **\|** im |
      begin
        <table>
        <thead>
        <tr>
        <th>f|oo</th>
        </tr>
        </thead>
        <tbody>
        <tr>
        <td>b <code>\|</code> az</td>
        </tr>
        <tr>
        <td>b <strong>|</strong> im</td>
        </tr></tbody></table>
      end

      'table4' => [ <<~'begin', <<~'end' ],
        | abc | def |
        | --- | --- |
        | bar | baz |
        > bar
      begin
        <table>
        <thead>
        <tr>
        <th>abc</th>
        <th>def</th>
        </tr>
        </thead>
        <tbody>
        <tr>
        <td>bar</td>
        <td>baz</td>
        </tr></tbody></table>
        <blockquote>
        <p>bar</p>
        </blockquote>
      end

      'table5' => [ <<~'begin', <<~'end' ],
        | abc | def |
        | --- | --- |
        | bar | baz |
        bar

        bar
      begin
        <table>
        <thead>
        <tr>
        <th>abc</th>
        <th>def</th>
        </tr>
        </thead>
        <tbody>
        <tr>
        <td>bar</td>
        <td>baz</td>
        </tr>
        <tr>
        <td>bar</td>
        <td></td>
        </tr></tbody></table>
        <p>bar</p>
      end

      'table6' => [ <<~'begin', <<~'end' ],
        | abc | def |
        | --- |
        | bar |
      begin
        <p>| abc | def |
        | --- |
        | bar |</p>
      end

      'table7' => [ <<~'begin', <<~'end' ],
        | abc | def |
        | --- | --- |
        | bar |
        | bar | baz | boo |
      begin
        <table>
        <thead>
        <tr>
        <th>abc</th>
        <th>def</th>
        </tr>
        </thead>
        <tbody>
        <tr>
        <td>bar</td>
        <td></td>
        </tr>
        <tr>
        <td>bar</td>
        <td>baz</td>
        </tr></tbody></table>
      end

      'table8' => [ <<~'begin', <<~'end' ],
        | abc | def |
        | --- | --- |
      begin
        <table>
        <thead>
        <tr>
        <th>abc</th>
        <th>def</th>
        </tr>
        </thead></table>
      end

      'task1' => [ <<~'begin', <<~'end' ],
        - [ ] foo
        - [x] bar
      begin
        <ul>
        <li><input disabled="" type="checkbox"> foo</li>
        <li><input checked="" disabled="" type="checkbox"> bar</li>
        </ul>
      end

      'task2' => [ <<~'begin', <<~'end' ],
        - [x] foo
          - [ ] bar
          - [x] baz
        - [ ] bim
      begin
        <ul>
        <li><input checked="" disabled="" type="checkbox"> foo
        <ul>
        <li><input disabled="" type="checkbox"> bar</li>
        <li><input checked="" disabled="" type="checkbox"> baz</li>
        </ul>
        </li>
        <li><input disabled="" type="checkbox"> bim</li>
        </ul>
      end

      'del1' => [ <<~'begin', <<~'end' ],
        ~Hi~ Hello, world!
      begin
        <p><del>Hi</del> Hello, world!</p>
      end

      'del2' => [ <<~'begin', <<~'end' ],
        This ~text~~~~ is ~~~~curious~.
      begin
        <p>This <del>text</del> is <del>curious</del>.</p>
      end

      'del3' => [ <<~'begin', <<~'end' ],
        This ~~has a

        new paragraph~~.
      begin
        <p>This ~~has a</p>
        <p>new paragraph~~.</p>
      end

      'url1' => [ <<~'begin', <<~'end' ],
        www.commonmark.org
      begin
        <p><a href="http://www.commonmark.org">www.commonmark.org</a></p>
      end

      'url2' => [ <<~'begin', <<~'end' ],
        Visit www.commonmark.org/help for more information.
      begin
        <p>Visit <a href="http://www.commonmark.org/help">www.commonmark.org/help</a> for more information.</p>
      end

      'url3' => [ <<~'begin', <<~'end' ],
        Visit www.commonmark.org.

        Visit www.commonmark.org/a.b.
      begin
        <p>Visit <a href="http://www.commonmark.org">www.commonmark.org</a>.</p>
        <p>Visit <a href="http://www.commonmark.org/a.b">www.commonmark.org/a.b</a>.</p>
      end

      'url4' => [ <<~'begin', <<~'end' ],
        www.google.com/search?q=Markup+(business)

        (www.google.com/search?q=Markup+(business))
      begin
        <p><a href="http://www.google.com/search?q=Markup+(business)">www.google.com/search?q=Markup+(business)</a></p>
        <p>(<a href="http://www.google.com/search?q=Markup+(business)">www.google.com/search?q=Markup+(business)</a>)</p>
      end

      'url5' => [ <<~'begin', <<~'end' ],
        www.google.com/search?q=(business))+ok
      begin
        <p><a href="http://www.google.com/search?q=(business))+ok">www.google.com/search?q=(business))+ok</a></p>
      end

      'url6' => [ <<~'begin', <<~'end' ],
        www.google.com/search?q=commonmark&hl=en

        www.google.com/search?q=commonmark&half;
      begin
        <p><a href="http://www.google.com/search?q=commonmark&amp;hl=en">www.google.com/search?q=commonmark&amp;hl=en</a></p>
        <p><a href="http://www.google.com/search?q=commonmark">www.google.com/search?q=commonmark</a>½</p>
      end

      'url7' => [ <<~'begin', <<~'end' ],
        www.commonmark.org/he<lp
      begin
        <p><a href="http://www.commonmark.org/he">www.commonmark.org/he</a>&lt;lp</p>
      end

      'url8' => [ <<~'begin', <<~'end' ],
        http://commonmark.org

        (Visit https://encrypted.google.com/search?q=Markup+(business))

        Anonymous FTP is available at ftp://foo.bar.baz.
      begin
        <p><a href="http://commonmark.org">http://commonmark.org</a></p>
        <p>(Visit <a href="https://encrypted.google.com/search?q=Markup+(business)">https://encrypted.google.com/search?q=Markup+(business)</a>)</p>
        <p>Anonymous FTP is available at <a href="ftp://foo.bar.baz">ftp://foo.bar.baz</a>.</p>
      end

      'url9' => [ <<~'begin', <<~'end' ],
        foo@bar.baz
      begin
        <p><a href="mailto:foo@bar.baz">foo@bar.baz</a></p>
      end

      'url10' => [ <<~'begin', <<~'end' ],
        hello@mail+xyz.example isn't valid, but hello+xyz@mail.example is.
      begin
        <p>hello@mail+xyz.example isn't valid, but <a href="mailto:hello+xyz@mail.example">hello+xyz@mail.example</a> is.</p>
      end

      'url11' => [ <<~'begin', <<~'end' ],
        a.b-c_d@a.b

        a.b-c_d@a.b.

        a.b-c_d@a.b-

        a.b-c_d@a.b_
      begin
        <p><a href="mailto:a.b-c_d@a.b">a.b-c_d@a.b</a></p>
        <p><a href="mailto:a.b-c_d@a.b">a.b-c_d@a.b</a>.</p>
        <p>a.b-c_d@a.b-</p>
        <p>a.b-c_d@a.b_</p>
      end
    )

    test '#render' do |(src, expected)|
      dom      = @@parser.parse src
      actual   = @@subject.render dom
      if expected != actual
        require 'pp'
        pp dom
      end
      assert_equal expected, actual
    end
  end
end
