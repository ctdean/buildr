# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


require 'buildr/core/build'
require 'buildr/core/compile'
require 'buildr/java/tests'

module Buildr::Clojure
  # clojure.test framework
  #
  # Support the following options:
  # * :properties  -- Hash of system properties available to the test case.
  # * :environment -- Hash of environment variables available to the test case.
  # * :java_args   -- Arguments passed as is to the JVM.
  class ClojureTest < Buildr::TestFramework::Java
    include Buildr::Clojure::ClojureNamespace

    class << self
      def applies_to?(project) #:nodoc:
        !Dir[project.path_to(:src, :test, :clojure, '**/*.clj')].empty?
      end
    end

    # annotation-based group inclusion
    attr_accessor :group_includes

    # annotation-based group exclusion
    attr_accessor :group_excludes

    def initialize(test_task, options)
      super
      @group_includes = []
      @group_excludes = []
    end

    def tests(dependencies) #:nodoc:
      project = Buildr::Project.project_from_task( task )
      namespaces = dir_to_namespaces( project.path_to(:src, :test, :clojure ) )

      (namespaces + group_includes) - group_excludes
    end

    def run(clojuretest, dependencies) #:nodoc:
      success = []
      project = Buildr::Project.project_from_task( task )
      cp = dependencies +
        [
         project.path_to(:src, :test, :clojure),
         project.options.clojure.spec
        ]

      clojuretest.each do |suite|
        args = [
                "--eval", "(require (quote #{suite}) :reload-all)",
                "--eval", "(let [r (clojure.test/run-tests (quote #{suite}))]
                             (System/exit (+ (:fail r) (:error r))))"
               ]

        Java::Commands.java 'clojure.main', args, :classpath => cp do |ok, res|
          success << suite if ok
        end
      end

      success
    end # run

  end # ClojureTest

end

Buildr::TestFramework << Buildr::Clojure::ClojureTest
