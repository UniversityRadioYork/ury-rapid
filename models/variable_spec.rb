require_relative 'variable'

class TestVariable < Bra::Models::Variable
end

describe Bra::Models::Variable do
  describe '#handler_target' do
    context 'with @handler_target being nil' do
      it 'returns the relative, underscored class name as a symbol' do
        var = Bra::Models::Variable.new(0, nil, nil, nil, nil)
        expect(var.handler_target).to eq(:variable)

        tvar = TestVariable.new(0, nil, nil, nil, nil) 
        expect(tvar.handler_target).to eq(:test_variable)
      end
    end
    context 'with @handler_target being defined' do
      it 'returns @handler_target' do
        var = Bra::Models::Variable.new(0, nil, nil, nil, :arsenicCatnip)
        expect(var.handler_target).to eq(:arsenicCatnip)

        tvar = TestVariable.new(0, nil, nil, nil, :noel_edmonds)
        expect(tvar.handler_target).to eq(:noel_edmonds)
      end
    end
  end
end 
