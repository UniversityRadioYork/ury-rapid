require 'json'
require 'ury_rapid/server/helpers'

module Rapid
  module Server
    # Sinatra helper sets for the Rapid HTTP server
    #
    # Much of the nitty-gritty of the server is in these helpers.
    module Helpers
      # Sinatra helpers for performing requests on the Rapid model
      #
      # Depends on Rapid::Server::Helpers::Error, for #wrap.
      module Model
        def get
          wrap { environment.get(request_url, &method(:handle_get)) }
        end

        %i(put post delete).each do |act|
          define_method(act) do
            wrap do
              environment.send(act, request_url, privilege_set, raw_payload)
              ok
            end
          end
        end

        private

        def handle_get(target)
          get_repr = {
            status: :ok,
            value: target.get(privilege_set)
          }

          respond_with :json, get_repr do |f|
            f.html { html_inspect(request, target, privilege_set) }
          end
        end

        def html_inspect(request, target, privilege_set)
          inspector_haml(Rapid::Server::Inspector.new(request,
                                                      target,
                                                      privilege_set))
        end

        def request_url
          params[:splat].first
        end

        def raw_payload
          payload_string = request.body.string
          payload_string.empty? ? nil : parse_json_from(request.body.string)
        end

        # Parses the request body as JSON and throws a 400 status if it
        # is malformed.
        #
        # request - The request whose body is to be parsed.
        #
        # Yields the parsed request body.
        #
        # Returns the block's return value if the JSON is valid, and nothing
        #   otherwise (processing is halted).
        def parse_json_from(string)
          json = JSON.parse(string)
        rescue JSON::ParserError
          error(400, 'Badly formed JSON.')
        else
          json.deep_symbolize_keys!
        end
      end

      # Renders a 'request sent OK' message
      #
      # This should be used for PUT, POST and DELETE responses.  There is a
      # special handler for GET, and OPTIONS returns CORS headers.
      #
      # @return [String]  The OK message, rendered according to the client's
      #   Accept headers.
      def ok
        respond_with :ok, status: :ok
      end
    end
  end
end
