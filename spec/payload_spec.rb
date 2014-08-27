require 'spec_helper'

require 'rapid/common/payload'

describe Rapid::Common::Payload do
  subject { Rapid::Common::Payload.new(body, privilege_set, default_id) }
  let(:body) { double(:body) }
  let(:privilege_set) { double(:privilege_set) }
  let(:default_id) { double(:default_id) }
  let(:integer) { 2401 }
  let(:float) { 240.1 }

  describe '#id' do
    context 'when the payload body is a Hash with one key' do
      context 'and the key is a String representing an Integer' do
        let(:body) { { '300' => :body } }
        it 'returns that key as an Integer' do
          expect(subject.id).to eq(300)
        end
      end
      context 'and the key is not a String representing an Integer' do
        let(:body) { { test_id: :body } }
        it 'returns that key' do
          expect(subject.id).to eq(:test_id)
        end
      end
    end
    context 'when the payload body is a Hash with multiple keys' do
      let(:body) { { test_id: :body, foo: :Bar } }
      it 'returns the default ID' do
        expect(subject.id).to eq(default_id)
      end
    end
    context 'when the payload body is an empty Hash' do
      let(:body) { {} }
      it 'returns the default ID' do
        expect(subject.id).to eq(default_id)
      end
    end
    context 'when the payload body is not a Hash' do
      let(:body) { 'Test String' }
      it 'returns the default ID' do
        expect(subject.id).to eq(default_id)
      end
    end
  end

  describe '#with_body' do
    it 'creates a new Payload' do
      new_payload = subject.with_body(double(:new_payload))
      expect(new_payload).to_not be(subject)
    end
  end

  describe '#process' do
    let(:receiver) { double(:receiver) }

    context 'when the body is a hash' do
      # Note that hashes with one key are taken to be mapping an explicit ID
      # to the actual body, hence why we test with two-key hashes.
      context 'and the hash has a Symbol parameter' do
        let(:body) { { type: :test_type, foo: :bar } }
        it 'calls #hash on the argument, with the type and rest of the hash' do
          expect(receiver).to receive(:hash).with(body[:type], foo: :bar)

          subject.process(receiver)
        end
        it 'does not mutate the input hash' do
          body2 = body.clone

          allow(receiver).to receive(:hash)
          subject.process(receiver)
          expect(body2).to eq(body)
        end
      end
      context 'and the hash has a String parameter' do
        let(:body) { { type: 'XBaps', foo: :bar } }
        it 'calls #hash on the argument, with downcase Symbol type and body' do
          expect(receiver).to receive(:hash).with(
            body[:type].downcase.intern, foo: :bar
          )

          subject.process(receiver)
        end
        it 'does not mutate the input hash' do
          body2 = body.clone

          allow(receiver).to receive(:hash)
          subject.process(receiver)
          expect(body2).to eq(body)
        end
      end
      context 'and the hash has no type parameter' do
        let(:body) { { bar: :baz, foo: :bar } }
        it 'calls #hash on the argument, with nil and the hash' do
          expect(receiver).to receive(:hash).with(nil, body)

          subject.process(receiver)
        end
        it 'does not mutate the input hash' do
          body2 = body.clone

          allow(receiver).to receive(:hash)
          subject.process(receiver)
          expect(body2).to eq(body)
        end
      end
    end

    context 'when the body is a URL or pseudo-URL' do
      let(:protocol) { 'a_protocol' }
      let(:rest) { 'a_body' }
      let(:body) { "#{protocol}://#{rest}" }
      it 'calls #string on the argument with the Symbol protocol, and body' do
        expect(receiver).to receive(:url).with(protocol.to_sym, rest)

        subject.process(receiver)
      end
    end
    context 'when the body is an Integer' do
      let(:body) { integer }
      it 'calls #integer on the argument, with the number' do
        expect(receiver).to receive(:integer).with(integer)

        subject.process(receiver)
      end
    end
    context 'when the body is a String representation of an integral number' do
      let(:body) { integer.to_s }
      it 'calls #integer on the argument, with the number as an Integer' do
        expect(receiver).to receive(:integer).with(integer)

        subject.process(receiver)
      end
    end
    context 'when the body is a Float' do
      let(:body) { float }
      it 'calls #float on the argument, with the number' do
        expect(receiver).to receive(:float).with(float)

        subject.process(receiver)
      end
    end
    context 'when the body is a String representation of a float' do
      let(:body) { float.to_s }
      it 'calls #float on the argument, with the number as a Float' do
        expect(receiver).to receive(:float).with(float)

        subject.process(receiver)
      end
    end
    context 'when the body is a normal String' do
      let(:body) { 'Normal String' }
      it 'calls #string on the argument with the string' do
        expect(receiver).to receive(:string).with(body)

        subject.process(receiver)
      end
    end
    context 'when the body is another object' do
      before(:each) do
        allow(body).to receive(:to_s).and_return('phenolphthalein')
      end

      it 'calls #string on the argument with the string form of the body' do
        expect(receiver).to receive(:string).with(body.to_s)

        subject.process(receiver)
      end
      it 'calls #to_s on the body' do
        allow(receiver).to receive(:string)
        expect(body).to receive(:to_s).once

        subject.process(receiver)
      end
    end
  end
end
