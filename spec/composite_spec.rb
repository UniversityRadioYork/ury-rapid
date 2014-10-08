require 'spec_helper'

require 'ury_rapid/model'

describe Rapid::Model::HashModelObject do
  subject { Rapid::Model::HashModelObject.new(target) }
  let(:target) { nil }
  let(:object1) { Rapid::Model::Constant.new(:test1) }
  let(:object2) { Rapid::Model::Constant.new(:test2) }
  let(:object3) { Rapid::Model::Constant.new(:test3) }
  let(:object4) { Rapid::Model::Constant.new(:test4) }
  let(:object5) { Rapid::Model::Constant.new(:test5) }

  describe '#initialize' do
    it 'initialises with no children' do
      expect(subject.children).to eq({})
    end
  end

  describe '#handler_target' do
    context 'when the handler_target is nil' do
      it 'returns the relative, underscored class name as a symbol' do
        expect(subject.handler_target).to eq(:hash_model_object)
      end
    end
    context 'when the handler_target is defined' do
      let(:target) { :angry_anderson }
      it 'returns that handler_target' do
        expect(subject.handler_target).to eq(:angry_anderson)
      end
    end
  end
end

describe Rapid::Model::ListModelObject do
  let(:object1) { Rapid::Model::Constant.new(:test1) }
  let(:object2) { Rapid::Model::Constant.new(:test2) }
  let(:object3) { Rapid::Model::Constant.new(:test3) }
  let(:object4) { Rapid::Model::Constant.new(:test4) }
  let(:object5) { Rapid::Model::Constant.new(:test5) }

  describe '#initialize' do
    it 'initialises with no children' do
      expect(subject.children).to eq({})
    end
  end
end
