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

# require 'logger' # intentionally left not required.

# This module  is a Refinements.  It  extends several existing methods  so that
# they can have printf-like format specifiers.
module Optdown::XPrintf

  refine Kernel do

    # Utility logger + printf function.  It  is quite hard to think of loggings
    # that only concern fixed strings.  @shyouhei really doesn't understand why
    # this is not a canon.
    #
    # @param logger  [Logger] log destination.
    # @param lv      [Symbol] log level.
    # @param fmt     [String] printf-format string.
    # @param va_args [Array]  anything.
    def lprintf logger, lv, fmt, *va_args
      str = fmt % va_args
      logger.send lv, str
    end

    # Utility raise + printf function.  It is quite hard to think of exceptions
    # that only concern fixed strings.  @shyouhei really doesn't understand why
    # this is not a canon.
    #
    # @param exc     [Class]  exception class.
    # @param fmt     [String] printf-format string.
    # @param va_args [Array]  anything.
    def rprintf exc, fmt, *va_args
      msg = fmt % va_args
      raise exc, msg, caller # caller() == caller(1) i.e. skip this frame.
    end

    # Utility warn  + printf function.  It  is quite hard to  think of warnings
    # that only concern fixed strings.  @shyouhei really doesn't understand why
    # this is not a canon.
    #
    # @param fmt     [String] printf-format string.
    # @param va_args [Array]  anything.
    def wprintf fmt, *va_args
      msg = fmt % va_args
      Warning.warn msg
    end
  end
end
