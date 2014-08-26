module Bra
  module ServiceCommon
    module Responses
      # DSL for defining response structures
      #
      # Response structures are useful when dealing with the output of a
      # playout system that speaks a binary protocol.  They allow the mapping
      # of a received command word to a list of expected following arguments.
      module StructureBuilder
        extend Forwardable

        # Creates a method at the singleton class level
        def create_method(name, &block)
          singleton_class.send(:define_method, name, &block)
        end

        # Defines the types that the structures are defined over
        def def_types(*types)
          types.each { |type| create_method(type) { |name| [name, type] } }
        end

        # Defines a common structure that can be reused for multiple commands
        def def_struct(name, *arguments)
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
          add_group_constants
          yield
        end

        def struct(key, *items)
          @structures[key] = items
        end

        def def_argument_shortcuts(type, arguments)
          arguments.each do |argument|
            create_method(argument) { send(type, argument) }
          end
        end

        # Exports a group's constants into this structure builder
        #
        # This allows them to be specified unqualified in a group.
        def add_group_constants
          @code_module.constants.each do |constant|
            const_set(constant, @code_module.const_get(constant))
          end
        end
      end
    end
  end
end
