require 'bra/launcher'

describe Bra::Launcher do
  subject { Bra::Launcher.new(config, overrides) }
  let(:config) do
    dc = driver_config
    mcl = model_class
    sc = server_config
    un = user_name
    uc = user_config
    di = driver_id
    dcl = driver_class
    si = server_id
    scl = server_class
    proc do
      driver(di, dcl) { dc }
      model mcl
      server(si, scl) { sc }
      user(un) { uc }
    end
  end

  let(:user_name) { double(:user_name) }

  let(:overrides) do
    { app:                app_maker,
      auth:               auth_maker,
      channel:            channel_maker,
      driver_view:        driver_view_maker,
      logger:             logger_maker,
      model_configurator: model_configurator_maker,
      model_structure:    model_structure_maker,
      server_view:        server_view_maker
    }
  end

  MAKERS = %i{
    app auth channel logger model_configurator model_structure
    driver_view server_view
  }

  MAKERS.each do |maker|
    sym = "#{maker}_maker".to_sym
    let(sym) { double(sym) }
    let(maker) { double(maker) }
  end

  let(:model) { double(:model) }

  let(:server)                 { double(:server)                 }
  let(:server_id)              { double(:server_id)              }
  let(:server_class)           { double(:server_class)           }

  let(:driver)                 { double(:driver)                 }
  let(:driver_id)              { double(:driver_id)              }
  let(:driver_class)           { double(:driver_class)           }
  let(:driver_model_structure) { double(:driver_model_structure) }
  let(:driver_model)           { double(:driver_model)           }
  let(:register_driver_view)   { double(:register_driver_view)   }

  let(:driver_config) { double(:driver_config) }
  let(:model_class) { double(:model_class) }
  let(:server_config) { double(:server_config) }
  let(:user_config) { double(:user_config) }

  describe '#run' do
    before(:each) do
      allow(app_maker).to receive(:call).and_return(app)
      allow(auth_maker).to receive(:call).and_return(auth)
      allow(channel_maker).to receive(:call).and_return(channel)
      allow(logger_maker).to receive(:call).and_return(logger)

      allow(driver_view_maker).to receive(:call).and_return(driver_view)
      allow(server_view_maker).to receive(:call).and_return(server_view)
      allow(model_configurator_maker).to receive(:call).and_return(
        model_configurator
      )

      allow(driver_view).to receive(:post)

      allow(model_configurator).to receive(:configure_with).and_return(
        model_configurator
      )
      allow(model_configurator).to receive(:make).and_return(model)
      allow(app).to receive(:run)

      allow(model_class).to receive(:new).and_return(model_structure)
      allow(model_structure).to receive(:create).and_return(model)

      allow(driver_class).to receive(:new).and_return(driver)
      allow(driver).to receive(:sub_model).and_return(
        [driver_model_structure, register_driver_view]
      )
      allow(driver_model_structure).to receive(:create).and_return(driver_model)
      allow(register_driver_view).to receive(:call)

      allow(server_class).to receive(:new).and_return(server)
    end

    def test_maker(maker, *args)
      expect(maker).to receive(:call).once.with(*args)
      subject.run
    end

    it 'calls the app maker with the drivers, servers, and driver view' do
      test_maker(app_maker, [driver], [server], driver_view)
    end
    it 'calls the authenticator maker with the user configuration' do
      test_maker(auth_maker, user_name => user_config)
    end
    it 'calls the channel maker with no arguments' do
      test_maker(channel_maker, no_args)
    end
    it 'calls the logger maker' do
      test_maker(logger_maker, no_args)
    end

    it 'initialises the driver class with the logger' do
      subject.run
      expect(driver_class).to have_received(:new).once.with(logger)
    end
    it 'initialises the server class with the global server view and auth' do
      subject.run
      expect(server_class).to have_received(:new).once.with(server_view, auth)
    end
    it 'initialises the model class with the update channel, logger and nil' do
      subject.run
      expect(model_class).to have_received(:new).once.with(
        channel,
        logger,
        nil
      )
    end
    it 'calls the driver view maker with the global model and structure' do
      subject.run
      expect(driver_view_maker).to have_received(:call).with(
        model, model_structure
      )
    end
    it 'calls the driver view maker with the driver model and structure' do
      subject.run
      expect(driver_view_maker).to have_received(:call).with(
        driver_model, driver_model_structure
      )
    end
    it 'calls the server view maker with the model' do
      test_maker(server_view_maker, model)
    end
  end
end
