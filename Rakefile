#! /your/favourite/path/to/rake
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

require 'rubygems'
require 'bundler/setup'
Bundler.setup :development, :test
require 'rake'
require 'yard'
require 'rake/testtask'
require 'rubocop/rake_task'

YARD::Rake::YardocTask.new
RuboCop::RakeTask.new

task default: :test
task spec: :test
desc "run tests"
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb'] - ['test/test_helper.rb']
  t.warning    = true
end

desc "pry console"
task :pry do
  require_relative 'lib/optdown'
  require 'pry'
  Pry.start
end
task c: :pry
task console: :pry

desc "run script under project"
task :runner do
  require_relative 'lib/optdown'
  ARGV.shift while ARGV.first != 'runner'
  ARGV.shift
  eval ARGF.read, TOPLEVEL_BINDING, '(ARGF)'
end

file 'lib/optdown/html5entity.rb' => 'lib/optdown/html5entity.erb' do |t|
  require 'open-uri'
  require 'erb'
  require 'json'
  URI('https://www.w3.org/TR/html5/entities.json').open do |fp|
    # For this use of create_additions option:
    # @see https://www.ruby-lang.org/en/news/2013/02/22/json-dos-cve-2013-0269/
    entities = JSON.parse fp.read, create_additions: false
    path = t.prerequisites.first
    src = File.read path
    erb = ERB.new src, nil, '%-'
    erb.filename = path
    b = TOPLEVEL_BINDING.dup
    b.local_variable_set 'entities', entities
    dst = erb.result b
    File.write t.name, dst
  end
end

task :submodule do
  sh 'git submodule update --init --recursive'
end

file 'test/spec.json' => 'submodules/CommonMark/spec.txt' do |f|
  sh 'make -C submodules/CommonMark spec.json'
  rm_r 'submodules/CommonMark/test/__pycache__'
  mv 'submodules/CommonMark/spec.json', f.name
end

task test: 'test/spec.json'
task prepare: :submodule
task prepare: 'test/spec.json'
