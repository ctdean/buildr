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

require 'buildr/core/project'
require 'buildr/core/common'
require 'buildr/core/compile'
require 'buildr/packaging'

require 'buildr/java/commands'

module Buildr
  module Clojure
    class Cljc < Buildr::Compiler::Base
      include Buildr::Clojure::ClojureNamespace

      OPTIONS = [:libs, :scalac, :groovyc, :javac]

      specify :language => :clojure, :sources => [:clojure, :java, :scala, :groovy],
              :source_ext => [:clj, :java, :scala, :groovy], :target => 'classes',
              :target_ext => 'class', :packaging => :jar

      def initialize(project, options)
        super
        options[:javac] ||= {}
        options[:scalac] ||= {}
        options[:groovyc] ||= {}

        @project = project
      end

      def compile(sources, target, dependencies) #:nodoc:
        check_options options, OPTIONS

        source_paths = sources.select { |source| File.directory?(source) }

        options[:libs] ||= source_paths.map { |path| dir_to_namespaces( path ) }.flatten

        cp = dependencies + source_paths + clojure_path
        cp_str = inner_classpath_from(cp).join(File::PATH_SEPARATOR) +
                 File::PATH_SEPARATOR + File.expand_path(target)

        cmd_args = [
          '-classpath', "'#{cp_str}'",
          "-Dclojure.compile.path='#{File.expand_path(target)}'",
          'clojure.lang.Compile'
        ] + options[:libs]

        trace "Target: #{target}"
        trace "Sources: [ #{sources.join ', '} ]"

        task :cljc do
          cmd = 'java ' + cmd_args.join(' ')
          trace cmd
          system cmd or fail 'Failed to compile. See errors above.'
        end

        options[:libs].each do |ns|
          src = namespace_to_path( ns )
          found = false

          source_paths.each do |s_path|
            orig = File.expand_path(src + '.clj', s_path)

            if File.exists? orig
              fail "Found duplicate namespace across multiple source dirs: #{ns}" if found
              found = true

              file File.expand_path(src + '__init.class', target) => orig do
                task(:cljc).invoke
              end.invoke
            end
          end
        end

        source_paths.each do |path|
          copy_remainder(path, File.expand_path(target), [], options[:libs])
        end

        if scala_applies? sources
          require 'buildr/scala'

          trace 'Compiling mixed Clojure/Scala/Java sources'

          @scalac = Buildr::Scala::Scalac.new(@project, options[:scalac])
          @scalac.compile(sources, target, cp)
        elsif groovy_applies? sources
          require 'buildr/groovy'

          trace 'Compiling mixed Clojure/Groovy/Java sources'

          @groovyc = Buildr::Groovy::Groovyc.new(@project, options[:groovyc])
          @groovyc.compile(sources, target, cp)
        elsif java_applies? sources
          trace 'Compiling mixed Clojure/Java sources'

          @javac = Buildr::Compiler::Javac.new(@project, options[:javac])
          @javac.compile(sources, target, cp)
        end
      end

    private
      def clojure_path
        @clojure_path ||= Buildr.artifacts(@project.options.clojure.spec).map(&:to_s).
          map { |t| task(t).invoke; File.expand_path(t) }
      end

      def scala_applies?(sources)
        not sources.flatten.map { |source| File.directory?(source) ? FileList["#{source}/**/*.scala"] : source }.
          flatten.reject { |file| File.directory?(file) }.map { |file| File.expand_path(file) }.uniq.empty?
      end

      def groovy_applies?(sources)
        not sources.flatten.map { |source| File.directory?(source) ? FileList["#{source}/**/*.groovy"] : source }.
          flatten.reject { |file| File.directory?(file) }.map { |file| File.expand_path(file) }.uniq.empty?
      end

      def java_applies?(sources)
        not sources.flatten.map { |source| File.directory?(source) ? FileList["#{source}/**/*.java"] : source }.
          flatten.reject { |file| File.directory?(file) }.map { |file| File.expand_path(file) }.uniq.empty?
      end

      def inner_classpath_from(cp)
        Buildr.artifacts(cp.map(&:to_s)).map do |t|
          task(t).invoke
          File.expand_path t
        end
      end

      def copy_remainder(path, target, ns, done)
        Dir.foreach path do |fname|
          unless fname == '.' or fname == '..'
            fullname = File.expand_path(fname, path)

            if fname =~ /^(.+)\.clj$/
              fullns = if ns.size > 0 then ns.join('.') + '.' else '' end + $1

              unless done.include? fullns
                dest_dir = target + if ns.size > 0 then File::SEPARATOR + ns.join(File::SEPARATOR) else '' end

                file dest_dir + File::SEPARATOR + fname => fullname do
                  mkdir dest_dir unless File.exists? dest_dir
                  cp fullname, dest_dir + File::SEPARATOR + fname
                end.invoke
              end
            elsif File.directory? fullname
              copy_remainder(fullname, target, ns + [fname], done)
            end
          end
        end
      end
    end
  end
end

Buildr::Compiler.compilers.unshift Buildr::Clojure::Cljc
