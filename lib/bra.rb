require 'bra/launcher'
require 'bra/common/constants'

module Bra
  def self.from_config_file(file = nil)
    config = get_config(file)
    unless config.nil?
        Bra::Launcher.launch(config)
    else
        $stderr.puts('No config file. Dying.')
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
    return nil unless File.exists?(file)
    File.read(file)
  end
end
