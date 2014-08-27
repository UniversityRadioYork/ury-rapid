require 'spec_helper'
require 'rapid/model/component_creator'
require 'rapid/model'

shared_examples 'a valid symbol constant' do |type, value|
  it "returns an object whose flat representation is :#{value}" do
    created = subject.send(type, value)
    expect(created.flat).to eq(value.to_sym)
  end
end

shared_examples 'a successful factory method' do |type, value|
  it 'sends the registrar #register with an object to register' do
    expect(registrar).to receive(:register).once do |arg|
      expect(arg).to be_a(Rapid::Model::ModelObject)
    end
    subject.send(type, value)
  end
end

shared_examples 'a symbol constant' do |type, valid_list|
  valid_list.each do |valid|
    it_behaves_like 'a successful factory method', type, valid

    context "when the argument is :#{valid}" do
      it_behaves_like 'a valid symbol constant', type, valid
    end
    context "when the argument is '#{valid}'" do
      it_behaves_like 'a valid symbol constant', type, valid.to_s
    end
  end

  context 'when the argument is invalid' do
    specify { expect { subject.send(type, :xyzzy) }.to raise_error }
  end

  context 'when the argument is nil' do
    specify { expect { subject.send(type, nil) }.to raise_error }
  end
end

shared_examples 'an item field' do |symbol, valid_value_hash, invalid_values|
  let(:defaults) { { type: :file, name: 'Test Name' } }

  context "when :#{symbol} is set to a valid value in the options" do
    it "returns an Item whose #{symbol} is the validated option value" do
      valid_value_hash.each do |input, output|
        hash = defaults.merge(symbol => input)
        item = subject.item(hash)
        expect(item.flat[symbol]).to eq(output)
      end
    end
  end

  context "when #{symbol} is set to an invalid value in the options" do
    it 'fails' do
      invalid_values.each do |input|
        hash = defaults.merge(symbol => input)
        expect { subject.item(hash) }.to raise_error
      end
    end
  end
end

describe Rapid::Model::ComponentCreator do
  subject { Rapid::Model::ComponentCreator.new(registrar) }
  let(:registrar) { double(:registrar) }
  before(:each) { allow(registrar).to receive(:register) }

  describe '#load_state' do
    it_behaves_like(
      'a symbol constant', :load_state, Rapid::Common::Types::LOAD_STATES
    )
  end

  describe '#play_state' do
    it_behaves_like(
      'a symbol constant', :play_state, Rapid::Common::Types::PLAY_STATES
    )
  end

  shared_examples 'a successful number volume call' do |examples|
    it 'returns an object whose #flat is equal to its input' do
      examples.each do |example|
        expect(subject.volume(example).flat).to eq(example)
      end
    end
  end

  shared_examples 'a successful string volume call' do |examples|
    it 'returns an object whose #flat is equal to Rational(input)' do
      examples.each do |example|
        expect(subject.volume(example).flat).to eq(Rational(example))
      end
    end
  end

  describe '#volume' do
    context 'when the value is a valid rational number between 0 and 1.0' do
      it_behaves_like(
        'a successful number volume call',
        [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
      )
    end

    context 'when the value is a valid integer between 0 and 1' do
      it_behaves_like('a successful number volume call', [0, 1])
    end

    context 'when the value is a string' do
      context 'and it represents a valid rational between 0 and 1.0' do
        it_behaves_like(
          'a successful string volume call',
          %w(0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0)
        )
      end

      context 'and it represents a valid integer between 0 and 1' do
        it_behaves_like 'a successful string volume call', %w(0 1)
      end
    end

    context 'when the value is a string that does not represent a number' do
      it 'fails' do
        expect { subject.volume('bananas') }.to raise_error
        expect { subject.volume('') }.to raise_error
        expect { subject.volume('3.0nanana') }.to raise_error
        expect { subject.volume('NaN') }.to raise_error
      end
    end

    context 'when the value is invalid' do
      it 'fails' do
        expect { subject.volume(true) }.to raise_error
        expect { subject.volume(false) }.to raise_error
        expect { subject.volume(nil) }.to raise_error
      end
    end
  end

  describe '#marker' do
    it 'returns an object whose #handler_target is the first argument' do
      expect(subject.marker(:foo, 1).handler_target).to eq(:foo)
    end

    context 'when the value is a valid natural' do
      it 'returns an object whose #flat is equal to its input' do
        [0, 1, 10, 100, 1000].each do |example|
          expect(subject.marker(:foo, example).flat).to eq(example)
        end
      end
    end

    context 'when the value is a string' do
      context 'and it represents a valid natural' do
        it 'returns an object whose #flat equals its input as an Integer' do
          %w(0 1 10 100 1000).each do |example|
            expect(subject.marker(:foo, example).flat).to eq(Integer(example))
          end
        end
      end
    end

    context 'when the value is a string representing a non-natural number' do
      it 'fails to construct' do
        expect { subject.marker(:foo, '1.1') }.to raise_error
      end
    end

    context 'when the value is a string that does not represent a number' do
      it 'fails to construct' do
        expect { subject.marker(:foo, 'bananas') }.to raise_error
        expect { subject.marker(:foo, '') }.to raise_error
        expect { subject.marker(:foo, '3dom') }.to raise_error
        expect { subject.marker(:foo, '3.0nanana') }.to raise_error
        expect { subject.marker(:foo, 'NaN') }.to raise_error
      end
    end

    context 'when the value is invalid' do
      it 'fails to construct' do
        expect { subject.volume(true) }.to raise_error
        expect { subject.volume(false) }.to raise_error
        expect { subject.volume(nil) }.to raise_error
      end
    end
  end

  describe '#item' do
    describe 'the duration of the Item' do
      it_behaves_like(
        'an item field',
        :duration,
        { 0 => 0, 500 => 500, nil => nil },
        [-1, 0.3, 'moo', true, false]
      )
    end

    describe 'the origin of the Item' do
      it_behaves_like(
        'an item field',
        :origin,
        { 0 => '0',
          'origin' => 'origin',
          :originy_originy_origin => 'originy_originy_origin',
          nil => nil,
          true => 'true',
          false => 'false'
        },
        []
      )
    end

    describe 'the type of the Item' do
      it_behaves_like(
        'an item field',
        :type,
        { 'file' => :file, :library => :library },
        ['s', 0, 0.3, nil, true, false]
      )
    end

    describe 'the name of the Item' do
      it_behaves_like(
        'an item field',
        :name,
        { 0 => '0',
          'name' => 'name',
          :namey_namey_name => 'namey_namey_name',
          nil => '',
          true => 'true',
          false => 'false'
        },
        []
      )
    end
  end
end
