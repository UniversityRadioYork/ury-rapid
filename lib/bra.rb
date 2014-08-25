require 'bra/launcher'
require 'bra/common/constants'

# The Bra system.
module Bra
  def self.from_config_file(file = nil)
    config = get_config(file)
    if config.nil?
      $stderr.puts('No config file. Dying.')
    else
      Bra::Launcher.launch(config)
    end
  end

  private

  def self.get_config(file)
    load_config_from(file_or_default(file))
  end

  def self.file_or_default(file)
    file || Bra::Common::Constants::CONFIG_FILE
  end

  def self.load_config_from(file)
    return nil unless File.exist?(file)
    File.read(file)
  end
end
