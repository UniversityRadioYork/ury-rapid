require_relative 'handler'

describe Bra::Baps::Requests::Handler do
  let(:handler) { Bra::Baps::Requests::Handler.new(nil) }

  describe '.split_url' do
    context 'with a valid lowercase URL' do
      it 'returns as an array the URL protocol and body' do
        expect(
          handler.class.split_url('http://example.com')
        ).to eq(['http', 'example.com'])
      end
    end
    context 'with a valid mixed-case URL' do
      it 'returns as an array the URL protocol, in lowercase, and body' do
        expect(
          handler.class.split_url('HTTP://FreeBSD.org')
        ).to eq(['http', 'FreeBSD.org'])
      end
    end
    context 'with a valid pseudo-URL' do
      it 'returns as an array the protocol and exact body' do
        expect(
          handler.class.split_url('x-baps://spaces are not allowed in URLs %20')
        ).to eq(['x-baps', 'spaces are not allowed in URLs %20'])
      end
    end
    context 'with a valid pseudo-URL containing ://' do
      it 'returns as an array the protocol and exact body' do
        expect(
          handler.class.split_url('x-BAPS://hollywood://reno')
        ).to eq(['x-baps', 'hollywood://reno'])
      end
    end
  end

  describe '.handle_url' do
    context 'with a valid URL or pseudo-url' do
      it 'splits the URL and yields it to a block, returning true' do
        u = 'HTTP://FreeBSD.org'
        a = nil
        expect { |b| a = handler.class.handle_url(u, &b) }.to yield_with_args(
          'http',
          'FreeBSD.org'
        )
        expect(a).to be_true
      end
    end
    context 'with a non-String object' do
      it 'bypasses the block and returns false' do
        u = { abc: 'HTTP://FreeBSD.org' }
        a = nil
        expect { |b| a = handler.class.handle_url(u, &b) }.not_to yield_control
        expect(a).to be_false
      end
    end
  end

  describe '.flatten_post' do
    context 'with a hash mapping an ID to an object' do
      it 'returns a tuple of that ID and that object' do
        expect(handler.class.flatten_post({ spoo: 10 }, :default)).to eq(
          [:spoo, 10]
        )
      end
    end
    context 'with a non-hash object' do
      it 'returns a tuple of the default ID and that object' do
        expect(handler.class.flatten_post(10, :default)).to eq(
          [:default, 10]
        )
      end
    end
    # TODO(mattbw): Hashes not mapping one key to one value.
  end
end
