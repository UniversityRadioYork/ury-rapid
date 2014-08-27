require 'ury-rapid/launcher'
require 'ury-rapid/common/constants'

# The Rapid system.
module Rapid
  def self.from_config_file(file = nil)
    config = get_config(file)
    if config.nil?
      $stderr.puts('No config file. Dying.')
    else
      Rapid::Launcher.launch(config)
    end
  end

  private

  def self.get_config(file)
    load_config_from(file_or_default(file))
  end

  def self.file_or_default(file)
    file || Rapid::Common::Constants::CONFIG_FILE
  end

  def self.load_config_from(file)
    return nil unless File.exist?(file)
    File.read(file)
  end
end
