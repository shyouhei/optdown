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

# By prepending  this module your class  gets frozen.  Instances of  your class
# can no longer be modifiable.  You cannot  but create a new instance to modify
# something.
#
# Due to ruby's language restriction this module has no public methods.
module Optdown::AlwaysFrozen
  private

  def self.included *;
    raise "#{self} must be prepended, not included"
  end

  private_class_method :included

  # Following  two method  definitions  are lexically  identical.  However  you
  # cannot merge them into one, because what `super` resolves to differs.

  def initialize_copy *;
    super
    freeze
  end

  def initialize *;
    super
    freeze
  end
end
