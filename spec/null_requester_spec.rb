require 'spec_helper'

require 'ury_rapid/service_common/requests/null_requester'

describe Rapid::ServiceCommon::Requests::NullRequester do
  describe '#add_handlers' do
    it 'does not change the model structure' do
      structure = double(:structure)
      expect { build(:null_requester).add_handlers(structure) }
                                     .not_to change { structure }
    end
  end
end
