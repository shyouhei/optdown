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

require_relative 'flanker'
require_relative 'token'

# @see http://spec.commonmark.org/0.28/#emphasis-and-strong-emphasis
module Optdown::Emphasis

  # Emphasis of `*`, `**`, `***`, ...
  class Aster < Optdown::Flanker

    # > A single  `*` character can  open emphasis iff (if  and only if)  it is
    # > part of a left-flanking delimiter run.
    #
    # @see   http://spec.commonmark.org/0.27/#emphasis-and-strong-emphasis
    # @param tok [Optdown::Token] token in question
    # @return    [true]  it is.
    # @return    [false] it isn't.
    def self.opener? tok
      return super && tok.yylval['flanker:run:*']
    end

    # > A single `*`  character can close emphasis  iff it is part  of a right-
    # > flanking delimiter run.
    #
    # @see   http://spec.commonmark.org/0.27/#emphasis-and-strong-emphasis
    # @param tok [Optdown::Token] token in question
    # @return    [true]  it is.
    # @return    [false] it isn't.
    def self.closer? tok
      return super && tok.yylval['flanker:run:*']
    end

    attr_reader :level # @return [Integer] nesting.

    def initialize open, body, close
      @level    = open.to_s.length
      @children = body
    end
  end

  # Emphasis of `_`, `__`, `___`, ...
  #
  # @note this is complicated than Aster.
  class Under < Optdown::Flanker

    # > A single  `_` character  can open emphasis  iff it is  part of  a left-
    # > flanking  delimiter run  and either  (a) not  part of  a right-flanking
    # > delimiter run or (b) part of a right-flanking delimiter run preceded by
    # > punctuation.
    #
    # @see   http://spec.commonmark.org/0.28/#emphasis-and-strong-emphasis
    # @param tok [Optdown::Flanker::Token] token in question
    # @return    [true]  it is.
    # @return    [false] it isn't.
    def self.opener? tok
      return false unless super
      md = tok.yylval
      return false unless md['flanker:run:_']
      return false unless md['flanker:left']
      return true  unless md['flanker:right']                     # (a)
      return %r/#{Optdown::EXPR}\g<PUNCT>\z/o.match? md.pre_match # (b)
    end

    # > A single `_`  character can close emphasis  iff it is part  of a right-
    # > flanking  delimiter run  and either  (a)  not part  of a  left-flanking
    # > delimiter run or (b) part of  a left-flanking delimiter run followed by
    # > punctuation.
    #
    # @see   http://spec.commonmark.org/0.28/#emphasis-and-strong-emphasis
    # @param tok [Optdown::Flanker::Run] token in question
    # @return    [true]  it is.
    # @return    [false] it isn't.
    def self.closer? tok
      return false unless super
      md = tok.yylval
      return false unless md['flanker:run:_']
      return false unless md['flanker:right']
      return true  unless md['flanker:left']                       # (a)
      return %r/#{Optdown::EXPR}\A\g<PUNCT>/o.match? md.post_match # (b)
    end

    attr_reader :level # @return [Integer] nesting.

    def initialize open, body, close
      @level    = open.to_s.length
      @children = body
    end
  end
end
