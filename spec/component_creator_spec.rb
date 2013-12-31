require 'spec_helper'
require 'bra/model/component_creator'
require 'bra/model'

shared_examples 'a valid symbol constant' do |type, value|
  it "returns an object whose flat representation is :#{value}" do
    created = subject.send(type, value)
    expect(created.flat).to eq(value.to_sym)
  end
end

shared_examples 'a successful factory method' do |type, value|
  it 'sends the registrar #register with an object to register' do
    expect(registrar).to receive(:register).once do |arg|
      expect(arg).to be_a(Bra::Model::ModelObject)
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

describe Bra::Model::ComponentCreator do
  subject { Bra::Model::ComponentCreator.new(registrar) }
  let(:registrar) { double(:registrar) }
  before(:each) { allow(registrar).to receive(:register) }

  describe '#load_state' do
    it_behaves_like(
      'a symbol constant', :load_state, Bra::Common::Types::LOAD_STATES
    )
  end

  describe '#play_state' do
    it_behaves_like(
      'a symbol constant', :play_state, Bra::Common::Types::PLAY_STATES
    )
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

