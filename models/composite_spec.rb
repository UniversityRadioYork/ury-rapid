require_relative 'composite'

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
        hmo.add_child('shazam', :marvel)
        expect(hmo.children).to eq({ marvel: 'shazam' })
        hmo.add_child('scoosh', 3)
        expect(hmo.children).to eq({ marvel: 'shazam', 3 => 'scoosh' })
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        hmo.add_child('scoosh', :cillit)
        expect(hmo.children).to eq({ cillit: 'scoosh' })
        hmo.add_child('bang', :cillit)
        expect(hmo.children).to eq({ cillit: 'bang' })
      end
    end
  end
  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        hmo.add_child('shazam', :spoo)
        hmo.remove_child(:spoo)
        expect(hmo.children).to eq({})
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        hmo.add_child('shazam', :spoo)
        hmo.remove_child(:flub)
        expect(hmo.children).to eq({ spoo: 'shazam' })
      end
    end
  end
  describe '#child' do
    context 'with a valid integer ID' do
      it 'returns the child at that ID' do
        hmo.add_child('shazam', 42)
        expect(hmo.child(42)).to eq('shazam')
      end
    end
    context 'with a valid string ID' do
      it 'returns the child at that ID' do
        hmo.add_child('fawkes', 42)
        hmo.add_child('shazam', '42')
        expect(hmo.child('42')).to eq('shazam')
      end
    end
    context 'with a valid string ID matching an integer ID' do
      it 'returns the child at that integer ID' do
        hmo.add_child('fawkes', 42)
        expect(hmo.child('42')).to eq('fawkes')
      end
    end
    context 'with a valid string ID matching a symbol ID' do
      it 'returns the child at that symbol ID' do
        hmo.add_child('granma', :foop)
        expect(hmo.child('foop')).to eq('granma')
      end
    end
    context 'with an unused ID' do
      it 'returns nil' do
        expect(hmo.child(42)).to be_nil
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
        lmo.add_child('shazam', 0)
        expect(lmo.children).to eq(['shazam'])
        lmo.add_child('scoosh', 3)
        expect(lmo.children).to eq(['shazam', nil, nil, 'scoosh'])
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        lmo.add_child('scoosh', 3)
        expect(lmo.children).to eq([nil, nil, nil, 'scoosh'])
        lmo.add_child('bang', 3)
        expect(lmo.children).to eq([nil, nil, nil, 'bang'])
      end
    end
  end
  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        lmo.add_child('shazam', 0)
        lmo.remove_child(0)
        expect(lmo.children).to eq([])
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        lmo.add_child('shazam', 0)
        lmo.remove_child(3)
        expect(lmo.children).to eq(['shazam'])
      end
    end
  end
  describe '#child' do
    context 'with a valid integer ID' do
      it 'returns the child at that ID' do
        lmo.add_child('shazam', 42)
        expect(lmo.child(42)).to eq('shazam')
      end
    end
    context 'with a valid string ID' do
      it 'returns the child at the integer equivalent of that ID' do
        lmo.add_child('shazam', 42)
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
        lmo.add_child('shazam', 42)
        expect(lmo.child(:yabba_dabba_doo)).to be_nil
      end
    end
  end
end
