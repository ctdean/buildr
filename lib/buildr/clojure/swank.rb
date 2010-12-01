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

module Buildr
  module Clojure
    module ClojureSwankExtension
      include Extension
      include Buildr::Clojure::ShouldBuild

      first_time do
        Project.local_task 'clojure-swank'
      end

      before_define do |project|
        project.task "clojure-swank" do
          project.clojure_swank
        end
      end

      def clojure_swank( port = options.clojure.swank_port,
                         host = options.clojure.swank_host )
        cp = [project.path_to(:src, :main, :clojure)]
        cp += project.resources.sources
        if build?
          cp += [project.path_to(:target, :classes)]
        end
        cp += [options.clojure.spec, options.clojure.swank_spec]
        cp += project.compile.dependencies
        puts "Starting Clojure swank on #{host}:#{port}"
        Java::Commands.java "clojure.main",
                "--eval", "(require (quote swank.swank))",
                "--eval", "(swank.swank/start-repl #{port} :host \"#{host}\")",
                :classpath => cp
      end
    end
  end

  class Project
    include Clojure::ClojureSwankExtension
  end
end
