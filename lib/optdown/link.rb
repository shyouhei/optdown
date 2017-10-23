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

require_relative 'flanker'
require_relative 'link_title'

# @see http://spec.commonmark.org/0.28/#links
module Optdown::Link
  # Links are  different from  other flankers  in one  point.  Its  opening and
  # closing characters are different.

  attr_reader :attr # return [Hash] description TBW.

  # (see Optdown::Flanker.parse)
  def self.parse ary, ctx
    ary.each_with_index do |t, i|
      next unless Optdown::Token === t
      next unless t.yylex == :link
      next unless t.yylval['a:right']
      i.downto 0 do |j|
        tt = ary[j]
        next unless Optdown::Token === tt
        next unless tt.yylex == :link
        if tt.yylval['a:left'] then
          A.reduce ary, j, i, ctx
          break
        elsif tt.yylval['img:left'] then
          Img.reduce ary, j, i, ctx
          break
        end
      end
    end
  end

  private

  def initialize argh
    @attr = argh
    if link = argh[:link] then
      @attr[:dest]  = link.dest
      @attr[:title] = link.title
    elsif tok = argh[:inline] then
      @attr[:dest]  = unparen_dest tok
      @attr[:title] = unparen_title tok
    end
    @children = argh[:label]
  end

  def unparen_title tok
    md    = tok.yylval
    title = md['link:title:2j'] || md['link:title:1j'] || md['link:title:0j']
    return nil unless title
    return Optdown::LinkTitle.new title
  end

  def unparen_dest tok
    md   = tok.yylval
    dest = md['link:dest:a'] || md['link:dest:b']
    return nil unless dest
    obj = Optdown::LinkTitle.new dest
    return obj.plain
  end

  def reduce_nothing tokens, iopen, iclose
    tokens[iopen]  = tokens[iopen].cdataify
    tokens[iclose] = tokens[iclose].cdataify
  end

  def reduce_ref tokens, iopen, iclose, ctx
    md     = tokens[iclose].yylval
    cand   = md['link:label']
    cand ||= /#{Optdown::EXPR}\g<link:label>\z/o.match(md.pre_match + ']')
    link   = ctx.find_link_by cand
    return reduce_nothing tokens, iopen, iclose unless link
    ifill = iclose
    if md['link:label'] then
      # eat the follwing label here
      ifill += 1
      ifill += 1 while tokens[ifill]&.to_s&.!= ']'
    end
    range  = iopen..iclose
    body   = tokens[range].compact
    body.shift
    body.pop
    tokens.fill nil, iopen..ifill
    child = recur body, ctx
    tokens[iopen] = new label: child, link: link
  end

  def reduce_inline tokens, iopen, iclose, ctx
    range  = iopen..iclose
    body   = tokens[range].compact
    body.shift
    t      = body.pop
    tokens.fill nil, range
    child = recur body, ctx
    tokens[iopen] = new label: child, inline: t
  end

  public

  # (see Optdown::Flanker.reduce)
  def reduce tokens, iopen, iclose, ctx
    if tokens[iclose].yylval['a:inline'] then
      reduce_inline tokens, iopen, iclose, ctx
    else
      reduce_ref tokens, iopen, iclose, ctx
    end
  end

  # @see http://spec.commonmark.org/0.28/#images
  class Img < Optdown::Flanker
    include Optdown::Link
    extend  Optdown::Link
  end

  # @see http://spec.commonmark.org/0.28/#links
  class A < Optdown::Flanker
    include Optdown::Link
    extend  Optdown::Link

    class << self

      # > links may not contain other links, at any level of nesting.
      def reduce tokens, iopen, iclose, ctx
        if (iopen..iclose).any? {|i| has_link? tokens[i] } then
          reduce_nothing tokens, iopen, iclose
        else
          super
        end
      end

      private

      def has_link? tok
        case tok
        when self then
          return true
        when Optdown::Flanker then
          return has_link? tok.children
        when Optdown::Inline then
          return tok.children.any? {|i| has_link? i }
        else
          return false
        end
      end
    end
  end
end
