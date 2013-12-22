require 'spec_helper'

require 'bra/model'

describe Bra::Model::ModelObject do
  subject { Bra::Model::ModelObject.new(target) }
  let(:target) { nil }
  let(:old_parent) { double(:old_parent) }
  let(:new_parent) { double(:new_parent) }
  let(:child) { double(:child) }
  let(:privilege_set) { double(:privilege_set) }
  let(:operation) { double(:operation) }

  before(:each) do
    allow(old_parent).to receive(:add_child)
    allow(old_parent).to receive(:remove_child)
    allow(old_parent).to receive(:id_function) { proc { :test_id } }
    allow(old_parent).to receive(:can_have_children?).and_return(:true)

    allow(new_parent).to receive(:add_child)
    allow(new_parent).to receive(:remove_child)
    allow(new_parent).to receive(:id_function) { proc { :test_id } }
    allow(new_parent).to receive(:can_have_children?).and_return(:true)
  end

  # ModelObjects should implement the composite interface as far as reading
  # goes; if anything attempts to add or remove a child on a plain
  # ModelObject, it should fail.

  describe '#add_child' do
    specify { expect { subject.add_child(child) }.to raise_error }
  end

  describe '#remove_child' do
    specify { expect { subject.remove_child(child) }.to raise_error }
  end

  describe '#children' do
    specify { expect(subject.children).to be_nil }
  end

  describe '#child_hash' do
    specify { expect(subject.child_hash).to eq({}) }
  end

  describe '#can_have_children?' do
    specify { expect(subject.can_have_children?).to be_false }
  end

  describe '#move_to' do
    context 'when the receiving parent is nil' do
      context 'when the object has no parent' do
        it 'keeps the parent as nil' do
          expect(subject.parent).to be_nil
          subject.move_to(nil, :test)
          expect(subject.parent).to be_nil
        end
        it 'sets the id to nil' do
          subject.move_to(nil, :test)
          expect(subject.id).to be_nil
        end
      end

      context 'when the object has a parent' do
        before(:each) { subject.move_to(old_parent, :test) }

        it 'calls #remove_child on the previous parent' do
          expect(old_parent).to receive(:remove_child).once.with(:test_id)

          subject.move_to(nil, :test)
        end

        it 'sets the parent to nil' do
          expect(subject.parent).to eq(old_parent)
          subject.move_to(nil, :test)
          expect(subject.parent).to be_nil
        end

        it 'sets the id to nil' do
          subject.move_to(nil, :test)
          expect(subject.id).to be_nil
        end
      end
    end
    context 'when the receiving parent cannot have children' do
      before(:each) do
        allow(new_parent).to receive(:can_have_children?).and_return(false)
      end

      context 'and the object has no parent' do
        specify do
          expect { subject.move_to(new_parent, :test_id) }.to raise_error
        end
      end
      context 'and the object has a parent' do
        before(:each) { subject.move_to(old_parent, :old) }

        specify do
          expect { subject.move_to(new_parent, :test_id) }.to raise_error
        end

        it 'does not change the parent' do
          expect { subject.move_to(new_parent, :test_id) }.to raise_error
          expect(subject.parent).to be(old_parent)
        end
      end
    end
    context 'when the receiving parent can have children' do
      context 'and the object has no parent' do
        it 'calls #can_have_children? on the receiving parent' do
          expect(new_parent).to receive(:can_have_children?).once

          subject.move_to(new_parent, :test_id)
        end
        it 'calls #add_child on the receiving parent' do
          expect(new_parent).to receive(:add_child).with(:test_id, subject)

          subject.move_to(new_parent, :test_id)
        end
        it 'calls #id_function on the receiving parent' do
          expect(new_parent).to receive(:id_function).with(subject)

          subject.move_to(new_parent, :test_id)
        end
        it 'sets the parent of the object to the receiving parent' do
          subject.move_to(new_parent, :test_id)
          expect(subject.parent).to be(new_parent)
        end
      end
      context 'and the object already has a parent' do
        before(:each) do
          expect(old_parent).to receive(:id_function).once.and_return(
            proc { :test_id }
          )
          subject.move_to(old_parent, :test_id)
        end

        it 'calls #can_have_children? on the receiving parent' do
          expect(new_parent).to receive(:can_have_children?).once

          subject.move_to(new_parent, :test_id)
        end
        it 'calls #add_child on the receiving parent' do
          expect(new_parent).to receive(:add_child).with(
            :test_id, subject
          ).once

          subject.move_to(new_parent, :test_id)
        end
        it 'calls #id_function on the receiving parent' do
          expect(new_parent).to receive(:id_function).with(subject).once

          subject.move_to(new_parent, :test_id)
        end
        it 'calls #remove_child on the previous parent' do
          expect(old_parent).to receive(:remove_child).with(:test_id).once

          subject.move_to(new_parent, :test_id)
        end
        it 'sets the parent of the object to the receiving parent' do
          expect(subject.parent).to be(old_parent)
          subject.move_to(new_parent, :test_id)
          expect(subject.parent).to be(new_parent)
        end
      end
    end
  end

  describe '#id' do
    context 'when the object has not been moved to a parent' do
      specify { expect(subject.id).to be_nil }
    end
    context 'when the object has been moved to a parent' do
      it 'returns the result of calling the ID function given by the parent' do
        procedure = double(:proc)
        expect(procedure).to receive(:call).once.and_return(:test_id)
        allow(new_parent).to receive(:id_function).and_return(procedure)

        subject.move_to(new_parent, :test123)
        expect(subject.id).to eq(:test_id)
      end
    end
  end

  describe '#notify_channel' do
    context 'when there is no update channel' do
      specify { expect { subject.notify_channel(:repr) }.to raise_error }
    end
    context 'when there is an update channel' do
      it 'calls channel#push with a tuple of itself and the given item' do
        channel = double('channel')
        subject.register_update_channel(channel)
        expect(channel).to receive(:push).with([subject, :repr])

        subject.notify_channel(:repr)
      end
    end
  end

  describe '#fail_if_cannot' do
    context 'when given a valid privilege set and operation' do
      it 'calls #require on the privileges set with the handler target' do
        ( expect(privilege_set)
          .to receive(:require).once
          .with(operation, subject.handler_target)
        )

        subject.fail_if_cannot(operation, privilege_set)
      end
    end
  end

  describe '#can?' do
    context 'when given a valid privilege set and operation' do
      it 'calls #has? on the privileges set with the handler target' do
        ( expect(privilege_set)
          .to receive(:has?).once
          .with(operation, subject.handler_target)
        )

        subject.can?(operation, privilege_set)
      end
    end
  end

  describe '#driver_put' do
    specify do
      expect { subject.driver_put(:foo) }.to raise_error(
        Bra::Common::Exceptions::NotSupportedByBra
      )
    end
  end
  describe '#driver_post' do
    specify do
      expect { subject.driver_post(:foo, :bar) }.to raise_error(
        Bra::Common::Exceptions::NotSupportedByBra
      )
    end
  end
  describe '#driver_delete' do
    specify do
      expect { subject.driver_delete }.to raise_error(
        Bra::Common::Exceptions::NotSupportedByBra
      )
    end
  end

  describe '#handler_target' do
    context 'when the subject is not a subclass' do
      context 'and and handler_target is nil' do
        it 'returns the relative, underscored class name as a symbol' do
          expect(subject.handler_target).to eq(:model_object)
        end
      end
      context 'and the handler_target is defined' do
        let(:target) { :arsenic_catnip }
        it 'returns that handler_target' do
          expect(subject.handler_target).to eq(:arsenic_catnip)
        end
      end
    end
  end
end
