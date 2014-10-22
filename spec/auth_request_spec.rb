require 'ury_rapid/server'

# Used for verifying doubles.
require 'kankri'
require 'rack'

describe Rapid::Server::AuthRequest do
  describe '#run' do
    context 'when the Rack request has no provided credentials' do
      it 'raises an authentication error' do
        ar = auth_request_with_invalid_rack(false, true)
        expect { ar.run }.to raise_error(Kankri::AuthenticationFailure)
      end
    end

    context 'when the Rack request is not HTTP BASIC' do
      it 'raises an authentication error' do
        ar = auth_request_with_invalid_rack(true, false)
        expect { ar.run }.to raise_error(Kankri::AuthenticationFailure)
      end
    end

    context 'when the Rack request yields valid credentials' do
      context 'when the credentials are correct as per the authenticator' do
        it 'returns the privileges set given by the authenticator' do
          symbols     = %i(foo bar baz)
          credentials = %w(a_username secret_password)

          ar = auth_request_with_valid_rack(credentials, credentials, symbols)
          expect(ar.run).to contain_exactly(*symbols)
        end
      end

      context 'when the credentials are not correct' do
        it 'raises an authentication error' do
          symbols = %i(foo bar baz)
          right   = %w(right_username right_password)
          wrong   = %w(wrong_username wrong_password)

          ar = auth_request_with_valid_rack(wrong, right, symbols)
          expect { ar.run }.to raise_error(Kankri::AuthenticationFailure)
        end
      end
    end
  end
end

private

def mock_rake_request(username, password, provided, basic)
  instance_double('Rack::Auth::Basic::Request',
                  provided?: provided,
                  basic?: basic,
                  credentials: [username, password])
end

def mock_authenticator(username, password, symbols)
  instance_double('Kankri::SimpleAuthenticator').tap do |a|
    allow(a).to receive(:authenticate) do |u, p|
      fail(Kankri::AuthenticationFailure) unless u == username
      fail(Kankri::AuthenticationFailure) unless p == password
      symbols
    end
  end
end

def auth_request_with_valid_rack(user_creds, valid_creds, symbols)
  authenticator = mock_authenticator(*valid_creds, symbols)
  rake_request  = mock_rake_request(*user_creds, true, true)
  auth_request(authenticator, rake_request)
end

def auth_request_with_invalid_rack(provided, basic)
  fail('Either provided or basic must be false.') if provided && basic

  authenticator = double(:authenticator)
  rake_request  = mock_rake_request(double(:u), double(:p), provided, basic)
  allow(authenticator).to receive(:authenticate)
  auth_request(authenticator, rake_request)
end

def auth_request(authenticator, rake_request)
  Rapid::Server::AuthRequest.new(authenticator, rake_request)
end
