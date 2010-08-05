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
  class Options
    DEFAULT_CLOJURE_SPEC = "org.clojure:clojure:jar:1.1.0"
    DEFAULT_JLINE_SPEC = "jline:jline:jar:0.9.94"
    DEFAULT_SWANK_SPEC = "swank-clojure:swank-clojure:jar:1.2.1"
    DEFAULT_SWANK_PORT = 4005
    DEFAULT_SWANK_HOST = "localhost"


    # :call-seq:
    #   clojure => options
    #
    # Returns the Clojure options. Currently supported options are:
    # * :spec -- The artifact spec for Clojure
    # * :jline_spec -- The artifact spec for jline
    # * :swank_spec -- The artifact spec for Swank
    # * :swank_port -- The port to use when running swank
    # * :swank_host -- The host to use when running swank
    # * :package_sources -- Should the .clj sources be included when packaging
    #
    # For example:
    #   options.clojure.swank_port = 4000
    def clojure
      @clojure ||= Buildr::struct(
                                  :spec              => DEFAULT_CLOJURE_SPEC,
                                  :jline_spec        => DEFAULT_JLINE_SPEC,
                                  :swank_spec        => DEFAULT_SWANK_SPEC,
                                  :swank_port        => DEFAULT_SWANK_PORT,
                                  :swank_host        => DEFAULT_SWANK_HOST,
                                  :package_sources   => true
                                  )
    end
  end

  module Clojure
    module ShouldBuild
      # don't build if it's *only* Clojure sources
      def build?
        (has_source?(:java) or
         has_source?(:scala) or
         has_source?(:groovy))
      end

      private
      def has_source?(lang)
        File.exists? project.path_to(:src, :main, lang)
      end
    end

    module ClojureNamespace
      def namespace_to_path( ns )
        ns.gsub( ".", "/" ).gsub( "-", "_" )
      end

      def path_to_namespace( path )
        path.gsub( "/", "." ).gsub( "_", "-" )
      end

      def dir_to_namespaces( dir )
        dir += "/" unless dir[-1] == ?/
        Dir["#{dir}**/*.clj"].map do |fname|
          path_to_namespace( fname[dir.length, fname.length - dir.length - 4] )
        end
      end
    end
  end
end
