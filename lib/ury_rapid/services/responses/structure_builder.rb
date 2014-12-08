module Rapid
  module Services
    module Responses
      # DSL for defining response components
      #
      # Response components are useful when dealing with the output of a
      # playout system that speaks a binary protocol.  They allow the mapping
      # of a received command word to a list of expected following arguments.
      module StructureBuilder
        extend Forwardable

        # Defines the types over which the components are defined
        #
        # Types are, effectively, symbols that are understood by the response
        # parser as indicating a specific parsing pattern to use to parse
        # arguments.
        #
        # @api      public
        # @example  Defining a set of types.
        #   def_types :float32, :uint32, :string, :load_body, :config_setting
        #
        # @param types
        #   The types to define in the structure builder.
        #
        # @return [null]
        def def_types(*types)
          types.each { |type| create_method(type) { |name| [name, type] } }
        end

        # Defines a common structure that can be reused for multiple commands
        #
        # Given a name and arguments, this creates a method of that name that,
        # when called with a response code, expands to a #struct call with that
        # code and the provided arguments.
        #
        # For convenience, multiple codes may be provided to the shortcut, with
        # the same result as that from invoking the shortcut once for each code.
        #
        # When the same structure is repeated multiple times with only the
        # response code varying, one can instead #def_struct the structure once
        # and then call the created method with those codes, saving time and
        # RSI.
        #
        # @api      public
        # @example  Defining a common structure with no argument.
        #   def_struct :unary
        #   # We can now write 'unary PLAY' instead of 'struct PLAY'.
        # @example  Defining a common structure with arguments.
        #   # Here, 'option_id' is an argument shortcut, and 'config_setting'
        #   # is a type.
        #   def_struct :config, option_id, config_setting(:setting)
        #   # We can now write 'config CONFIG_SETTING, CONFIG_SETTING_INDEXED'
        #   # instead of the rather long-winded
        #   # 'struct CONFIG_SETTING, option_id, config_setting(:setting)' and
        #   # 'struct CONFIG_SETTING_INDEXED, option_id,
        #   #  config_setting(:setting)'.
        #
        # @return [null]
        def def_struct(name, *arguments)
          create_method(name) do |*symbols|
            symbols.each { |symbol| struct(symbol, *arguments) }
          end
        end

        # Defines shortcuts for common argument type-name pairs
        #
        # This creates, for each argument name in 'arguments', a method with
        # that name serves as a shortcut for calling 'type' with that name.
        #
        # @api      public
        # @example  Defining some argument shortcuts.
        #   # Assume 'uint32' is an existing type.
        #   def_argument_shortcuts :uint32, %i(position count index)
        #   # We can now substitute 'position' etc. for 'uint32(position' etc.
        #   # in calls to #struct.
        #
        # @param type [Symbol]
        #   The type, defined by #def_type, of all argument shortcuts to be
        #   defined by this method call.
        #
        # @param arguments [Array]
        #   An array of symbols, each representing a common argument name for
        #   which a shortcut method should be made that creates an argument
        #   with type 'type' and said argument name.
        #
        # @return [null]
        def def_argument_shortcuts(type, arguments)
          arguments.each do |argument|
            create_method(argument) { send(type, argument) }
          end
        end

        # Allows response components to be defined
        #
        # @api      public
        # @example  An example components block.
        #   components do
        #     # See the documentation for #group for more explanation about
        #     # what this is doing
        #     group Codes::Playlist do
        #       struct DELETE_ITEM,           index
        #       struct MOVE_ITEM_IN_PLAYLIST, old_index, new_index
        #       struct ITEM_COUNT,            count
        #       struct ITEM_DATA,             index, uint32(:type), title
        #     end
        #   end
        #
        # @return [null]
        def structures
          @structures = {}
          yield
        end

        # Allows fetching the structure for a given command word
        def_delegator :@structures, :fetch, :structure

        # Defines a response group
        #
        # This effectively takes a module containing response structure codes
        # as constants and, for the duration of the #group block, brings those
        # codes into the global namespace.  It also serves as a nice way of
        # grouping components by the same structure used in the code table.
        #
        # @api      public
        # @example  An example group block.
        #   group Codes::Playlist do
        #     # The group has brought DELETE_ITEM, MOVE_ITEM_IN_PLAYLIST,
        #     # ITEM_COUNT, and ITEM_DATA into scope from Codes::Playlist
        #     struct DELETE_ITEM,           index
        #     struct MOVE_ITEM_IN_PLAYLIST, old_index, new_index
        #     struct ITEM_COUNT,            count
        #     struct ITEM_DATA,             index, uint32(:type), title
        #   end
        #
        # @param code_module [Module]
        #   The module, from the response code table, in which the command
        #   codes for all of the responses in this group are defined.
        #
        # @return [null]
        def group(code_module)
          @code_module = code_module
          add_group_constants
          yield
        end

        # Defines a response structure
        #
        # This creates an association between the response code and the
        # following argument types and names, so that, if the code is read by
        # the response parser, the parser will prepare to read values with
        # those types and store them under the respective names.
        #
        # The arguments can either be defined by calling a type set up with
        # #def_types with the intended argument name, or by calling an argument
        # shortcut set up with #def_argument_shortcuts.
        #
        # @api      public
        # @example  Defining a structure.
        #   # Assuming that the code DELETE_ITEM is in scope, and the argument
        #   # shortcut 'index' has been defined.
        #   struct DELETE_ITEM, index
        #
        # @param code [Object]
        #   The response code.  The actual type of this code will depend on the
        #   protocol.
        # @param arguments
        #   Zero or more argument specifiers, telling the structure builder
        #   which arguments will be expected of a response with the given code.
        #
        # @return [null]
        def struct(code, *arguments)
          @structures[code] = arguments
        end

        # Creates a method at the singleton class level
        #
        # @api private
        #
        # @param name [String]
        #   The name of the method to create.
        #
        # @return [null]
        def create_method(name, &block)
          singleton_class.send(:define_method, name, &block)
        end

        # Exports a group's constants into this structure builder
        #
        # This allows them to be specified unqualified in a group.
        #
        # @api private
        #
        # @return [null]
        def add_group_constants
          @code_module.constants.each do |constant|
            const_set(constant, @code_module.const_get(constant))
          end
        end
      end
    end
  end
end
