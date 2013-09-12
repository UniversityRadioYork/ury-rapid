require_relative 'exceptions'

module Bra
  # Internal: The Commander converts API requests into playout system
  # commands, executes them, and deals with any error messages.
  class Commander
    # Internal: Initialises the Commander.
    #
    # command_module  - The module containing all of the commands the Commander
    #                   will execute.
    # error_callback  - The callable to use when encountering an error.  This
    #                   should halt the command (for example by throwing an
    #                   exception).
    # run_arguments   - The arguments to provide to each command as it is run.
    def initialize(command_module, error_callback, run_arguments)
      @command_module = command_module
      @error_callback = error_callback
      @run_arguments = run_arguments
    end

    # Internal: Runs a command.
    #
    # symbol    - The symbol representing the command.
    # arguments - The arguments to provide to the command's initialiser.
    #
    # Returns nothing.
    def run(symbol, *arguments)
      command = @command_module.const_get(symbol)
      error_callback("No such command: #{symbol}.") if command.nil?

      run_class(command, arguments)
    end

    private

    # Internal: Runs the command with the specified class.
    #
    # command_class - The class representing the command.
    # arguments     - The arguments to provide to the command's initialiser.
    #
    # Returns nothing.
    def run_class(command_class, arguments)
      instance = command_class.new(*arguments)
    rescue Exceptions::CommandError => e
      error_callback(e.message)
    else
      instance.run(*@run_arguments)
    end
  end
end
