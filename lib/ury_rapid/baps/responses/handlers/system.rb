module Rapid
  module Baps
    module Responses
      module Handlers
        # Handler for dealing with BAPS system notifications that Rapid logs
        # but otherwise ignores.
        class Log < Rapid::Services::Responses::Handler
          def_targets(
            Codes::System::CLIENT_CHANGE,
            Codes::System::LOG_MESSAGE
          )

          def run
            log(:info, "#{type_message}: #{details}")
          end

          def type_message
            TYPE_MESSAGE[@response.code + @response.subcode]
          end

          def details
            symbol = DETAILS_SYM[@response.code]
            @response[symbol]
          end

          DETAILS_SYM = {
            Codes::System::CLIENT_CHANGE => :client,
            Codes::System::LOG_MESSAGE => :message
          }

          TYPE_MESSAGE = {
            Codes::System::CLIENT_CHANGE => 'Client disconnected',
            Codes::System::CLIENT_CHANGE + 1 => 'Client connected',
            Codes::System::LOG_MESSAGE => 'BAPS says'
          }
        end

        # Handler for BAPS responses carrying login seeds.
        class Seed < Rapid::Services::Responses::Handler
          def_targets Codes::System::SEED

          def run
            username = find('x_baps/server/username').value
            password = find('x_baps/server/password').value
            seed = @response.seed
            # Kurse all SeeDs.  Swarming like lokusts akross generations.
            #   - Sorceress Ultimecia, Final Fantasy VIII
            @parent.login_authenticate(username, password, seed) if seed
          end
        end

        # Handler for BAPS responses carrying login responses.
        class LoginResult < Rapid::Services::Responses::Handler
          def_targets Codes::System::LOGIN_RESULT

          # TODO(mattbw): Move these somewhere more relevant?
          module LoginErrors
            OK = 0
            INCORRECT_USER = 1
            EMPTY_USER = 2
            INCORRECT_PASSWORD = 3
          end

          def run
            code = @response.subcode
            ok?(code) ? continue : die(code, @response.details)
          end

          def ok?(code)
            code == LoginErrors::OK
          end

          def continue
            @parent.login_synchronise
          end

          def die(code, string)
            log(:fatal, "BAPS login failed: #{string}, code #{code}.")
            EventMachine.stop
          end
        end
      end
    end
  end
end
