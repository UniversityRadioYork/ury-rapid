require 'colored'

module Bra
  # Utility functions for logging
  #
  # Bra::Logger defines a method, #default_logger, that provides a sensible
  # logging format for BRA.
  module Logger
    # Constructs the default BRA logger configuration
    def self.default_logger
      # TODO: Allow redirecting
      output = STDERR
      ::Logger.new(output).tap do |logger|
        logger.formatter = proc do |severity, datetime, _progname, msg|
          [format_date(datetime, output),
           format_severity(severity, output),
           msg].join(' ') + "\n"
        end
      end
    end

    private

    # Colourises the severity if the logging output is a terminal
    def self.format_severity(severity, output)
      "[#{output.is_a?(String) ? severity : coloured_severity(severity)}]"
    end

    def self.format_date(datetime, output)
      dt = datetime.strftime('%d/%m/%y %H:%M:%S')
      output.is_a?(String) ? dt : dt.green
    end

    SEVERITIES = {
      'DEBUG' => :green,
      'INFO' => :blue,
      'WARN' => :yellow,
      'ERROR' => :red,
      'FATAL' => :magenta
    }

    def self.coloured_severity(severity)
      severity.send(SEVERITIES.fetch(severity, :white))
    end
  end
end