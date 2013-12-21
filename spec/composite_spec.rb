require 'spec_helper'

require 'bra/models/composite'
require 'bra/models/variable'

describe Bra::Models::HashModelObject do
  let(:object1) { Bra::Models::Constant.new(:test1) }
  let(:object2) { Bra::Models::Constant.new(:test2) }
  let(:object3) { Bra::Models::Constant.new(:test3) }
  let(:object4) { Bra::Models::Constant.new(:test4) }
  let(:object5) { Bra::Models::Constant.new(:test5) }

  describe '#initialize' do
    it 'initialises with no children' do
      expect(subject.children).to eq({})
    end
  end

  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        subject.add_child(:marvel, object1)
        expect(subject.children).to eq({ marvel: object1 })
        subject.add_child(3, object2)
        expect(subject.children).to eq({ marvel: object1, 3 => object2 })
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        subject.add_child(:cillit, object1)
        expect(subject.children).to eq({ cillit: object1 })
        subject.add_child(:cillit, object2)
        expect(subject.children).to eq({ cillit: object2 })
      end
    end
  end

  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        subject.add_child(:spoo, object1)
        subject.remove_child(:spoo)
        expect(subject.children).to eq({})
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        subject.add_child(:spoo, object1)
        subject.remove_child(:flub)
        expect(subject.children).to eq({ spoo: object1 })
      end
    end
  end

  describe '#child' do
    context 'with a valid integer ID' do
      it 'returns the child at that ID' do
        subject.add_child(42, object1)
        expect(subject.child(42)).to eq(object1)
      end
    end
    context 'with a valid string ID' do
      it 'returns the child at that ID' do
        subject.add_child(42, object1)
        subject.add_child('42', object2)
        expect(subject.child('42')).to eq(object2)
      end
    end
    context 'with a valid string ID matching an integer ID' do
      it 'returns the child at that integer ID' do
        subject.add_child(42, object1)
        expect(subject.child('42')).to eq(object1)
      end
    end
    context 'with a valid string ID matching a symbol ID' do
      it 'returns the child at that symbol ID' do
        subject.add_child(:foop, object1)
        expect(subject.child('foop')).to eq(object1)
      end
    end
    context 'with an unused ID' do
      it 'returns nil' do
        expect(subject.child(42)).to be_nil
      end
    end
  end

  describe '#each' do
    context 'with a block' do
      it 'runs it on each child' do
        subject.add_child(:shooby, object1)
        subject.add_child(:dooby, object2)
        subject.add_child(:doo, object3)

        expect { |b| subject.each(&b) }.to yield_successive_args(
          *subject.children.values
        )
      end
    end
    context 'without a block' do
      it 'returns an enumerator' do
        expect(subject.each).to be_an(Enumerator)
      end
    end
  end

  describe '#id_function' do
    context 'when given an object not in the HashModelObject' do
      it 'returns a proc that returns nil' do
        idf = subject.id_function(object1)
        expect(idf.call).to eq(nil)
      end
    end
    context 'when given an object in the HashModelObject' do
      it 'returns a proc that returns the object key' do
        object1.move_to(subject, :wozniak)
        idf = subject.id_function(object1)
        expect(idf.call).to eq(:wozniak)
      end
    end
  end
end

describe Bra::Models::ListModelObject do
  let(:object1) { Bra::Models::Constant.new(:test1) }
  let(:object2) { Bra::Models::Constant.new(:test2) }
  let(:object3) { Bra::Models::Constant.new(:test3) }
  let(:object4) { Bra::Models::Constant.new(:test4) }
  let(:object5) { Bra::Models::Constant.new(:test5) }

  describe '#initialize' do
    it 'initialises with no children' do
      expect(subject.children).to eq([])
    end
  end
  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        subject.add_child(0, object1)
        expect(subject.children).to eq([object1])
        subject.add_child(3, 'scoosh')
        expect(subject.children).to eq([object1, nil, nil, 'scoosh'])
      end
    end
    context 'with an ID already in use' do
      it 'inserts before the existing child' do
        subject.add_child(3, 'scoosh')
        expect(subject.children).to eq([nil, nil, nil, 'scoosh'])
        subject.add_child(3, 'bang')
        expect(subject.children).to eq([nil, nil, nil, 'bang', 'scoosh'])
      end
    end
  end
  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        subject.add_child(0, object1)
        subject.remove_child(0)
        expect(subject.children).to eq([])
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        subject.add_child(0, object1)
        subject.remove_child(3)
        expect(subject.children).to eq([object1])
      end
    end
    context 'with an ID in use, and children with greater IDs' do
      before(:each) do
        object1.move_to(subject, 0)
        object2.move_to(subject, 1)
        object3.move_to(subject, 2)
        object4.move_to(subject, 3)
        object5.move_to(subject, 4)
      end

      it 'removes the item' do
        subject.remove_child(2)

        expect(subject.child(0)).to eq(object1)
        expect(subject.child(1)).to eq(object2)
        expect(subject.child(2)).to eq(object4)
        expect(subject.child(3)).to eq(object5)
      end

      it 'reduces the IDs of those children by one' do
        subject.remove_child(2)

        (0...4).each { |i| expect(subject.child(i).id).to eq(i) }
      end
    end
  end
  describe '#child' do
    context 'with a valid integer ID' do
      it 'returns the child at that ID' do
        subject.add_child(42, object1)
        expect(subject.child(42)).to eq(object1)
      end
    end
    context 'with a valid string ID' do
      it 'returns the child at the integer equivalent of that ID' do
        subject.add_child(42, object1)
        expect(subject.child('42')).to eq(object1)
      end
    end
    context 'with an unused ID' do
      it 'returns nil' do
        expect(subject.child(42)).to be_nil
      end
    end
    context 'with an invalid ID' do
      it 'returns nil' do
        subject.add_child(42, object1)
        expect(subject.child(:yabba_dabba_doo)).to be_nil
      end
    end
  end

  describe '#each' do
    context 'with a block' do
      it 'runs it on each child' do
        subject.add_child(0, object1)
        subject.add_child(1, object2)
        subject.add_child(2, object3)

        expect { |b| subject.each(&b) }.to yield_successive_args(
          *subject.children
        )
      end
    end
    context 'without a block' do
      it 'returns an enumerator' do
        expect(subject.each).to be_an(Enumerator)
      end
    end
  end
end
