require 'spec_helper'
require 'bra/model/component_creator'
require 'bra/model'

shared_examples 'a valid symbol constant' do |type, value|
  it "returns an object whose flat representation is :#{value}" do
    created = subject.send(type, value)
    expect(created.flat).to eq(value.to_sym)
  end
end

shared_examples 'a successful factory method' do |type, value|
  it 'sends the registrar #register with an object to register' do
    expect(registrar).to receive(:register).once do |arg|
      expect(arg).to be_a(Bra::Model::ModelObject)
    end
    subject.send(type, value)
  end
end

shared_examples 'a symbol constant' do |type, valid_list|
  valid_list.each do |valid|
    it_behaves_like 'a successful factory method', type, valid

    context "when the argument is :#{valid}" do
      it_behaves_like 'a valid symbol constant', type, valid
    end
    context "when the argument is '#{valid}'" do
      it_behaves_like 'a valid symbol constant', type, valid.to_s
    end
  end

  context 'when the argument is invalid' do
    specify { expect { subject.send(type, :xyzzy) }.to raise_error }
  end

  context 'when the argument is nil' do
    specify { expect { subject.send(type, nil) }.to raise_error }
  end
end

describe Bra::Model::ComponentCreator do
  subject { Bra::Model::ComponentCreator.new(registrar) }
  let(:registrar) { double(:registrar) }
  before(:each) { allow(registrar).to receive(:register) }

  describe '#load_state' do
    it_behaves_like(
      'a symbol constant', :load_state, Bra::Common::Types::LOAD_STATES
    )
  end

  describe '#play_state' do
    it_behaves_like(
      'a symbol constant', :play_state, Bra::Common::Types::PLAY_STATES
    )
  end
end

