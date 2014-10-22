require 'ury_rapid/launcher'
require 'ury_rapid/modules/set'
require 'ury_rapid/modules/root'

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
    vm = environment_maker
    lm = logger_maker
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
      make_environment_with vm
    end
  end

  let(:user_name) { double(:user_name) }

  MAKERS = %i(app auth channel logger environment)

  MAKERS.each do |maker|
    sym = "#{maker}_maker".to_sym
    let(sym) { double(sym) }
    let(maker) { double(maker) }
  end

  let(:model)                  { double(:model)                  }
  let(:model_class)            { double(:model_class)            }

  let(:server)                 { double(:server)                 }
  let(:server_id)              { double(:server_id)              }
  let(:server_class)           { double(:server_class)           }

  let(:service)                 { double(:service)                 }
  let(:service_id)              { double(:service_id)              }
  let(:service_class)           { double(:service_class)           }

  let(:service_config) { double(:service_config) }
  let(:server_config) { double(:server_config) }
  let(:user_config) { double(:user_config) }

  describe '#run' do
    before(:each) do
      allow(app_maker).to receive(:call).and_return(app)
      allow(auth_maker).to receive(:call).and_return(auth)
      allow(channel_maker).to receive(:call).and_return(channel)
      allow(logger_maker).to receive(:call).and_return(logger)

      allow(environment_maker).to receive(:call).and_return(environment)

      allow(environment).to receive(:post)

      allow(app).to receive(:run)

      allow(service_class).to receive(:new).and_return(service)

      allow(server_class).to receive(:new).and_return(server)
    end

    def test_maker(maker, *args)
      expect(maker).to receive(:call).once.with(*args)
      subject.run
    end

    it 'calls the app maker with the root module' do
      subject.run
      expect(app_maker).to have_received(:call).once.with(
        a_kind_of(Rapid::Modules::Root)
          .and(respond_to(:enabled))
          .and(satisfy { |ms| ms.enabled.include?(service_id) })
          .and(satisfy { |ms| ms.enabled.include?(server_id) })
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
  end
end
