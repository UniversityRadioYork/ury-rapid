require_relative 'composite'

describe Bra::Models::HashModelObject do
  before :each do
    @hmo = Bra::Models::HashModelObject.new
  end

  describe '#initialize' do
    it 'initialises with no children' do
      @hmo.children.should eq({})
    end
  end
  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        @hmo.add_child('shazam', :marvel)
        @hmo.children.should eq({ marvel: 'shazam' })
        @hmo.add_child('scoosh', 3)
        @hmo.children.should eq({ marvel: 'shazam', 3 => 'scoosh' })
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        @hmo.add_child('scoosh', :cillit)
        @hmo.children.should eq({ cillit: 'scoosh' })
        @hmo.add_child('bang', :cillit)
        @hmo.children.should eq({ cillit: 'bang' })
      end
    end
  end
  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        @hmo.add_child('shazam', :spoo)
        @hmo.remove_child(:spoo)
        @hmo.children.should eq({})
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        @hmo.add_child('shazam', :spoo)
        @hmo.remove_child(:flub)
        @hmo.children.should eq({ spoo: 'shazam' })
      end
    end
  end
end

describe Bra::Models::ListModelObject do
  before :each do
    @lmo = Bra::Models::ListModelObject.new
  end

  describe '#initialize' do
    it 'initialises with no children' do
      @lmo.children.should eq([])
    end
  end
  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        @lmo.add_child('shazam', 0)
        @lmo.children.should eq(['shazam'])
        @lmo.add_child('scoosh', 3)
        @lmo.children.should eq(['shazam', nil, nil, 'scoosh'])
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        @lmo.add_child('scoosh', 3)
        @lmo.children.should eq([nil, nil, nil, 'scoosh'])
        @lmo.add_child('bang', 3)
        @lmo.children.should eq([nil, nil, nil, 'bang'])
      end
    end
  end
  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        @lmo.add_child('shazam', 0)
        @lmo.remove_child(0)
        @lmo.children.should eq([])
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        @lmo.add_child('shazam', 0)
        @lmo.remove_child(3)
        @lmo.children.should eq(['shazam'])
      end
    end
  end
end
