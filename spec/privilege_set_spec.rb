require 'spec_helper'

require 'bra/common/privilege_set'

describe Bra::Common::PrivilegeSet do
  subject do
    Bra::Common::PrivilegeSet.new(
      foo: [:get, :put],
      bar: :all
    )
  end

  describe '#require' do
    context 'when #has? returns true' do
      it 'does nothing' do
        allow(subject).to receive(:has?).and_return(true)
        subject.require(:get, :foo)
      end
    end
    context 'when #has? returns false' do
      it 'fails' do
        allow(subject).to receive(:has?).and_return(false)
        expect { subject.require(:get, :foo) }.to raise_error
      end
    end
  end

  describe '#has?' do
    context 'when given a valid target' do
      context 'and the privilege is directly in the PrivilegeSet' do
        context 'and the privilege and target are both Symbols' do
          it('returns true') { expect(subject.has?(:get, :foo)).to be_true }
        end
        context 'and the privilege and target are both Strings' do
          it('returns true') { expect(subject.has?('get', 'foo')).to be_true }
        end
        context 'and the privilege is a Symbol and the target is a String' do
          it('returns true') { expect(subject.has?(:get, 'foo')).to be_true }
        end
        context 'and the privilege is a String and the target is a Symbol' do
          it('returns true') { expect(subject.has?('get', :foo)).to be_true }
        end
      end
      context 'and the target is covered by an :all' do
        context 'and the privilege and target are both Symbols' do
          it('returns true') { expect(subject.has?(:get, :bar)).to be_true }
        end
        context 'and the privilege and target are both Strings' do
          it('returns true') { expect(subject.has?('get', 'bar')).to be_true }
        end
        context 'and the privilege is a Symbol and the target is a String' do
          it('returns true') { expect(subject.has?(:get, 'bar')).to be_true }
        end
        context 'and the privilege is a String and the target is a Symbol' do
          it('returns true') { expect(subject.has?('get', :bar)).to be_true }
        end
      end
      context 'and the privilege is not allowed for that target' do
        it('returns false') { expect(subject.has?(:delete, :foo)).to be_false }
      end
    end
    context 'when given a target not in the PrivilegeSet' do
      it 'returns false' do
        expect(subject.has?(:get, :baz)).to be_false
        expect(subject.has?(:put, :baz)).to be_false
      end
    end
  end
end
