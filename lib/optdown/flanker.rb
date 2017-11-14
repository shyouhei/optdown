#! /your/favourite/path/to/ruby
# -*- mode: ruby; coding: utf-8; indent-tabs-mode: nil; ruby-indent-level: 2 -*-
# -*- frozen_string_literal: false -*-
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

# Flanker  is the  mother  of  all inlines  who  nest.   Those inlines  include
# emphasis, links,  strike-throughs (,  and possibly  "smarty pants").   On the
# other hand  for instance HTML  tags are not;  they would never  include other
# inlines.
class Optdown::Flanker

  attr_reader :children # @return [Inline] child nodes.

  class << self

    # @see http://spec.commonmark.org/0.27/#phase-2-inline-structure
    def parse ary, ctx
      #
      #  " ... foo ... **bar* baz*** ... "
      #        ^       ^    ^
      #        i       k    j
      #
      n = ary.length
      i = 0
      while i < n do
        j, x = find_closer ary, i
        if j then
          k = find_opener ary, j, x
          if k then
            x.reduce ary, k, j, ctx
            i = k + 1
          else
            i = j + 1
          end
        else
          i += 1
        end
      end
    end

    def find_closer ary, i
      i.upto ary.length do |j|
        next unless t = ary[j]
        next unless Optdown::Token === t
        next unless t.yylex == :flanker
        next unless t.yylval['flanker:right']
        [
          Optdown::Emphasis::Under,
          Optdown::Emphasis::Aster,
          Optdown::Strikethrough,
          # other flankers to come, maybe smartypants?
        ].each do |k|
          return j, k if k.closer? t
        end
      end
      return nil
    end

    def find_opener ary, i, k
      t = ary[i]
      i.downto 0 do |j|
        next unless tt = ary[j]
        next unless Optdown::Token === tt
        next unless tt.yylex == :flanker
        next unless tt.yylval['flanker:left']
        next unless k.opener? tt
        next unless k.matching? tt, t
        return j
      end
      return nil
    end

    # > Emphasis begins with a delimiter that can open emphasis and ends with a
    # > delimiter that  can close  emphasis, and that  uses the  same character
    # > (`_`  or  `*`) as  the  opening  delimiter.   The opening  and  closing
    # > delimiters  must belong  to separate  delimiter  runs.  If  one of  the
    # > delimiters  can both  open  and close  emphasis, then  the  sum of  the
    # > lengths  of  the delimiter  runs  containing  the opening  and  closing
    # > delimiters must not be a multiple of 3.
    #
    # @see http://spec.commonmark.org/0.27/#emphasis-and-strong-emphasis
    def matching? opener, closer
      return false unless opener.yylex == closer.yylex
      # "must belong to separate run" constraint
      return false if opener == closer

      # intuitive conditions
      return false unless opener?(opener)
      return false unless closer?(closer)

      o = opener.to_s
      c = closer.to_s

      # same character constraint
      return false unless o[0] == c[0]

      # "If one of the delimiters can both open and close emphasis..." part
      if opener?(closer) || closer?(opener) then
        return ((o.length + c.length) % 3) != 0
      end

      # reaching here indicates the arguments match.
      return true
    end

    def reduce tokens, iopen, iclose, ctx
      # Either t1 or t2 (or maybe both) would completely be consumed here, but
      # there might be at most one flanker that would be left-over.
      range  = iopen..iclose
      body   = tokens[range].compact
      t1     = body.shift
      t2     = body.pop
      eat    = [t1, t2].map{|t| t.to_s.length }.min
      t3, t4 = leftover t1, eat
      t5, t6 = leftover t2, eat
      recur body, ctx
      node   = new t3, body, t5
      tokens.fill nil, range
      if node then
        tokens[iopen, 3] = [t4, node, t6]
      else
        tokens[iopen, 3] = [t4, t3, body, t5, t6] # includes nil
      end
      tokens.compact!
    end

    def recur ary, ctx
      ary.compact!
      return Optdown::Inline.new ary, ctx
    end

    def leftover tok, eat
      str   = tok.to_s[0...eat]
      run   = tok.to_s[eat..-1]
      eaten = Optdown::Token.new :cdata, str
      if run.nil? or run.empty?
        return eaten, nil
      else
        left  = Optdown::Token.new tok.yylex, tok.yylval, run
        return eaten, left
      end
    end

    # routines shared among children

    def opener? tok
      return false unless Optdown::Token === tok
      return false unless tok.yylex == :flanker
      return false unless tok.yylval['flanker:left']
      return true
    end

    def closer? tok
      return false unless Optdown::Token === tok
      return false unless tok.yylex == :flanker
      return false unless tok.yylval['flanker:right']
      return true
    end
  end
end
