require_relative 'composite'
require_relative 'variable'

describe Bra::Models::HashModelObject do
  let(:hmo) { Bra::Models::HashModelObject.new }

  describe '#initialize' do
    it 'initialises with no children' do
      expect(hmo.children).to eq({})
    end
  end
  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        hmo.add_child(:marvel, 'shazam')
        expect(hmo.children).to eq({ marvel: 'shazam' })
        hmo.add_child(3, 'scoosh')
        expect(hmo.children).to eq({ marvel: 'shazam', 3 => 'scoosh' })
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        hmo.add_child(:cillit, 'scoosh')
        expect(hmo.children).to eq({ cillit: 'scoosh' })
        hmo.add_child(:cillit, 'bang')
        expect(hmo.children).to eq({ cillit: 'bang' })
      end
    end
  end
  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        hmo.add_child(:spoo, 'shazam')
        hmo.remove_child(:spoo)
        expect(hmo.children).to eq({})
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        hmo.add_child(:spoo, 'shazam')
        hmo.remove_child(:flub)
        expect(hmo.children).to eq({ spoo: 'shazam' })
      end
    end
  end
  describe '#child' do
    context 'with a valid integer ID' do
      it 'returns the child at that ID' do
        hmo.add_child(42, 'shazam')
        expect(hmo.child(42)).to eq('shazam')
      end
    end
    context 'with a valid string ID' do
      it 'returns the child at that ID' do
        hmo.add_child(42, 'fawkes')
        hmo.add_child('42', 'shazam')
        expect(hmo.child('42')).to eq('shazam')
      end
    end
    context 'with a valid string ID matching an integer ID' do
      it 'returns the child at that integer ID' do
        hmo.add_child(42, 'fawkes')
        expect(hmo.child('42')).to eq('fawkes')
      end
    end
    context 'with a valid string ID matching a symbol ID' do
      it 'returns the child at that symbol ID' do
        hmo.add_child(:foop, 'granma')
        expect(hmo.child('foop')).to eq('granma')
      end
    end
    context 'with an unused ID' do
      it 'returns nil' do
        expect(hmo.child(42)).to be_nil
      end
    end
  end
  describe '#each' do
    context 'with a block' do
      it 'runs it on each child' do
        count = 0
        hmo.add_child(:karl, :marx )
        hmo.add_child(:friedrich, :engels )
        hmo.add_child(:vladimir, :lenin )
        hmo.each do |child|
          expect(hmo.children.values).to include(child)
          count += 1
        end
        # The child's ID won't necessarily be the one we've put it in here
        # at.
        expect(count).to eq(3)
      end
    end
    context 'without a block' do
      it 'returns an enumerator' do
        expect(hmo.each.is_a?(Enumerator)).to be_true
      end
    end
  end
end

describe Bra::Models::ListModelObject do
  let(:lmo) { Bra::Models::ListModelObject.new }

  describe '#initialize' do
    it 'initialises with no children' do
      expect(lmo.children).to eq([])
    end
  end
  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        lmo.add_child(0, 'shazam')
        expect(lmo.children).to eq(['shazam'])
        lmo.add_child(3, 'scoosh')
        expect(lmo.children).to eq(['shazam', nil, nil, 'scoosh'])
      end
    end
    context 'with an ID already in use' do
      it 'inserts before the existing child' do
        lmo.add_child(3, 'scoosh')
        expect(lmo.children).to eq([nil, nil, nil, 'scoosh'])
        lmo.add_child(3, 'bang')
        expect(lmo.children).to eq([nil, nil, nil, 'bang', 'scoosh'])
      end
    end
  end
  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        lmo.add_child(0, 'shazam')
        lmo.remove_child(0)
        expect(lmo.children).to eq([])
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        lmo.add_child(0, 'shazam')
        lmo.remove_child(3)
        expect(lmo.children).to eq(['shazam'])
      end
    end
    context 'with an ID in use, and children with greater IDs' do
      it 'removes the item and reduces the IDs of those children by one' do
        Bra::Models::Constant.new('good morning').move_to(lmo, 0)
        Bra::Models::Constant.new('starshine').move_to(lmo, 1)
        Bra::Models::Constant.new('the Earth says').move_to(lmo, 2)
        Bra::Models::Constant.new('hello!').move_to(lmo, 3)
        Bra::Models::Constant.new('etaoin shrdlu').move_to(lmo, 4)

        lmo.remove_child(2)

        expect(lmo.child(0).value).to eq('good morning')
        expect(lmo.child(1).value).to eq('starshine')
        expect(lmo.child(2).value).to eq('hello!')
        expect(lmo.child(3).value).to eq('etaoin shrdlu')

        (0...4).each { |i| expect(lmo.child(i).id).to eq(i) }
      end
    end
  end
  describe '#child' do
    context 'with a valid integer ID' do
      it 'returns the child at that ID' do
        lmo.add_child(42, 'shazam')
        expect(lmo.child(42)).to eq('shazam')
      end
    end
    context 'with a valid string ID' do
      it 'returns the child at the integer equivalent of that ID' do
        lmo.add_child(42, 'shazam')
        expect(lmo.child('42')).to eq('shazam')
      end
    end
    context 'with an unused ID' do
      it 'returns nil' do
        expect(lmo.child(42)).to be_nil
      end
    end
    context 'with an invalid ID' do
      it 'returns nil' do
        lmo.add_child(42, 'shazam')
        expect(lmo.child(:yabba_dabba_doo)).to be_nil
      end
    end
  end
  describe '#each' do
    context 'with a block' do
      it 'runs it on each child' do
        count = 0
        lmo.add_child(0, :marx )
        lmo.add_child(1, :engels )
        lmo.add_child(2, :lenin )
        lmo.each do |child|
          expect(lmo.children).to include(child)
          count += 1
        end
        # The child's ID won't necessarily be the one we've put it in here
        # at.
        expect(count).to eq(3)
      end
    end
    context 'without a block' do
      it 'returns an enumerator' do
        expect(lmo.each.is_a?(Enumerator)).to be_true
      end
    end
  end

end
