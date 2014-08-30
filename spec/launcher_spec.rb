require 'ury-rapid/launcher'
require 'ury-rapid/modules/set'

describe Rapid::Launcher do
  subject { Rapid::Launcher.new(config) }
  let(:config) do
    dc = service_config
    mcl = model_class
    sc = server_config
    un = user_name
    uc = user_config
    di = service_id
    dcl = service_class
    si = server_id
    scl = server_class

    appm = app_maker
    authm = auth_maker
    cm = channel_maker
    dvm = service_view_maker
    lm = logger_maker
    svm = server_view_maker
    proc do
      modules do
        configure(di, dcl) { dc }
        enable di
        configure(si, scl) { sc }
        enable si
      end

      model mcl

      user(un) { uc }

      make_app_with appm
      make_auth_with authm
      make_channel_with cm
      make_logger_with lm
      make_service_view_with dvm
      make_server_view_with svm
    end
  end

  let(:user_name) { double(:user_name) }

  MAKERS = %i(app auth channel logger service_view server_view)

  MAKERS.each do |maker|
    sym = "#{maker}_maker".to_sym
    let(sym) { double(sym) }
    let(maker) { double(maker) }
  end

  let(:model)                  { double(:model)                  }
  let(:model_class)            { double(:model_class)            }
  let(:model_structure)        { double(:model_structure)        }

  let(:server)                 { double(:server)                 }
  let(:server_id)              { double(:server_id)              }
  let(:server_class)           { double(:server_class)           }

  let(:service)                 { double(:service)                 }
  let(:service_id)              { double(:service_id)              }
  let(:service_class)           { double(:service_class)           }
  let(:service_model_structure) { double(:service_model_structure) }
  let(:service_model)           { double(:service_model)           }
  let(:register_service_view)   { double(:register_service_view)   }

  let(:service_config) { double(:service_config) }
  let(:server_config) { double(:server_config) }
  let(:user_config) { double(:user_config) }

  describe '#run' do
    before(:each) do
      allow(app_maker).to receive(:call).and_return(app)
      allow(auth_maker).to receive(:call).and_return(auth)
      allow(channel_maker).to receive(:call).and_return(channel)
      allow(logger_maker).to receive(:call).and_return(logger)

      allow(service_view_maker).to receive(:call).and_return(service_view)
      allow(server_view_maker).to receive(:call).and_return(server_view)

      allow(service_view).to receive(:post)

      allow(app).to receive(:run)

      allow(model_class).to receive(:new).and_return(model_structure)
      allow(model_structure).to receive(:create).and_return(model)

      allow(service_class).to receive(:new).and_return(service)
      allow(service).to receive(:sub_model).and_return(
        [service_model_structure, register_service_view]
      )
      allow(service_model_structure).to receive(:create)
                                    .and_return(service_model)
      allow(register_service_view).to receive(:call)

      allow(server_class).to receive(:new).and_return(server)
    end

    def test_maker(maker, *args)
      expect(maker).to receive(:call).once.with(*args)
      subject.run
    end

    it 'calls the app maker with the module set and service view' do
      subject.run
      expect(app_maker).to have_received(:call).once.with(
        a_kind_of(Rapid::Modules::Set)
          .and(respond_to(:enabled))
          .and(satisfy { |ms| ms.enabled.include?(service_id) })
          .and(satisfy { |ms| ms.enabled.include?(server_id) }),
        service_view
      )
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

    it 'initialises the model class with the update channel, logger and nil' do
      subject.run
      expect(model_class).to have_received(:new).once.with(
        channel,
        logger,
        nil
      )
    end
    it 'calls the service view maker with the global model and structure' do
      subject.run
      expect(service_view_maker).to have_received(:call).with(
        model, model_structure
      )
    end
    it 'calls the server view maker with the model' do
      test_maker(server_view_maker, model)
    end
  end
end
