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

# This module is a Refinements.  It introduces Object#deeply_frozen_copy.
module Optdown::DeeplyFrozen
  refine Object do

    private

    # Recursively freeze everything inside, no matter what the given object is.
    #
    # @param  x [Object] anything.
    # @return   [Object] deeply frozen copy of x.
    # @note              @shyouhei recommends  you to read  the implementation.
    #                    This is fascinating.
    def deeply_frozen_copy_of x
      str = Marshal.dump x
      ary = Array.new
      ret = Marshal.load str, ->(y) { ary.push y; y }
      ary.each(&:freeze)
      return ret
    end

    public

    # Recursively freeze everything inside, no matter what it is.
    #
    # @return   [Object] deeply frozen copy of self.
    def deeply_frozen_copy
      return deeply_frozen_copy_of self
    end
  end
end
