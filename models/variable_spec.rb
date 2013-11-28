require_relative 'variable'

class TestVariable < Bra::Models::Variable
end

describe Bra::Models::Variable do
  describe '#method_missing' do
    context 'with a valid value' do
      it 'delegates missing methods to that value' do
        var = Bra::Models::Variable.new('quux', nil, nil)
        expect(var.upcase).to eq('QUUX')
      end
    end
  end
  describe '#handler_target' do
    context 'with @handler_target being nil' do
      it 'returns the relative, underscored class name as a symbol' do
        var = Bra::Models::Variable.new(0, nil, nil)
        expect(var.handler_target).to eq(:variable)

        tvar = TestVariable.new(0, nil, nil)
        expect(tvar.handler_target).to eq(:test_variable)
      end
    end
    context 'with @handler_target being defined' do
      it 'returns @handler_target' do
        var = Bra::Models::Variable.new(0, nil, :arsenic_catnip)
        expect(var.handler_target).to eq(:arsenic_catnip)

        tvar = TestVariable.new(0, nil, :noel_edmonds)
        expect(tvar.handler_target).to eq(:noel_edmonds)
      end
    end
  end
end
