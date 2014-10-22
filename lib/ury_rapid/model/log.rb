require 'compo'
require 'ury_rapid/model/model_object'

module Rapid
  module Model
    # An object that represents Rapid's error/debugging log
    #
    # This is part of the model to allow easy access to the logger in areas
    # such as the server and service, without needing to pass it in
    # explicitly.  It also allows the log to be treated like any other bit of
    # data Rapid holds.
    #
    # In future, the log may be readable using the Rapid API.
    class Log < Compo::Branches::Leaf
      include ModelObject

      # Initialises the Log
      #
      # @api  public
      # @example  Initialising a log with an instance of a Ruby Logger
      #   log = Log.new(Logger.new(STDOUT))
      #
      # @param logger [Object]  An object that implements the standard library
      #   Logger's API.
      def initialize(logger)
        super()
        @logger = logger
      end

      # POSTs an entry to this Log
      #
      # The ID should be one of :info, :debug, :warn, :fatal or :error, and the
      # payload should be the string to log.
      #
      # @api  public
      # @example  Posting an error message to the log.
      #   log.insert(:error, 'Somebody famous has died.')
      #
      # @param id [Symbol]  The target ID: for the Log, this is overloaded
      #   to mean the severity of the error message, which must be one of those
      #   listed above.
      #
      # @param payload [String]  The payload: for the Log, this should be the
      #   string to log.
      def insert(id, payload)
        fail(ArgumentError) unless %i(debug info warn fatal error).include?(id)
        @logger.send(id, payload)
      end
    end
  end
end
