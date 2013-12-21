require 'spec_helper'

require 'forwardable'
require 'bra/baps/requests/request'
require 'bra/baps/format_strings'

# Simple queue for testing requests.
class MockQueue
  extend Forwardable

  def initialize
    @contents = []
  end

  def_delegator :@contents, :push
  def_delegator :@contents, :shift, :pop
end

describe Bra::Baps::Requests::Request do
  let(:request) { Bra::Baps::Requests::Request.new(100, 3) }
  let(:request_two) { Bra::Baps::Requests::Request.new(100, 3) }
  let(:queue) { MockQueue.new }
  let(:header) { MockQueue.new }

  describe '#uint16' do
    context 'with a 16-bit integer' do
      it 'adds the integer in BAPS format to its payload' do
        request.uint16(65535).to(queue)
        expect(queue.pop).to eq(
          [103, 2, 65535].pack(
            Bra::Baps::FormatStrings::UINT16 +
            Bra::Baps::FormatStrings::UINT32 +
            Bra::Baps::FormatStrings::UINT16
          )
        )
      end
    end
    context 'with multiple 16-bit integers' do
      it 'behaves as if each had been added separately' do
        request.uint16(1).uint16(100).uint16(65536).to(queue)
        request_two.uint16(1, 100, 65536).to(queue)
        a = queue.pop
        b = queue.pop
        expect(a).to eq(b)
      end
    end
  end

  describe '#uint32' do
    context 'with a 32-bit integer' do
      it 'adds the integer in BAPS format to its payload' do
        request.uint32(65535).to(queue)
        expect(queue.pop).to eq(
          [103, 4, 65535].pack(
            Bra::Baps::FormatStrings::UINT16 +
            Bra::Baps::FormatStrings::UINT32 +
            Bra::Baps::FormatStrings::UINT32
          )
        )
      end
    end
    context 'with multiple 32-bit integers' do
      it 'behaves as if each had been added separately' do
        request.uint32(1).uint32(100).uint32(65536).to(queue)
        request_two.uint32(1, 100, 65536).to(queue)
        a = queue.pop
        b = queue.pop
        expect(a).to eq(b)
      end
    end
  end

  describe '#string' do
    context 'with a string' do
      it 'adds the string in BAPS format to its payload' do
        str = 'FUS'
        size = str.bytesize
        request.string(str).to(queue)

        expect(queue.pop).to eq(
          [103, 4 + size, size, str].pack(
            Bra::Baps::FormatStrings::UINT16 +
            Bra::Baps::FormatStrings::UINT32 +
            Bra::Baps::FormatStrings::UINT32 +
            Bra::Baps::FormatStrings::STRING_BODY + size.to_s
          )
        )
      end
    end
    context 'with multiple strings' do
      it 'behaves as if each had been added separately' do
        request.string('tom').string('and').string('jerry').to(queue)
        request_two.string('tom', 'and', 'jerry').to(queue)
        a = queue.pop
        b = queue.pop
        expect(a).to eq(b)
      end
    end
  end
end
