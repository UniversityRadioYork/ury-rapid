require 'spec_helper'

require 'bra/common/payload'
require 'bra/model'

describe Bra::Model::ModelObject do
  subject { Bra::Model::ModelObject.new(target) }
  let(:target) { nil }
  let(:old_parent) { double(:old_parent) }
  let(:new_parent) { double(:new_parent) }
  let(:child) { double(:child) }
  let(:privilege_set) { double(:privilege_set) }
  let(:operation) { double(:operation) }
  let(:handler) { double(:handler) }

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

  #
  # Composite interface
  #

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

  #
  # URLs and IDs
  #

  describe '#url' do
    context 'when the object has not been moved to a parent' do
      specify { expect(subject.url).to eq '' }
    end
    context 'when the object has been moved to a parent' do
      before(:each) do
        subject.move_to(new_parent, nil)
        allow(new_parent).to receive(:url)
      end

      it 'calls #id' do
        allow(subject).to receive(:id)
        expect(subject).to receive(:id).once

        subject.url
      end
      it 'calls #url recursively on its parent' do
        expect(new_parent).to receive(:url).once

        subject.url
      end
      it 'is equal to the joining of the parent URL and ID with a slash' do
        allow(subject).to receive(:id).and_return(:woof)
        allow(new_parent).to receive(:url).and_return('dog/goes')

        expect(subject.url).to eq('dog/goes/woof')
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


  #
  # Moving children
  #

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

  #
  # Updates channel
  #

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

  #
  # Privileges methods
  #

  {fail_if_cannot: :require, can?: :has?}.each do |subject_meth, set_meth|
    describe "##{subject_meth}" do
      context 'when given a valid privilege set and operation' do
        it 'calls ##{set_meth} on the privilege set with the handler target' do
          expect(privilege_set).to receive(set_meth).once.with(
            operation, subject.handler_target
          )
          subject.send(subject_meth, operation, privilege_set)
        end
      end
    end
  end

  #
  # Server actions
  #

  describe '#get' do
    before(:each) { allow(subject).to receive(:flat) }

    it 'calls #require on the privilege set' do
      expect(privilege_set).to receive(:require).once.with(:get, :model_object)
      subject.get(privilege_set)
    end

    context 'the PrivilegeSet does not raise an error in #require' do
      it 'returns the flat representation' do
        flat = double

        allow(privilege_set).to receive(:require)
        expect(subject).to receive(:flat).once.with(no_args).and_return(flat)
        expect(subject.get(privilege_set)).to be(flat)
      end
    end
  end

  %i{put post delete}.each do |action|
    describe "##{action}" do
      let(:payload) { Bra::Common::Payload.new(:body, privilege_set) }
      before(:each) do
        subject.register_handler(handler)
        allow(handler).to receive(action)
      end

      it 'calls #require on the privilege set' do
        expect(privilege_set).to receive(:require).once.with(
          action, :model_object
        )
        subject.send(action, payload)
      end

      context 'the PrivilegeSet does not raise an error in #require' do
        it "calls ##{action} on the handler with the object and payload" do
          allow(privilege_set).to receive(:require)

          expect(handler).to receive(action).once.with(subject, payload)
          subject.send(action, payload)
        end
      end
    end
  end

  #
  # Driver actions (these, by default, do nothing)
  #

  { put: [:foo], post: [:foo, :bar], delete: [] }.each do |action, args|
    describe "#driver_#{action}" do
      specify do
        method = "driver_#{action}".intern
        expect { subject.send(method, *args) }.to raise_error(
          Bra::Common::Exceptions::NotSupportedByBra
        )
      end
    end
  end

  #
  # Handler target
  #

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
