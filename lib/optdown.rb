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
;

module Optdown
  VERSION = 1

  require_relative 'optdown/html5entity'
  require_relative 'optdown/deeply_frozen'
  require_relative 'optdown/always_frozen'
  require_relative 'optdown/expr'
  require_relative 'optdown/xprintf'
  require_relative 'optdown/matcher'
  require_relative 'optdown/token'
  require_relative 'optdown/flanker'
  require_relative 'optdown/emphasis'
  require_relative 'optdown/link'
  require_relative 'optdown/strikethrough'
  require_relative 'optdown/autolink'
  require_relative 'optdown/raw_html'
  require_relative 'optdown/code_span'
  require_relative 'optdown/entity'
  require_relative 'optdown/escape'
  require_relative 'optdown/newline'
  require_relative 'optdown/inline'
  require_relative 'optdown/paragraph'
  require_relative 'optdown/table'
  require_relative 'optdown/setext_heading'
  require_relative 'optdown/atx_heading'
  require_relative 'optdown/indented_code_block'
  require_relative 'optdown/fenced_code_block'
  require_relative 'optdown/blockhtml'
  require_relative 'optdown/list_item'
  require_relative 'optdown/list'
  require_relative 'optdown/blockquote'
  require_relative 'optdown/link_def'
  require_relative 'optdown/thematic_break'
  require_relative 'optdown/blocklevel'
  require_relative 'optdown/parser'
  require_relative 'optdown/renderer'
  require_relative 'optdown/plugins/html_renderer.rb'
end
