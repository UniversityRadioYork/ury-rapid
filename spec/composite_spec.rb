require 'bra/models/composite'
require 'bra/models/variable'

describe Bra::Models::HashModelObject do
  describe '#initialize' do
    it 'initialises with no children' do
      expect(subject.children).to eq({})
    end
  end
  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        subject.add_child(:marvel, 'shazam')
        expect(subject.children).to eq({ marvel: 'shazam' })
        subject.add_child(3, 'scoosh')
        expect(subject.children).to eq({ marvel: 'shazam', 3 => 'scoosh' })
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        subject.add_child(:cillit, 'scoosh')
        expect(subject.children).to eq({ cillit: 'scoosh' })
        subject.add_child(:cillit, 'bang')
        expect(subject.children).to eq({ cillit: 'bang' })
      end
    end
  end
  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        subject.add_child(:spoo, 'shazam')
        subject.remove_child(:spoo)
        expect(subject.children).to eq({})
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        subject.add_child(:spoo, 'shazam')
        subject.remove_child(:flub)
        expect(subject.children).to eq({ spoo: 'shazam' })
      end
    end
  end
  describe '#child' do
    context 'with a valid integer ID' do
      it 'returns the child at that ID' do
        subject.add_child(42, 'shazam')
        expect(subject.child(42)).to eq('shazam')
      end
    end
    context 'with a valid string ID' do
      it 'returns the child at that ID' do
        subject.add_child(42, 'fawkes')
        subject.add_child('42', 'shazam')
        expect(subject.child('42')).to eq('shazam')
      end
    end
    context 'with a valid string ID matching an integer ID' do
      it 'returns the child at that integer ID' do
        subject.add_child(42, 'fawkes')
        expect(subject.child('42')).to eq('fawkes')
      end
    end
    context 'with a valid string ID matching a symbol ID' do
      it 'returns the child at that symbol ID' do
        subject.add_child(:foop, 'granma')
        expect(subject.child('foop')).to eq('granma')
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
        count = 0
        subject.add_child(:karl, :marx)
        subject.add_child(:friedrich, :engels)
        subject.add_child(:vladimir, :lenin)

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
end

describe Bra::Models::ListModelObject do
  describe '#initialize' do
    it 'initialises with no children' do
      expect(subject.children).to eq([])
    end
  end
  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        subject.add_child(0, 'shazam')
        expect(subject.children).to eq(['shazam'])
        subject.add_child(3, 'scoosh')
        expect(subject.children).to eq(['shazam', nil, nil, 'scoosh'])
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
        subject.add_child(0, 'shazam')
        subject.remove_child(0)
        expect(subject.children).to eq([])
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        subject.add_child(0, 'shazam')
        subject.remove_child(3)
        expect(subject.children).to eq(['shazam'])
      end
    end
    context 'with an ID in use, and children with greater IDs' do
      def populate
        Bra::Models::Constant.new('good morning').move_to(subject, 0)
        Bra::Models::Constant.new('starshine').move_to(subject, 1)
        Bra::Models::Constant.new('the Earth says').move_to(subject, 2)
        Bra::Models::Constant.new('hello!').move_to(subject, 3)
        Bra::Models::Constant.new('etaoin shrdlu').move_to(subject, 4)
      end

      it 'removes the item' do
        populate
        subject.remove_child(2)

        expect(subject.child(0).value).to eq('good morning')
        expect(subject.child(1).value).to eq('starshine')
        expect(subject.child(2).value).to eq('hello!')
        expect(subject.child(3).value).to eq('etaoin shrdlu')
      end
      it 'reduces the IDs of those children by one' do
        populate

        subject.remove_child(2)

        (0...4).each { |i| expect(subject.child(i).id).to eq(i) }
      end
    end
  end
  describe '#child' do
    context 'with a valid integer ID' do
      it 'returns the child at that ID' do
        subject.add_child(42, 'shazam')
        expect(subject.child(42)).to eq('shazam')
      end
    end
    context 'with a valid string ID' do
      it 'returns the child at the integer equivalent of that ID' do
        subject.add_child(42, 'shazam')
        expect(subject.child('42')).to eq('shazam')
      end
    end
    context 'with an unused ID' do
      it 'returns nil' do
        expect(subject.child(42)).to be_nil
      end
    end
    context 'with an invalid ID' do
      it 'returns nil' do
        subject.add_child(42, 'shazam')
        expect(subject.child(:yabba_dabba_doo)).to be_nil
      end
    end
  end
  describe '#each' do
    context 'with a block' do
      it 'runs it on each child' do
        count = 0
        subject.add_child(0, :marx)
        subject.add_child(1, :engels)
        subject.add_child(2, :lenin)

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
