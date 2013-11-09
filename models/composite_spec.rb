require_relative 'composite'

describe Bra::Models::HashModelObject do
  before :each do
    @hmo = Bra::Models::HashModelObject.new
  end

  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        @hmo.children.should == {}
        @hmo.add_child('shazam', :marvel)
        @hmo.children.should == {marvel: 'shazam'}
        @hmo.add_child('scoosh', 3)
        @hmo.children.should == {marvel: 'shazam', 3 => 'scoosh'}
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        @hmo.children.should == {}
        @hmo.add_child('scoosh', :cillit)
        @hmo.children.should == {cillit: 'scoosh'}
        @hmo.add_child('bang', :cillit)
        @hmo.children.should == {cillit: 'bang'}
      end
    end
  end

  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        @hmo.add_child('shazam', :spoo)
        @hmo.remove_child(:spoo)
        @hmo.children.should == {}
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        @hmo.add_child('shazam', :spoo)
        @hmo.remove_child(:flub)
        @hmo.children.should == {spoo: 'shazam'}
      end
    end
  end
end

describe Bra::Models::ListModelObject do
  before :each do
    @lmo = Bra::Models::ListModelObject.new
  end

  describe '#add_child' do
    context 'with an ID not yet used' do
      it 'adds the child into the object\'s children' do
        @lmo.children.should == []
        @lmo.add_child('shazam', 0)
        @lmo.children.should == ['shazam']
        @lmo.add_child('scoosh', 3)
        @lmo.children.should == ['shazam', nil, nil, 'scoosh']
      end
    end
    context 'with an ID already in use' do
      it 'replaces the existing child' do
        @lmo.children.should == []
        @lmo.add_child('scoosh', 3)
        @lmo.children.should == [nil, nil, nil, 'scoosh']
        @lmo.add_child('bang', 3)
        @lmo.children.should == [nil, nil, nil, 'bang']
      end
    end
  end

  describe '#remove_child' do
    context 'with an ID in use' do
      it 'removes the item' do
        @lmo.add_child('shazam', 0)
        @lmo.remove_child(0)
        @lmo.children.should == []
      end
    end
    context 'with an ID not in use' do
      it 'does nothing' do
        @lmo.add_child('shazam', 0)
        @lmo.remove_child(3)
        @lmo.children.should == ['shazam']
      end
    end
  end
end
