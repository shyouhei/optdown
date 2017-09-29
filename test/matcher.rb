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

class TC_Matcher < Test::Unit::TestCase
  setup do
    @subject = Optdown:: Matcher.new <<~'end'
      Lorem ipsum dolor sit amet,
      consectetur adipiscing elit,
      sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
    end
  end

  test ".new" do
    assert_instance_of Optdown::Matcher, @subject
  end

  sub_test_case ".join" do
    setup do
      ary = ["foo\n", "bar\n", "baz\n"].map {|i| Optdown::Matcher.new i}
      @subject = Optdown::Matcher.join ary
    end

    test ".join" do
      assert_instance_of Optdown::Matcher, @subject
      assert_equal "foo\nbar\nbaz\n", @subject.to_s
    end
  end

  sub_test_case "#compile" do
    data(
      "empty" => "",
      "blank" => "  \r\n",
      "tab"   => "\t",
      "long"  => "\t" * 32768,
      "bq"    => ">\tfoo",
      "li"    => "-\tfoo",
      "2li"   => " -\tx\t\n" * 2,
      "mix"   => "\tfoo\r\nbar\r\nba\tz",
    )

    test "#compile" do |str|
      subject = Optdown::Matcher.new str
      assert_equal str, subject.compile
    end
  end

  sub_test_case "#length" do
    data(
      0  => [0, ''],
      3  => [3, 'foo'],
      4  => [4, "foo\t"],
      5  => [5, "fo\to"],
      6  => [6, "f\too"],
      7  => [7, "\tfoo"],
      8  => [8, "foo\nfoo\n"],
      9  => [9, "foo\nfoo\t\n"],
      10 => [10, "foo\nfo\to\n"],
      11 => [11, "foo\nf\too\n"]
    )

    test "#length" do |(n, str)|
      subject = Optdown::Matcher.new str
      if n != subject.length
        p [str, subject]
      end
      assert_equal n, subject.length
    end
  end

  sub_test_case "#empty?" do
    data(
      "yes" => [true, ""],
      "no"  => [false, "foo"]
    )

    test "#empty?" do |(expected, src)|
      subject = Optdown::Matcher.new src
      assert_equal expected, subject.empty?
    end
  end

  test "#match?" do
    assert_true  @subject.match?(/\A/)
    assert_true  @subject.match?(/\w+/)
    assert_true  @subject.match?(/Lorem/)
    assert_false @subject.match?(/\G\W/)
  end

  test "#match" do
    assert_equal '',      @subject.match(/\G\A/)[0]
    assert_equal 'Lorem', @subject.match(/\G\w+/)[0]
    assert_equal ' ',     @subject.match(/\G\W+/)[0]
    assert_equal 'ipsum', @subject.match(/\G\w+/)[0]
    assert_equal ' ',     @subject.match(/\G\W+/)[0]
    assert_equal 'dolor', @subject.match(/\G\w+/)[0]
    assert_equal ' ',     @subject.match(/\G\W+/)[0]
    assert_equal 'sit',   @subject.match(/\G\w+/)[0]
    assert_equal ' ',     @subject.match(/\G\W+/)[0]
    assert_equal 'amet',  @subject.match(/\G\w+/)[0]
    assert_equal ',',     @subject.match(/\G\W/)[0]
    assert_equal '',      @subject.match(/\G$/)[0]
    assert_equal "\n",    @subject.match(/\G\W+/)[0]
    assert_equal '',      @subject.match(/\G^/)[0]
    assert_equal nil,     @subject.match(/\G\z/)
  end

  test "#eos?" do
    assert_false @subject.eos?
    @subject.gets
    assert_false @subject.eos?
    @subject.gets
    assert_false @subject.eos?
    @subject.gets
    assert_true @subject.eos?
    @subject.gets
    assert_true @subject.eos?
  end

  test "#read" do
    assert_equal 'Lorem ip', @subject.read(8).to_s
    assert_equal 'sum dolo', @subject.read(8).to_s
    assert_equal 'r sit am', @subject.read(8).to_s
    assert_equal "et,\n",    @subject.gets.to_s
  end

  sub_test_case "#gets" do
    test "#gets" do
      assert_equal <<~'end', @subject.gets.to_s
        Lorem ipsum dolor sit amet,
      end
      assert_equal <<~'end', @subject.gets.to_s
        consectetur adipiscing elit,
      end
      assert_equal <<~'end', @subject.gets.to_s
        sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
      end
      assert_equal '', @subject.gets.to_s
    end
  end

  test "#advance" do
    assert_equal ['Lorem', ' '], @subject.advance(/(?<=m) /).map(&:to_s)
  end

  test "#get_anchor" do
    md1 = @subject.match(/\w+/)
    md2 = @subject.match(/(?<ipsum>\w+)/)
    assert_equal 'ipsum', @subject['ipsum'].to_s
    assert_equal 'Lorem', @subject[md1, 0].to_s
    assert_equal 'ipsum', @subject[md2, 0].to_s
  end

  sub_test_case "#split" do
    data(
      "empty1" => ['', [/./], []],
      "empty2" => ['', [/$/], []],
      "empty3" => ['', [',', -1], []],
      "sp"     => ["   a \t  b \n  c", [/\s+/], ["", "a", "b", "c"]],
      "//"     => ["hi there", [//], %w[h i \  t h e r e]],
      "()"     => ["1:2:3", [/(:)()()/, 2], ["1", ":", "", "", "2:3"]],
      "limit0" => ["1,2,,3,4,,", [','], ["1", "2", "", "3", "4"]],
      "limit+" => ["1,2,,3,4,,", [',', 4], ["1", "2", "", "3,4,,"]],
      "limit-" => ["1,2,,3,4,,", [',', -4], ["1", "2", "", "3", "4", "", ""]]
    )

    test '#split' do |(src, argv, expected)|
      subject = Optdown::Matcher.new src
      actual  = subject.split(*argv)
      assert_instance_of Array, actual
      actual.each {|i| assert_instance_of Optdown::Matcher, i }
      assert_equal expected, actual.map(&:to_s)
    end
  end

  class TestRefinemenrs < TC_Matcher
    using Optdown::Matcher::Refinements

    test '#===' do
      loop do
        case @subject
        when /\n/        then break
        when /(L.+?)\s+/ then assert_equal 'Lorem', @subject.last_match[1]
        when /(i.+?)\s+/ then assert_equal 'ipsum', @subject.last_match[1]
        when /(\w+),/    then assert_equal 'amet',  @subject.last_match[1]
        when /\w+\s+/    then next # skip
        end
      end
    end

    test 'other class' do
      case "foo"
      when Time  then flunk
      when /bar/ then flunk
      when /foo/ then refute nil
      else flunk
      end
    end
  end
end
