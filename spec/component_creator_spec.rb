require 'spec_helper'
require 'bra/model/component_creator'

shared_examples 'a valid symbol constant' do |type, value|
  it "returns an object whose flat representation is :#{value}" do
    created = subject.send(type, value)
    expect(created.flat).to eq(value.to_sym)
  end
end

shared_examples 'a symbol constant' do |type, valid_list|
  valid_list.each do |valid|
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
  describe '#load_state' do
    it_behaves_like(
      'a symbol constant',
      :load_state,
      Bra::Common::Types::LOAD_STATES
    )
  end

  describe '#play_state' do
    it_behaves_like(
      'a symbol constant',
      :play_state,
      Bra::Common::Types::PLAY_STATES
    )
  end
end

