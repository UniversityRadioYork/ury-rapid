require 'minitest'

require 'ury_rapid/services/code_table'

# A dummy code table, for the CodeTableTest test
module DummyCodeTable
  extend Rapid::Services::CodeTable

  module Foo
    FOO = 0xF00
    BAR = 0xBAA
  end

  module Foobar
    OOPS = 0xDEADBEEF
  end
end

# Tests for the CodeTable module mixin
class CodeTableTest < Minitest::Test
  # Tests whether CodeTable#code_symbol works for a valid code
  def test_code_symbol_valid
    assert_equal('DummyCodeTable::Foobar::OOPS',
                 DummyCodeTable.code_symbol(DummyCodeTable::Foobar::OOPS))
  end
end
