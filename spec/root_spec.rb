require 'spec_helper'

require 'bra/model'

describe Bra::Model::Root do
  describe '#id' do
    specify { expect(subject.id).to eq '' }
  end

  describe '#parent_url' do
    specify { expect { subject.parent_url }.to raise_error }
  end

  describe '#url' do
    specify { expect(subject.url).to eq '' }
  end
end
