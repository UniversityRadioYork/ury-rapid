require 'compo'
require 'bra/model/model_object'

module Bra
  module Model
    # An object that represents bra's error/debugging log
    # 
    # This is part of the model to allow easy access to the logger in areas
    # such as the server and driver, without needing to pass it in
    # explicitly.  It also allows the log to be treated like any other bit of
    # data bra holds.
    # 
    # In future, the log may be readable using the bra API.
    class Log < Compo::Leaf
      include ModelObject

    end
  end
end
