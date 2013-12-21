require 'bra/models/model_object'

describe Bra::Models::ModelObject do
  let(:parent1) { double(:parent1) }
  let(:parent2) { double(:parent2) }

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
        before(:each) do
          allow(parent1).to receive(:add_child)
          allow(parent1).to receive(:remove_child)
          allow(parent1).to receive(:id_function) { proc { :test_id } }

          subject.move_to(parent1, :test)
        end

        it 'calls #remove_child on the previous parent' do
          parent1.should_receive(:remove_child).once.with(:test_id)

          subject.move_to(nil, :test)
        end

        it 'sets the parent to nil' do
          expect(subject.parent).to eq(parent1)
          subject.move_to(nil, :test)
          expect(subject.parent).to be_nil
        end

        it 'sets the id to nil' do
          subject.move_to(nil, :test)
          expect(subject.id).to be_nil
        end
      end
    end

    context 'when the receiving parent is not nil' do
      context 'when the object has no parent' do
        before(:each) do
          allow(parent1).to receive(:add_child)
          allow(parent1).to receive(:id_function)
        end

        it 'calls #add_child on the receiving parent' do
          parent1.should_receive(:add_child).with(:test_id, subject)

          subject.move_to(parent1, :test_id)
        end
        it 'calls #id_function on the receiving parent' do
          parent1.should_receive(:id_function).with(subject)

          subject.move_to(parent1, :test_id)
        end
        it 'sets the parent of the object to the receiving parent' do
          subject.move_to(parent1, :test_id)
          expect(subject.parent).to be(parent1)
        end
      end
      context 'when the object already has a parent' do
        before(:each) do
          allow(parent1).to receive(:add_child)
          allow(parent1).to receive(:id_function)
          allow(parent1).to receive(:remove_child)
          allow(parent2).to receive(:add_child)
          allow(parent2).to receive(:id_function)

          parent1.should_receive(:id_function).once.and_return(
            proc { :test_id }
          )
          subject.move_to(parent1, :test_id)
        end

        it 'calls #add_child on the receiving parent' do
          parent2.should_receive(:add_child).with(:test_id, subject).once

          subject.move_to(parent2, :test_id)
        end
        it 'calls #id_function on the receiving parent' do
          parent2.should_receive(:id_function).with(subject).once

          subject.move_to(parent2, :test_id)
        end
        it 'calls #remove_child on the previous parent' do
          parent1.should_receive(:remove_child).with(:test_id).once

          subject.move_to(parent2, :test_id)
        end
        it 'sets the parent of the object to the receiving parent' do
          expect(subject.parent).to be(parent1)
          subject.move_to(parent2, :test_id)
          expect(subject.parent).to be(parent2)
        end
      end
    end
  end

  describe '#id' do
    context 'when the object has not been moved to a parent' do
      it 'returns nil' do
        expect(subject.id).to be_nil
      end
    end
    context 'when the object has been moved to a parent' do
      it 'returns the result of calling the ID function given by the parent' do
        procedure = double(:proc)

        allow(parent1).to receive(:add_child)
        allow(parent1).to receive(:id_function) { procedure }
        procedure.should_receive(:call).once.and_return(:test_id)

        subject.move_to(parent1, :test123)
        expect(subject.id).to eq(:test_id)
      end
    end
  end

  describe '#notify_channel' do
    context 'when there is no update channel' do
      it 'fails' do
        expect { subject.notify_channel(:repr) }.to raise_error
      end
    end
    context 'when there is an update channel' do
      it 'calls channel#push with a tuple of itself and the given item' do
        channel = double('channel')
        subject.register_update_channel(channel)
        channel.should_receive(:push).with([subject, :repr])

        subject.notify_channel(:repr)
      end
    end
  end
end
