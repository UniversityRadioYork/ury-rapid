require 'spec_helper'

require 'bra/common/config_authenticator'
require 'bra/common/exceptions'

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

  subject { Bra::Common::ConfigAuthenticator.new(config) }

  describe '#authenticate' do
    context 'when the user and password are valid strings' do
      it 'returns a privilege set matching the config' do
        privs = subject.authenticate('test', 'hunter2')
        expect(privs.has?(:get, :channel_set)).to be_true
        expect(privs.has?(:put, :channel_set)).to be_false
        expect(privs.has?(:get, :channel)).to be_true
        expect(privs.has?(:put, :channel)).to be_true
        expect(privs.has?(:get, :player)).to be_false
        expect(privs.has?(:put, :player)).to be_false
      end
    end
    context 'when the user and password are valid symbols' do
      it 'returns a privilege set matching the config' do
        privs = subject.authenticate(:test, :hunter2)
        expect(privs.has?(:get, :channel_set)).to be_true
        expect(privs.has?(:put, :channel_set)).to be_false
        expect(privs.has?(:get, :channel)).to be_true
        expect(privs.has?(:put, :channel)).to be_true
        expect(privs.has?(:get, :player)).to be_false
        expect(privs.has?(:put, :player)).to be_false
      end
    end
    context 'when the user is not authorised' do
      it 'fails with an AuthenticationFailure' do
        expect { subject.authenticate(:wrong, :hunter2) }.to raise_error(
          Bra::Common::Exceptions::AuthenticationFailure
        )
      end
    end
    context 'when the password is incorrect' do
      it 'fails with an AuthenticationFailure' do
        expect { subject.authenticate(:test, :wrong) }.to raise_error(
          Bra::Common::Exceptions::AuthenticationFailure
        )
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
