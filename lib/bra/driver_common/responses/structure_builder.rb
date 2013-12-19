module Bra
  module DriverCommon
    # DSL for defining response structures
    #
    # Response structures are useful when dealing with the output of a playout
    # system that speaks a binary protocol.  They allow the mapping of a
    # received command word to a list of expected following arguments.
    class StructureBuilder
      extend Forwardable

      # Creates a method at both the class and instance levels
      def self.create_method(name, &block)
        self.class.send(:define_method, name, &block)
        define_method(name, &block)
      end

      # Defines the types that the structures are defined over
      def self.def_types(*types)
        types.each { |type| create_method(type) { |name| [name, type] } }
      end

      # Defines a common structure that can be reused for multiple commands
      def self.def_struct(name, *arguments)
        create_method(name) do |*symbols|
          symbols.each { |symbol| struct(symbol, *arguments) }
        end
      end

      # Begins defining the structures
      def structures
        @structures = {}
        yield
      end

      # Allows fetching the structure for a given command word
      def_delegator :@structures, :fetch, :structure

      def group(code_module)
        @code_module = code_module
        yield
      end

      def struct(symbol, *items)
        key = @code_module.const_get(symbol)
        @structures[key] = items
      end

      def self.def_argument_shortcuts(type, arguments)
        arguments.each do |argument|
          create_method(argument) { send(type, argument) }
        end
      end
    end
  end
end
