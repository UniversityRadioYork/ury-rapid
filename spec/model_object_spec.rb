require 'spec_helper'

require 'ury_rapid/common/payload'
require 'ury_rapid/model'

describe Rapid::Model::ModelObject do
  subject { build(:model_object) }
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
      subject { build(:model_object, channel: nil) }
      specify do
        expect { subject.send(method) }.to raise_error(
          Rapid::Common::Exceptions::MissingUpdateChannel
        ) { |e| expect(e.model_object).to eq(subject) }
      end
    end

    context 'when there is an update channel' do
      let(:channel) { double(:channel) }
      subject { build(:model_object, channel: channel) }

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

  %i(put post delete).each do |action|
    describe "##{action}" do
      let(:payload) { Rapid::Common::Payload.new(:body, privilege_set) }
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
  # Service actions (TODO: specify)
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
        subject { build(:model_object, handler_target: :arsenic_catnip) }

        it 'returns that handler_target' do
          expect(subject.handler_target).to eq(:arsenic_catnip)
        end
      end
    end
  end
end
