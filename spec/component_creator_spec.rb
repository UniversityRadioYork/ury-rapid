require 'spec_helper'
require 'bra/model/component_creator'

shared_examples 'a symbol constant' do |type, valid_list|
  valid_list.each do |valid|
    context "when the argument is :#{valid}" do
      it "returns an object whose flat representation is :#{valid}" do
        created = subject.create(type, valid)
        expect(created.flat).to eq(valid)
      end
    end
  end

  context 'when the argument is invalid' do
    specify { expect { subject.create(type, :xyzzy) }.to raise_error }
  end

  context 'when the argument is nil' do
    specify { expect { subject.create(type, nil) }.to raise_error }
  end
end

describe Bra::Model::ComponentCreator do
  describe '#create' do
    context 'when the type is :load_state' do
      it_behaves_like(
        'a symbol constant',
        :load_state,
        Bra::Common::Types::LOAD_STATES
      )
    end

    context 'when the type is :play_state' do
      it_behaves_like(
        'a symbol constant',
        :play_state,
        Bra::Common::Types::PLAY_STATES
      )
    end
  end
end

