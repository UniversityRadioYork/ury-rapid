require 'yaml'

require 'bra/launcher'
require 'bra/common/constants'

module Bra
  def self.launch_from_config_file(file = nil)
    Bra::Launcher.launch(get_config(file))
  end

  private

  def get_config(file)
    load_config_from(file_or_default(file))
  end

  def file_or_default(file)
    file || Bra::Common::Constants::CONFIG_FILE
  end

  def load_config_from(file)
    YAML.load_file(file).deep_symbolize_keys!
  end
end
