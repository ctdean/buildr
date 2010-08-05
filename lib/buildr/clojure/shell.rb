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


require 'buildr/shell'

module Buildr
  module Clojure
    class ClojureShell < Buildr::Shell::Base
      include Buildr::Shell::JavaRebel
      include Buildr::Clojure::ShouldBuild

      class << self
        def lang
          :clojure
        end

        def to_sym
          :clj      # more common than `clojure`
        end
      end

      def launch
        cp = project.compile.dependencies +
          [
           project.path_to(:src, :main, :clojure),
           project.options.clojure.spec,
           project.options.clojure.jline_spec,
          ]

        if build?
          cp += [project.path_to(:target, :classes)]
        end

        puts "Starting Clojure repl"
        Java::Commands.java 'jline.ConsoleRunner', 'clojure.main', :classpath => cp
      end

    end
  end
end

Buildr::ShellProviders << Buildr::Clojure::ClojureShell
