
RMake v1.0 by Solistra
=============================================================================

Summary
-----------------------------------------------------------------------------
  This script provides a very simple Rake-like utility for RPG Maker VX Ace
projects which is run directly from the game player itself. Usage of a REPL
(such as the [SES Console](https://github.com/sesvxace/console)) is highly
recommended in order to make use of this script, though not necessary. This
is primarily a scripter's tool.

Usage
-----------------------------------------------------------------------------
  This script attempts to behave similarly to the Rake utility commonly used
in Ruby development. As such, invocation of RMake should be familiar: simply
calling `rmake` via REPL or a script call will call the `:default` task; in
order to call specific tasks (or a list of tasks in order), simply pass the
tasks you wish to run to the `rmake` method as arguments. Tasks may be
defined in an external file (the recommended way to define them) or through a
script defined in the Ace script editor. The name of the external file (or
internal script) may be defined in the configuration area for this script.

  Note that this script is, essentially, an incredibly simple version of the
Rake utility -- as such, the DSL for defining tasks is appropriately simple.
In order to define a task with no defined dependent tasks, simply use the
`task` method, pass the name of your task as an argument, and provide a block
which will be stored as that task's action:

    task :example do
      puts 'This is an example task.'
    end

  Defining a task with dependencies is just as simple, requiring only that
you pass a hash into the `task` method; the key of the hash becomes your task
name, and its value is an array of dependencies. Dependencies defined in this
way will be called in the order given _before_ the defined task is executed.

    task :another_example => [:example] do
      puts 'This task has a dependency.'
    end

  Considering the dependency on the `:example` task, if you call `rmake` with
`:another_example` as the task, you should see the following output:

    >> rmake :another_example
    This is an example task.
    This task has a dependency.

  You may also add descriptions to your tasks with the `desc` method by
placing it directly before a task definition -- this is primarily used to
display usage information for the built-in `:help` task.

    desc 'Prints an example message.'
    task :example do ... end

  This will provide a usage string whenever you run RMake with the either the
`:tasks` or `:help` task like so:

    >> rmake :help
    Usage: rmake [:task[, :task ...]]
    Tasks:
      default          (undescribed)
      example          Prints an example message.

  Note that you may also explicitly define your own `:default` task to be run
when `rmake` is called without arguments, or you may overwrite the `:default`
task with a task that you have previously defined:

    desc 'Prints an example message. (default)'
    task :default => [:example]

License
-----------------------------------------------------------------------------
  This script is made available under the terms of the MIT Expat license.
View [this page](http://sesvxace.wordpress.com/license/) for more detailed
information.

Installation
-----------------------------------------------------------------------------
  Place this script below the SES Core (v2.0 or higher) script (if you are
using it) or the Materials header, but above all other custom scripts. This
script does not require the SES Core, but it is highly recommended.

