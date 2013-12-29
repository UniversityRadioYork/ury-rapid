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

  describe '#notify_update' do
    context 'when there is no update channel' do
      specify { expect { subject.notify_channel(:repr) }.to raise_error }
    end
    context 'when there is an update channel' do
      it 'calls channel#notify_update with itself' do
        channel = double('channel')
        subject.register_update_channel(channel)
        expect(channel).to receive(:notify_update).with(subject)

        subject.notify_update
      end
    end
  end

  describe '#notify_delete' do
    context 'when there is no update channel' do
      specify { expect { subject.notify_channel(:repr) }.to raise_error }
    end
    context 'when there is an update channel' do
      it 'calls channel#notify_delete with itself' do
        channel = double('channel')
        subject.register_update_channel(channel)
        expect(channel).to receive(:notify_delete).with(subject)

        subject.notify_delete
      end
    end
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
        allow(handler).to receive(action)
      end

      it 'calls #require on the privilege set' do
        expect(privilege_set).to receive(:require).once.with(
          action, :mock_model_object
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
