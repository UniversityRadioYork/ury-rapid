require 'spec_helper'

require 'bra/common/payload'

describe Bra::Common::Payload do
  subject { Bra::Common::Payload.new(payload, privilege_set, default_id) }
  let(:payload) { double(:payload) }
  let(:privilege_set) { double(:privilege_set) }
  let(:default_id) { double(:default_id) }

  describe '#id' do
    context 'when the payload body is a Hash with one key' do
      let(:payload) { { test_id: :body } }
      it 'returns that key' do
        expect(subject.id).to eq(:test_id)
      end
    end
    context 'when the payload body is a Hash with multiple keys' do
      let(:payload) { { test_id: :body, foo: :Bar } }
      it 'returns the default ID' do
        expect(subject.id).to eq(default_id)
      end
    end
    context 'when the payload body is an empty Hash' do
      let(:payload) { {} }
      it 'returns the default ID' do
        expect(subject.id).to eq(default_id)
      end
    end
    context 'when the payload body is not a Hash' do
      let(:payload) { 'Test String' }
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
end
