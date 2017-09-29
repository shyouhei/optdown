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

require_relative 'expr'
require_relative 'xprintf'

# @see http://spec.commonmark.org/0.28/#tabs
class Optdown::Matcher
  using Optdown::XPrintf
  using Module.new {
    refine Optdown::Matcher.singleton_class do
      alias construct new
    end

    refine Optdown::Matcher do
      attr_reader :logical, :map
    end
  }
  private_class_method :new

  attr_reader :last_match # @return [MatchData, nil] last match result, if any.

  # Main constructor.
  #
  # @param string [String]  source string.
  # @return       [Matcher] created instance.
  def self.new string
    tab_width = 4 # change? insane.
    pad       = 0
    map       = 0.chr * string.length
    logical   = string.gsub("\u0000", "\uFFFD")
    # rexp    = /#{Optdown::EXPR}(?<b4>(?~\g<EOL>|\g<TAB>))\g<TAB>/o
    rexp      = /(?<b4>[^\t\r\n]*)\t/o
    logical.gsub! rexp do
      b4              = $~[:b4]
      x               = $~.end :b4
      y               = tab_width - b4.length % tab_width
      z               = y - 1
      w               = 1.chr + 2.chr * z
      map[x + pad, 1] = w
      pad            += z
      next b4 + ' ' * y
    end
    return construct logical, map
  end

  # This method is faster than `inject(:+)`
  #
  # @param ary [Array<Matcher>] targets to join
  # @return    [Matcher]        joined matcher
  def self.join ary
    jl = ary.map(&:logical).join
    jm = ary.map(&:map).join
    return construct jl, jm
  end

  # (Ignore this method; you  can't call it by hand.  YARD  is so friendly that
  # it provides no way to hide #initialize.)
  def initialize logical, map
    @logical    = logical.freeze
    @map        = map.freeze
    @pos        = 0
    @last_match = nil
  end

  Empty = construct '', ''
  private_constant :Empty

  # Stringify.
  #
  # @return [String] the rendered string.
  def compile
    case @map when /\A\x0*\z/ then
      return @logical # fast path
    else
      # :FIXME: slow
      ret  = String.new encoding: @logical.encoding, capacity: length
      @logical.each_char.with_index do |c, i|
        case @map.getbyte i
        when 0 then ret << c
        when 1 then ret << "\t"
        # else # do nothing
        end
      end
      return ret
    end
  end

  alias to_s   compile
  alias to_str compile

  # Length, in logical columns.
  #
  # @return [Integer] how many logical columns are there.
  def length
    # @map  is a  binary string.  Its  length is  binary length,  which can  be
    # obtained O(1). On the other hand  @logical is a UTF-8 string whose length
    # needs be calculated in O(n).
    return @map.length
  end

  alias size length

  # Inspection.
  def pretty_print pp
    pp.text '@'
    compile.pretty_print pp
  end

  # Inspection.
  def inspect
    '@' + compile.inspect
  end

  # Checks if nothing is inside.
  #
  # @return [true]  it is.
  # @return [false] it isn't.
  def empty?
    @map.empty?
  end

  # Checks if the content is blank.  "Blank"-ness of a string is
  # defined in the spec so we take that definition.
  #
  # @see http://spec.commonmark.org/0.28/#blank-lines
  # @return [true]  it is.
  # @return [false] it isn't.
  def blank?
    match? %r/#{Optdown::EXPR}\G\g<LINE:blank>*\z/o
  end

  # Match, ignoring tabs
  #
  # @param rexp [Regexp]    pattern to consider.
  # @return     [MatchData] successful match.
  # @return     [nil]       failure in match.
  def match rexp
    _, ret = match_internal rexp
    return ret
  end

  # Tries to match the given pattern at  the current position. No seek, also no
  # MatchData generation.
  #
  # @param rexp [Regexp] pattern to consider.
  # @return     [true]   successful match.
  # @return     [false]  failure in match.
  def match? rexp
    return @logical.match? rexp, @pos
  end

  # Same as `match?(/\G\z/)`
  #
  # @return [true]  end of string.
  # @return [false] not yet.
  def eos?
    return match? %r/\G\z/
  end

  # Read until the end of string (or leftmost n characters, whichever reached
  # first).
  #
  # @param n [Integer] characters to read.
  # @return  [String]  what was read.
  def read n = length
    if @pos == 0 and n == length then
      # fast path
      ret = dup
      @pos = length
    else
      ret   = slice @pos, n
      @pos += ret.length
    end
    return ret
  end

  # Seek back from current position.
  #
  # @param n [Integer] logical columns to back.
  # @note              There is no method named getc.
  def ungetc n = 1
    @pos -= n
    @pos = @pos.clamp 0, length
  end

  # Read until the end of line.
  #
  # @param rs [Regexp] newline pattern, like `$/`
  # @return   [String] what was read.
  def gets rs = /#{Optdown::EXPR}\g<EOL>/o
    beg_, md = match_internal rs
    if md then
      end_ = md.end 0
      return slice beg_...end_
    else
      return read
    end
  end

  # Read until the regexp matches.
  #
  # @param re  [Regexp] pattern.
  # @return    [String] prematch.
  def advance re
    beg_, md = match_internal re
    if md then
      end_ = md.begin 0
      prematch = slice beg_...end_
      return prematch, md
    else
      return read
    end
  end

  # `md` is a MatchData generated by some other methods of self.  Given such md
  # and a capture name, return the corresponding substring.
  #
  # @param md   [MatchData]       position info.
  # @param name [String, Integer] capture name, or capture #.
  # @return     [String]          substring for `md`'s `name`.
  # @return     [nil]             no match.
  def get_anchor md = @last_match, name
    return nil unless md
    # this is faster than calling slice
    beg_, end_ = md.offset name
    return nil unless beg_
    substr = md[name]
    submap = @map[beg_...end_]
    submap.sub! %r/\A\x2+/ do |i| 0.chr * i.length end
    return self.class.construct substr, submap
  end

  alias [] get_anchor

  # Poor man's simulation of String#split
  #
  # @param  sep   [Regexp]  split separator.
  # @param  limit [Integer] split limit.
  # @return       [Array<Matcher>] self, split.
  def split sep, limit = 0
    a   = []
    return a if empty?
    sep = Regexp.quote sep unless sep.kind_of? Regexp
    pos = @pos
    max = @map.size
    while pos < max do
      break if limit > 0 and a.size >= limit - 1
      md = @logical.match sep, pos
      break unless md

      beg_, end_ = md.offset 0
      if beg_ == end_ then
        str  = slice pos
        pos += 1
      else
        str = slice pos...beg_
        pos = end_
      end
      a << str

      m = md.size - 1
      1.upto m do |n|
        beg_, end_ = md.offset n
        str        = slice beg_...end_
        a << str
      end
    end
    last = slice pos..max
    a << last

    if limit == 0 then
      a.pop while a.last&.empty?
    end
    return a
  end

  private

  def match_internal rexp
    beg         = @pos
    md          = @logical.match rexp, beg
    @last_match = md
    @pos        = md.end 0 if md
    return beg, md
  end

  # @overload slice(range)
  #
  #   generate a substring of the given range.
  #
  #   @param  range [Range]   a range of the string.
  #   @return       [Matcher] requested substring.
  #
  # @overload slice(from, to)
  #
  #   generate a substring of the given range.
  #
  #   @param  from [Integer] staring index of the requested substring.
  #   @param  to   [Integer] terminating index of the requested substring.
  #   @return      [Matcher] requested substring.
  def slice *argv
    subl = @logical[*argv]
    subm = @map[*argv]
    # we need to take care when cutting a middle of a tab.
    subm.sub! %r/\A\x2+/ do |i| 0.chr * i.length end
    return self.class.construct subl, subm
  end

  public

  # This is  the refinements that  refines Regexp#===.  Should  be `using`-ed
  # beforehand.
  module Refinements
    refine Regexp do
      private

      alias rb_reg_eqq ===

      public

      # Case equality.
      #
      # @param other [Optdown::Scanner] scanable string.
      # @return      [true]             successful match.
      # @return      [false]            failure in match.
      def === other
        case other when Optdown::Matcher then
          return other.match self
        else
          return rb_reg_eqq other
        end
      end
    end
  end
end
