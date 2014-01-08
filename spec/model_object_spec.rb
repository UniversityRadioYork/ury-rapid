require 'spec_helper'

require 'bra/common/payload'
require 'bra/model'

class MockModelObject
  include Bra::Model::ModelObject
end

describe MockModelObject do
  subject { MockModelObject.new(target) }
  let(:target) { nil }
  let(:old_parent) { double(:old_parent) }
  let(:new_parent) { double(:new_parent) }
  let(:child) { double(:child) }
  let(:privilege_set) { double(:privilege_set) }
  let(:handler) { double(:handler) }

  #
  # Updates channel
  #

  shared_examples 'a notification method' do |method|
    context 'when there is no update channel' do
      specify { expect { subject.send(method) }.to raise_error }
    end

    context 'when there is an update channel' do
      let(:channel) { double(:channel) }
      before(:each) do
        subject.register_update_channel(channel)
      end

      it "calls ##{method} on the channel with itself" do
        expect(channel).to receive(method).with(subject)
        subject.send(method)
      end
    end
  end

  describe '#notify_update' do
    it_behaves_like 'a notification method', :notify_update
  end

  describe '#notify_delete' do
    it_behaves_like 'a notification method', :notify_delete
  end

  #
  # Server actions
  #

  describe '#get' do
    before(:each) { allow(subject).to receive(:flat) }

    it 'calls #require on the privilege set' do
      expect(privilege_set).to receive(:require).once.with(
        :get, :mock_model_object
      )
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
        allow(handler).to receive(:call)
      end

      it 'calls #require on the privilege set' do
        expect(privilege_set).to receive(:require).once.with(
          action, :mock_model_object
        )
        subject.send(action, payload)
      end

      context 'the PrivilegeSet does not raise an error in #require' do
        it "calls the handler with :#{action}, the object and payload" do
          allow(privilege_set).to receive(:require)

          expect(handler).to receive(:call).once.with(action, subject, payload)
          subject.send(action, payload)
        end
      end
    end
  end

  #
  # Driver actions (TODO: specify)
  #

  #
  # Handler target
  #

  describe '#handler_target' do
    context 'when the subject is not a subclass' do
      context 'and and handler_target is nil' do
        it 'returns the relative, underscored class name as a symbol' do
          expect(subject.handler_target).to eq(:mock_model_object)
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
