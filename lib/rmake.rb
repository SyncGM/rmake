#--
# RMake v1.1 by Solistra
# =============================================================================
# 
# Summary
# -----------------------------------------------------------------------------
#   This script provides a very simple Rake-like utility for RPG Maker VX Ace
# projects which is run directly from the game player itself. Usage of a REPL
# (such as the [SES Console](https://github.com/sesvxace/console)) is highly
# recommended in order to make use of this script, though not necessary. This
# is primarily a scripter's tool.
# 
# Usage
# -----------------------------------------------------------------------------
#   This script attempts to behave similarly to the Rake utility commonly used
# in Ruby development. As such, invocation of RMake should be familiar: simply
# calling `rmake` via REPL or a script call will call the `:default` task; in
# order to call specific tasks (or a list of tasks in order), simply pass the
# tasks you wish to run to the `rmake` method as arguments. Tasks may be
# defined in an external file (the recommended way to define them) or through a
# script defined in the Ace script editor. The name of the external file (or
# internal script) may be defined in the configuration area for this script.
# 
#   Note that this script is, essentially, an incredibly simple version of the
# Rake utility -- as such, the DSL for defining tasks is appropriately simple.
# In order to define a task with no defined dependent tasks, simply use the
# `task` method, pass the name of your task as an argument, and provide a block
# which will be stored as that task's action:
# 
#     task :example do
#       puts 'This is an example task.'
#     end
# 
#   Defining a task with dependencies is just as simple, requiring only that
# you pass a hash into the `task` method; the key of the hash becomes your task
# name, and its value is an array of dependencies. Dependencies defined in this
# way will be called in the order given _before_ the defined task is executed.
# 
#     task :another_example => [:example] do
#       puts 'This task has a dependency.'
#     end
# 
#   Considering the dependency on the `:example` task, if you call `rmake` with
# `:another_example` as the task, you should see the following output:
# 
#     >> rmake :another_example
#     This is an example task.
#     This task has a dependency.
# 
#   You may also add descriptions to your tasks with the `desc` method by
# placing it directly before a task definition -- this is primarily used to
# display usage information for the built-in `:help` task.
# 
#     desc 'Prints an example message.'
#     task :example do ... end
# 
#   This will provide a usage string whenever you run RMake with the either the
# `:tasks` or `:help` task like so:
# 
#     >> rmake :help
#     Usage: rmake [:task[, :task ...]]
#     Tasks:
#       default          (undescribed)
#       example          Prints an example message.
# 
#   Note that you may also explicitly define your own `:default` task to be run
# when `rmake` is called without arguments, or you may overwrite the `:default`
# task with a task that you have previously defined:
# 
#     desc 'Prints an example message. (default)'
#     task :default => [:example]
# 
# License
# -----------------------------------------------------------------------------
#   This script is made available under the terms of the MIT Expat license.
# View [this page](http://sesvxace.wordpress.com/license/) for more detailed
# information.
# 
# Installation
# -----------------------------------------------------------------------------
#   Place this script below the SES Core (v2.0 or higher) script (if you are
# using it) or the Materials header, but above all other custom scripts. This
# script does not require the SES Core, but it is highly recommended.
# 
#++

# SES
# =============================================================================
# The top-level namespace for all SES scripts.
module SES
  # RMake
  # ===========================================================================
  # Provides classes and modules which culminate in a Rake-like utility.
  module RMake
    class << self
      # The current {Runner} if one exists.
      # @return [Runner, nil]
      attr_accessor :runner
    end
    
    # =========================================================================
    # BEGIN CONFIGURATION
    # =========================================================================
    
    # The value of this constant determines how {RMake} will attempt to collect
    # and execute tasks. The default (and highly recommended) way to use this
    # constant is to provide a string which represents an external file to run
    # relative to your project's root directory. It is also possible, however,
    # to use a tasks file which is defined within the Ace Script Editor by
    # using a value of `:internal` -- in this case, the first script with the
    # name specified by {RGSS_SCRIPT} will be used as the tasks file.
    # 
    # **NOTE:** Using an internal tasks file will cause the contents of the
    # script to be executed by the game player as usual -- take any necessary
    # precautions if you decide to use one.
    FILE = 'RMakefile.rb'
    
    # The name of an RGSS3 script in the Ace Script Editor providing {RMake}
    # tasks if the value of {FILE} is `:internal`.
    RGSS_SCRIPT = 'RMakefile'
    
    # Whether or not to print the full backtrace if an exception is encountered
    # while running RMake.
    TRACE = true
    
    # =========================================================================
    # END CONFIGURATION
    # =========================================================================
    
    # Task
    # =========================================================================
    # Provides a basic object representing a task, its dependencies, and the
    # action it performs.
    class Task
      # The action called by {#invoke}.
      # @return [Proc]
      attr_reader :action
      
      # The dependencies for this task.
      # @return [Array<Symbol>]
      attr_reader :dependencies
      
      # The description of this task.
      # @return [String]
      attr_reader :description
      
      # The name of this task.
      # @return [String]
      attr_reader :name
      
      # Instantiates a new {Task} object with the given name, dependencies, and
      # action to invoke.
      # 
      # @param name [#to_sym] the name of this task
      # @param dependencies [Array<#to_sym>] the dependencies for this task
      # @param description [#to_s] the description of this task
      # @return [Task] the new {Task} instance
      def initialize(name, dependencies = [], description = nil, &action)
        @name         = name.to_sym
        @dependencies = dependencies.map!(&:to_sym)
        @description  = description
        @action       = action
        @invoked      = false
      end
      
      # Calls the action defined for this task if it has not already been
      # invoked during this run.
      # 
      # @return [Boolean] `true` if the task was invoked, `false` otherwise
      def invoke
        return false if invoked? || SES::RMake.runner.nil?
        @dependencies.each { |dep| SES::RMake.runner.invoke_task(dep) }
        @action.call if @action
        @invoked = true
      end
      
      # Adds a description to this task.
      # 
      # @param description [#to_s] the desired description for this {Task}
      # @return [String] the description
      def describe(description)
        @description = description.to_s
      end
      
      # Returns the invocation status of this task.
      # 
      # @return [Boolean] `true` if the {Task} has been invoked, `false`
      #   otherwise
      def invoked?
        @invoked
      end
      
      # Clears the invocation status of this task.
      # 
      # @return [Task] this {Task} instance
      def clear
        tap { @invoked = false }
      end
    end
    # Runner
    # =========================================================================
    # Provides a unique runnable environment for RMake tasks roughly equivalent
    # to an executable.
    class Runner
      # The hash of tasks known to this {Runner}.
      # @return [Hash{Symbol => Task}]
      attr_reader :tasks
      
      # Instantiates a new {Runner} and assigns itself as the value for
      # {SES::RMake.runner}.
      # 
      # @return [Runner] the new {Runner} instance
      def initialize
        SES::RMake.runner = self
        collect_tasks
      end
      
      # Deterministically collects the tasks for this {Runner} instance. If the
      # value of {SES::RMake::FILE} is `:internal`, tasks will be collected
      # from an RGSS3 script in the script editor; otherwise, tasks will be
      # gathered from an external file represented by {SES::RMake::FILE}.
      # 
      # @return [void]
      # @see #collect_tasks_internally
      # @see #collect_tasks_from_file
      def collect_tasks
        @tasks ||= {}
        if SES::RMake::FILE == :internal
          collect_tasks_internally
        else
          collect_tasks_from_file(SES::RMake::FILE.to_s)
        end
      end
      private :collect_tasks
      
      # Collects tasks by evaluating the contents of an internal script named
      # 'RMakefile' using the RMake domain-specific language. This method is
      # used entirely for its side-effects.
      # 
      # @note This method uses the first RGSS3 script titled "RMakefile" in the
      #   Ace Script Editor and ignores all others.
      # 
      # @return [void]
      def collect_tasks_internally
        script = $RGSS_SCRIPTS.find { |s| s[1] == SES::RMake::RGSS_SCRIPT }
        if script
          with_exception_handling { TOPLEVEL_BINDING.eval(script[3]) }
        else
          puts "Could not find internal script '#{SES::RMake::RGSS_SCRIPT}'!"
        end
      end
      private :collect_tasks_internally
      
      # Collects tasks by evaluating the contents of an external file written
      # using the RMake domain-specific language. This method is used entirely
      # for its side-effects.
      # 
      # @param file [String] the filename to collect tasks from
      # @return [void]
      def collect_tasks_from_file(file)
        if FileTest.exist?(file)
          with_exception_handling { TOPLEVEL_BINDING.eval(File.read(file)) }
        else
          puts "Could not find external file '#{file}'!"
        end
      end
      private :collect_tasks_from_file
      
      # Prepares a description for the next {Task} to be added to this {Runner}
      # via the {#add_task} method.
      # 
      # @param description [String] the description to prepare
      # @return [String] the prepared description
      def prepare_task_description(description)
        @next_description = description.to_s
      end
      
      # Adds a {Task} to the known tasks for this {Runner}.
      # 
      # @param task [Task] the task to add
      # @return [Task] the added task
      def add_task(task)
        if @next_description
          task.describe(@next_description)
          @next_description = nil
        end
        @tasks[task.name] = task
      end
      
      # Invokes the task represented by the given task name if the task is
      # present within this {Runner}.
      # 
      # @param task_name [Symbol] the name of the task to invoke
      # @return [Object, nil] the return value of task invocation or `nil` if
      #   invocation failed
      def invoke_task(task_name)
        unless @tasks[task_name].respond_to?(:invoke)
          raise NoMethodError, "Cannot invoke task: '#{task_name}'"
        end
        @tasks[task_name].invoke
      end
      
      # Clears the invocation status of all of the tasks present within this
      # {Runner}.
      # 
      # @return [Hash{Symbol => Task}] the hash of known tasks
      def clear
        @tasks.tap { |tasks| tasks.each_value(&:clear) }
      end
      
      # Prints basic usage information and information about all of the tasks
      # known to this {Runner} to standard output.
      # 
      # @return [nil]
      def print_usage
        puts 'Usage: rmake [:task[, :task ...]]', 'Tasks:'
        @tasks.each_value do |t|
          puts '  %-16.16s %-16s' % [t.name, t.description || '(undescribed)']
        end
        return
      end
      
      # Runs the given block of code, printing exception information to the
      # standard error stream if encountered. Exits the application if a
      # `SystemExit` exception is enountered.
      # 
      # @note This method will only print an actual backtrace if the value of
      #   {SES::RMake::TRACE} evaluates to `true`.
      # 
      # @return [Object, Exception] the return value of the given block if
      #   successful, the raised `Exception` otherwise
      def with_exception_handling(&block)
        yield
      rescue SystemExit
        exit!
      rescue Exception => ex
        $stderr.puts(if SES::RMake::TRACE
          for l in ex.backtrace
            break if l[/^:1:/]
            (trace ||= []) << l.gsub(/^{(\d+)}/) { $RGSS_SCRIPTS[$1.to_i][1] }
          end
          "FAILED: #{ex.class}: #{ex}\nBacktrace:\n\t" << trace.join("\n\t")
        else
          "FAILED: #{ex.class}: #{ex}\n(Enable tracing for more information.)"
        end)
        ex
      end
      private :with_exception_handling
      
      # Runs the tasks represented by the given task names (as well as their
      # dependencies).
      # 
      # @param tasks [Array<Symbol>] the names of tasks to run
      # @return [Array<Symbol>, Exception] the names of the run tasks if this
      #   run was successful, the raised `Exception` otherwise
      def call(*tasks)
        tasks.map!(&:to_sym)
        if tasks.include?(:help) || tasks.include?(:tasks)
          print_usage
          return [:help]
        else
          with_exception_handling do
            tasks << :default if tasks.empty?
            tasks.select(&method(:invoke_task))
          end
        end
      end
    end
    # DSL
    # =========================================================================
    # Provides a simple domain-specific language for RMake.
    module DSL
      # Defines a {Task} (or number of {Task} instances) and adds it to the
      # current {Runner}.
      # 
      # @param type [#to_sym, Hash{#to_sym => Array<#to_sym>}] the name of the
      #   task (or a hash of tasks and their dependencies) being defined
      # @return [Task] the defined {Task} instance
      def task(type, &action)
        return unless SES::RMake.runner
        if type.respond_to?(:to_sym)
          # There can be no dependencies if the `type` responds to `#to_sym`.
          ::SES::RMake.runner.add_task(SES::RMake::Task.new(type, [], &action))
        else
          type.map do |(t, d)|
            ::SES::RMake.runner.add_task(SES::RMake::Task.new(t, d, &action))
          end
        end
      end
      
      # Describes the next defined {Task}. This information is primarily used
      # to print RMake usage information.
      # 
      # @param description [#to_s] the description for the next defined task
      # @return [String] the prepared description
      def desc(description)
        return unless SES::RMake.runner
        ::SES::RMake.runner.prepare_task_description(description)
      end
      
      # Creates a new {Runner} and runs the tasks represented by the given task
      # names through it.
      # 
      # @param tasks [Array<#to_sym>] the names of tasks to run
      # @return [Array<Symbol>, nil] an array of task names which were run if
      #   successful, `nil` otherwise
      def rmake(*tasks)
        runner = ::SES::RMake::Runner.new
        runner.call(*tasks) unless runner.tasks.empty?
      end
    end
    
    # Register this script with the SES Core if it exists.
    if SES.const_defined?(:Register)
      # Script metadata.
      Description = Script.new(:RMake, 1.1, :Solistra)
      Register.enter(Description)
    end
  end
end

# Include the methods defined in `SES::RMake::DSL` in main.
include SES::RMake::DSL
