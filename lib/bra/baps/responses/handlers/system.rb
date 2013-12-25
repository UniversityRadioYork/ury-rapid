module Bra
  module Baps
    module Responses
      module Handlers
        # Handler for dealing with BAPS system notifications that bra logs
        # but otherwise ignores.
        class Log < Bra::DriverCommon::Responses::Handler
          TARGETS = [
            Codes::System::CLIENT_CHANGE,
            Codes::System::LOG_MESSAGE
          ]

          def run(response)
            puts("#{type_message(response)}: #{details(response)}")
          end

          def type_message(response)
            TYPE_MESSAGE[response.code + response.subcode]
          end

          def details(response)
            symbol = DETAILS_SYM[response.code]
            response[symbol]
          end

          private

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
        class Seed < Bra::DriverCommon::Responses::Handler
          TARGETS = [Codes::System::SEED]

          def run(response)
            username = get('x_baps/server/username').value
            password = get('x_baps/server/password').value
            seed = response.seed
            # Kurse all SeeDs.  Swarming like lokusts akross generations.
            #   - Sorceress Ultimecia, Final Fantasy VIII
            @parent.login_authenticate(username, password, seed) if seed
          end
        end

        # Handler for BAPS responses carrying login responses.
        class LoginResult < Bra::DriverCommon::Responses::Handler
          TARGETS = [Codes::System::LOGIN_RESULT]

          # TODO(mattbw): Move these somewhere more relevant?
          module LoginErrors
            OK = 0
            INCORRECT_USER = 1
            EMPTY_USER = 2
            INCORRECT_PASSWORD = 3
          end

          def run(response)
            code = response.subcode
            is_ok(code) ? continue : die(code, response.details)
          end

          def is_ok(code)
            code == LoginErrors::OK
          end

          def continue
            @parent.login_synchronise
          end

          def die(code, string)
            puts("BAPS login FAILED: #{string}, code #{code}.")
            EventMachine.stop
          end
        end
      end
    end
  end
end
