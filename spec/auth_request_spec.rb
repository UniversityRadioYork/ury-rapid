require 'ury-rapid/server'

# Used for verifying doubles.
require 'kankri'
require 'rack'

describe Rapid::Server::AuthRequest do
  describe '#run' do
    context 'when the Rack request yields valid credentials' do
      it 'returns the privileges set given by the authenticator' do
        symbols = %i(foo bar baz)

        rake_request = instance_double(
          'Rack::Auth::Basic::Request',
          provided?: true,
          basic?: true,
          credentials: ['a_username', 'secret_password']
        )

        authenticator = instance_double('Kankri::SimpleAuthenticator')
        allow(authenticator).to receive(:authenticate) do |username, password|
          fail(Kankri::AuthenticationFailure) unless username == 'a_username'
          fail(Kankri::AuthenticationFailure) unless password == 'secret_password'
          symbols
        end

        ar = Rapid::Server::AuthRequest.new(authenticator, rake_request)

        expect(ar.run).to contain_exactly(*symbols)
      end
    end
  end
end
