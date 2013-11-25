require_relative 'privilege_set'

describe Bra::Common::PrivilegeSet do
  let(:ps) do
    Bra::Common::PrivilegeSet.new(
      foo: [:bar, :baz],
      foofoo: :all
    )
  end
  describe '#has?' do
    context 'with a target and privilege directly in the privilege set' do
      it 'returns true' do
        expect(ps.has?(:foo, :bar)).to be_true
        expect(ps.has?('foo', 'bar')).to be_true
        expect(ps.has?(:foo, 'bar')).to be_true
      end
    end
    context 'with a target and privilege covered by an :all' do
      it 'returns true' do
        expect(ps.has?(:foofoo, :bar)).to be_true
        expect(ps.has?(:foofoo, :baz)).to be_true
        expect(ps.has?('foofoo', 'baz')).to be_true
        expect(ps.has?(:foofoo, 'baz')).to be_true
      end
    end
    context 'with a privilege not covered for a valid target' do
      it 'returns false' do
        expect(ps.has?(:foo, :quux)).to be_false
      end
    end
    context 'with a target not covered' do
      it 'returns false' do
        expect(ps.has?(:swab, :bar)).to be_false
        expect(ps.has?(:swab, :quux)).to be_false
      end
    end
  end
end
