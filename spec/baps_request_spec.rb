require 'spec_helper'

require 'forwardable'
require 'ury_rapid/baps/requests/request'
require 'ury_rapid/baps/format_strings'

# Simple queue for testing requests.
class MockQueue
  extend Forwardable

  def initialize
    @contents = []
  end

  def_delegator :@contents, :push
  def_delegator :@contents, :shift, :pop
end

describe Rapid::Baps::Requests::Request do
  let(:request) { Rapid::Baps::Requests::Request.new(100, 3) }
  let(:request_two) { Rapid::Baps::Requests::Request.new(100, 3) }
  let(:queue) { MockQueue.new }
  let(:header) { MockQueue.new }

  describe '#uint16' do
    context 'with a 16-bit integer' do
      it 'adds the integer in BAPS format to its payload' do
        request.uint16(65_535).to(queue)
        expect(queue.pop).to eq(
          [103, 2, 65_535].pack(
            Rapid::Baps::FormatStrings::UINT16 +
            Rapid::Baps::FormatStrings::UINT32 +
            Rapid::Baps::FormatStrings::UINT16
          )
        )
      end
    end
    context 'with multiple 16-bit integers' do
      it 'behaves as if each had been added separately' do
        request.uint16(1).uint16(100).uint16(65_536).to(queue)
        request_two.uint16(1, 100, 65_536).to(queue)
        a = queue.pop
        b = queue.pop
        expect(a).to eq(b)
      end
    end
  end

  describe '#uint32' do
    context 'with a 32-bit integer' do
      it 'adds the integer in BAPS format to its payload' do
        request.uint32(65_535).to(queue)
        expect(queue.pop).to eq(
          [103, 4, 65_535].pack(
            Rapid::Baps::FormatStrings::UINT16 +
            Rapid::Baps::FormatStrings::UINT32 +
            Rapid::Baps::FormatStrings::UINT32
          )
        )
      end
    end
    context 'with multiple 32-bit integers' do
      it 'behaves as if each had been added separately' do
        request.uint32(1).uint32(100).uint32(65_536).to(queue)
        request_two.uint32(1, 100, 65_536).to(queue)
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
            Rapid::Baps::FormatStrings::UINT16 +
            Rapid::Baps::FormatStrings::UINT32 +
            Rapid::Baps::FormatStrings::UINT32 +
            Rapid::Baps::FormatStrings::STRING_BODY + size.to_s
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
