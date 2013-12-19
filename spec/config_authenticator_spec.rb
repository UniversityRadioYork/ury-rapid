require_relative '../common/config_authenticator'

describe Bra::Common::ConfigAuthenticator do
  let(:config) do
    {
      test: {
        password: 'hunter2',
        privileges: {
          channel_set: ['get'],
          channel: 'all'
        }
      }
    }
  end
  let(:ca) { Bra::Common::ConfigAuthenticator.new(config) }

  describe '#authenticate' do
    context 'with a valid string user and password' do
      it 'returns a privilege set matching the config' do
        privs = ca.authenticate('test', 'hunter2')
        expect(privs.has?(:channel_set, :get)).to be_true
        expect(privs.has?(:channel_set, :put)).to be_false
        expect(privs.has?(:channel, :get)).to be_true
        expect(privs.has?(:channel, :put)).to be_true
        expect(privs.has?(:player, :get)).to be_false
        expect(privs.has?(:player, :put)).to be_false
      end
    end
    context 'with a valid symbol user and password' do
      it 'returns a privilege set matching the config' do
        privs = ca.authenticate(:test, :hunter2)
        expect(privs.has?(:channel_set, :get)).to be_true
        expect(privs.has?(:channel_set, :put)).to be_false
        expect(privs.has?(:channel, :get)).to be_true
        expect(privs.has?(:channel, :put)).to be_true
        expect(privs.has?(:player, :get)).to be_false
        expect(privs.has?(:player, :put)).to be_false
      end
    end
  end
end

describe Bra::Common::PasswordCheck do
  let(:passwords) { { test: :hunter2 } }
  let(:pc) { ->(u, p) { Bra::Common::PasswordCheck.new(u, p, passwords) } }

  describe '#ok?' do
    context 'with a valid string username and password' do
      it 'returns true' do
        expect(pc.call('test', 'hunter2').ok?).to be_true
      end
    end
    context 'with a valid symbol username and password' do
      it 'returns true' do
        expect(pc.call(:test, :hunter2).ok?).to be_true
      end
    end
    context 'with a valid username and invalid password' do
      it 'returns false' do
        expect(pc.call('test', 'nope').ok?).to be_false
      end
    end
    context 'with an invalid username and password' do
      it 'returns false' do
        expect(pc.call('toast', 'nope').ok?).to be_false
      end
    end
    context 'with a valid username and blank password' do
      it 'returns false' do
        expect(pc.call('test', '').ok?).to be_false
      end
    end
    context 'with a blank username and password' do
      it 'returns false' do
        expect(pc.call('', '').ok?).to be_false
      end
    end
    context 'with a valid username and nil password' do
      it 'returns false' do
        expect(pc.call('test', nil).ok?).to be_false
      end
    end
    context 'with a nil username and password' do
      it 'returns false' do
        expect(pc.call(nil, nil).ok?).to be_false
      end
    end
  end
end
