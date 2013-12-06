module Bra
  module Baps
    module Responses
      module Handlers
        # Handler for dealing with BAPS system notifications that bra logs
        # but otherwise ignores.
        class Log < Bra::DriverCommon::Responses::Handler
          TARGETS = [
            Codes::System::CLIENT_ADD,
            Codes::System::CLIENT_REMOVE,
            Codes::System::LOG_MESSAGE
          ]

          MESSAGES = {
            Codes::System::CLIENT_ADD => 'New client',
            Codes::System::CLIENT_REMOVE => 'Client disconnected',
            Codes::System::LOG_MESSAGE => 'BAPS says'
          }

          def run(response)
            puts("#{MESSAGES[response]}: #{client}")
          end
        end

        # Handler for BAPS responses carrying login seeds.
        class Seed < Bra::DriverCommon::Responses::Handler
          TARGETS = [
            Codes::System::SEED
          ]

          def run(response)
            username = find('x_baps/server/username', &:value)
            password = find('x_baps/server/password', &:value)
            seed = response[:seed]
            # Kurse all SeeDs.  Swarming like lokusts akross generations.
            #   - Sorceress Ultimecia, Final Fantasy VIII
            @parent.login_authenticate(username, password, seed) if seed
          end
        end

        # Handler for BAPS responses carrying login responses.
        class LoginResult < Bra::DriverCommon::Responses::Handler
          TARGETS = [
            Codes::System::LOGIN_RESULT
          ]

          # TODO(mattbw): Move these somewhere more relevant?
          module LoginErrors
            OK = 0
            INCORRECT_USER = 1
            EMPTY_USER = 2
            INCORRECT_PASSWORD = 3
          end

          def run(response)
            code, string = response.values_at(*%i(subcode details))
            is_ok(code) ? continue : die
          end

          def is_ok(code)
            code == LoginErrors::OK
          end

          def continue
            @parent.login_synchronise
          end

          def die
            puts("BAPS login FAILED: #{string}, code #{code}.")
            EventMachine.stop
          end
        end
      end
    end
  end
end
