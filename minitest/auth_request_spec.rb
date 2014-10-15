require 'minitest/autorun'
require 'ury_rapid/server/auth_request'

describe Rapid::Server::AuthRequest do
  it 'cannot be constructed with a null authenticator' do
    proc { Rapid::Server::AuthRequest.new(nil, Minitest::Mock.new) }
      .must_raise(ArgumentError)
  end

  it 'cannot be constructed with a authenticator that cannot authenticate' do
    bad_auth = Minitest::Mock.new
    bad_auth.expect :nil?, :false

    proc { Rapid::Server::AuthRequest.new(bad_auth, Minitest::Mock.new) }
      .must_raise(ArgumentError)
  end

end
