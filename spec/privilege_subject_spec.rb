require 'spec_helper'

require 'bra/common/privilege_set'

class MockPrivilegeSubject
  include Bra::Common::PrivilegeSubject

  def privilege_key
    :fake_key
  end
end

describe MockPrivilegeSubject do
  let(:privilege_set) { double(:privilege_set) }
  let(:operation) { double(:operation) }

  {fail_if_cannot: :require, can?: :has?}.each do |subject_meth, set_meth|
    describe "##{subject_meth}" do
      context 'when given a valid privilege set and operation' do
        it 'calls ##{set_meth} on the privilege set with the handler target' do
          expect(privilege_set).to receive(set_meth).once.with(
            operation, subject.privilege_key
          )
          subject.send(subject_meth, operation, privilege_set)
        end
      end
    end
  end
end
