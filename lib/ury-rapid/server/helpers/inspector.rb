require 'haml'

module Rapid
  module Server
    module Helpers
      # Sinatra helpers for the API Inspector
      module Inspector
        def child(inspector, id)
          insp = inspector.inspect_child(id)
          inspector_haml(insp)
        end

        def navigation(inspector)
          haml(
            :in_out_links,
            locals: {
              resource_url: inspector.resource_url,
              inner: inspector.inner
            }
          )
        end

        # Renders an API Inspector instance using HAML.
        def inspector_haml(inspector)
          render = ->(type) { haml(type, locals: { inspector: inspector }) }
          begin
            render.call(inspector.resource_type)
          rescue Errno::ENOENT
            # There was no template for the resource type, so try something
            # more general.
            render.call(inspector.resource_general_type)
          end
        end
      end
    end
  end
end

