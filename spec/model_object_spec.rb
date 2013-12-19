require_relative '../models/model_object'

describe Bra::Models::ModelObject do
  let(:object) { Bra::Models::ModelObject.new }

  describe '#notify_channel' do
    context 'there is no update channel' do
      it 'fails' do
        expect { object.notify_channel(:repr) }.to raise_error
      end
    end
    context 'there is an update channel' do
      it 'calls channel#push with a tuple of itself and the given item' do
        channel = double('channel')
        object.register_update_channel(channel)
        channel.should_receive(:push).with([object, :repr])

        object.notify_channel(:repr)
      end
    end
  end
end
