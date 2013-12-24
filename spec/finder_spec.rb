require 'bra/common/exceptions'
require 'bra/model'

describe Bra::Model::Finder do
  subject { Bra::Model::Finder.new(root, url) }
  let(:root) { Bra::Model::HashModelObject.new }
  let(:foo) { Bra::Model::HashModelObject.new }
  let(:bar) { Bra::Model::HashModelObject.new }
  let(:baz) { Bra::Model::HashModelObject.new }
  let(:error) { Bra::Common::Exceptions::MissingResource }

  before(:each) do
    foo.move_to(root, :foo)
    bar.move_to(foo, :bar)
    baz.move_to(foo, :baz)
  end

  describe '#run' do
    context 'when the URL is the empty string' do
      let(:url) { '' }

      it 'yields the root node' do
        expect { |b| subject.run(&b) }.to yield_with_args(root)
      end
    end
    context 'when the URL is nil' do
      let(:url) { nil }

      specify { expect { |b| subject.run(&b) }.to raise_error }
    end
    context 'when the URL refers to a valid child of the model' do
      let(:url) { 'foo' }

      it 'returns that child' do
        expect { |b| subject.run(&b) }.to yield_with_args(foo)
      end
    end
    context 'when the URL refers to a valid descendant of the model' do
      let(:url) { 'foo/bar' }

      it 'returns that descendant' do
        expect { |b| subject.run(&b) }.to yield_with_args(bar)
      end
    end
    context 'when the URL refers to an invalid child of the model root' do
      let(:url) { 'bank' }

      specify { expect { |b| subject.run(&b) }.to raise_error(error) }
    end
    context 'when the URL refers to an invalid descendant of the model' do
      let(:url) { 'foo/bank' }

      specify { expect { |b| subject.run(&b) }.to raise_error(error) }
    end
  end
end
