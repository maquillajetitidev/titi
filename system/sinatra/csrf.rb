require 'sinatra/base'
require 'rack/csrf'

module Sinatra
  module Csrf
    module Helpers
      # Insert an hidden tag with the anti-CSRF token into your forms.
      def csrf_tag
        Rack::Csrf.csrf_tag(env)
      end

      # Return the anti-CSRF token
      def csrf_token
        Rack::Csrf.csrf_token(env)
      end

      # Return the field name which will be looked for in the requests.
      def csrf_field
        Rack::Csrf.csrf_field
      end
    end

    def apply_csrf_protection(options = {})
      opts = {raise: true, field: 'csrf', key: 'csrf', header: 'X_CSRF_TOKEN', skip: ['POST:/admin/products/ajax_update']}.merge(options)
      use Rack::Csrf, opts
      helpers Csrf::Helpers
    end
  end
  register Csrf
end
