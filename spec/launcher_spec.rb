require 'bra/launcher'

describe Bra::Launcher do
  subject { Bra::Launcher.new(config, overrides) }
  let(:config) do
    { driver: driver_config,
      model: model_config,
      server: server_config,
      users: user_config
    }
  end
  let(:overrides) do
    { app:                app_maker,
      auth:               auth_maker,
      channel:            channel_maker,
      driver:             driver_maker,
      driver_view:        driver_view_maker,
      logger:             logger_maker,
      model_configurator: model_configurator_maker,
      model_structure:    model_structure_maker,
      server:             server_maker,
      server_view:        server_view_maker
    }
  end

  MAKERS = %i{
    app auth channel driver logger model_configurator model_structure server
    driver_view server_view
  }

  MAKERS.each do |maker|
    sym = "#{maker}_maker".to_sym
    let(sym) { double(sym) }
    let(maker) { double(maker) }
  end

  let(:model) { double(:model) }

  let(:driver_config) { double(:driver_config) }
  let(:model_config) { double(:model_config) }
  let(:server_config) { double(:server_config) }
  let(:user_config) { double(:user_config) }

  describe '#run' do
    before(:each) do
      allow(app_maker).to receive(:call).and_return(app)
      allow(auth_maker).to receive(:call).and_return(auth)
      allow(channel_maker).to receive(:call).and_return(channel)
      allow(server_maker).to receive(:call).and_return(server)
      allow(driver_maker).to receive(:call).and_return(driver)
      allow(logger_maker).to receive(:call).and_return(logger)

      allow(driver_view_maker).to receive(:call).and_return(driver_view)
      allow(server_view_maker).to receive(:call).and_return(server_view)
      allow(model_structure_maker).to receive(:call).and_return(
        model_structure
      )
      allow(model_configurator_maker).to receive(:call).and_return(
        model_configurator
      )

      allow(model_configurator).to receive(:configure_with).and_return(
        model_configurator
      )
      allow(model_configurator).to receive(:make).and_return(model)
      allow(app).to receive(:run)
    end

    def test_maker(maker, *args)
      expect(maker).to receive(:call).once.with(*args)
      subject.run
    end

    it 'calls the app maker with the driver, its view, server, and its view' do
      test_maker(app_maker, driver, driver_view, server, server_view)
    end
    it 'calls the authenticator maker with the user configuration' do
      test_maker(auth_maker, user_config)
    end
    it 'calls the channel maker with no arguments' do
      test_maker(channel_maker, no_args)
    end
    it 'calls the driver maker with the driver config and logger' do
      test_maker(driver_maker, driver_config, logger)
    end
    it 'calls the logger maker' do
      test_maker(logger_maker)
    end

    it 'calls the model configurator maker with its expected arguments' do
      test_maker(
        model_configurator_maker,
        model_structure,
        channel,
        logger,
        model_config
      )
    end
    it 'calls the model structure maker with the model config' do
      test_maker(model_structure_maker, model_config)
    end
    it 'calls the server maker with config and authenticator' do
      test_maker(server_maker, server_config, auth)
    end
    it 'calls the driver view maker with the model configurator and model' do
      test_maker(driver_view_maker, model_configurator, model)
    end
    it 'calls the server view maker with the model' do
      test_maker(server_view_maker, model)
    end
  end
end
