require 'bra/launcher'
require 'bra/common/constants'

module Bra
  def self.from_config_file(file = nil)
    Bra::Launcher.launch(get_config(file))
  end

  private

  def self.get_config(file)
    load_config_from(file_or_default(file))
  end

  def self.file_or_default(file)
    file || Bra::Common::Constants::CONFIG_FILE
  end

  def self.load_config_from(file)
    File.read(file)
  end
end
