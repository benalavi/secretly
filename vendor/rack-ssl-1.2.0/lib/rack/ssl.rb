require 'rack'
require 'rack/request'

module Rack
  class SSL
    YEAR = 31536000

    def self.default_hsts_options
      { :expires => YEAR, :subdomains => false }
    end

    def initialize(app, options = {})
      @app = app

      @hsts = options[:hsts]
      @hsts = {} if @hsts.nil? || @hsts == true
      @hsts = self.class.default_hsts_options.merge(@hsts) if @hsts

      @exclude   = options[:exclude]
      @subdomain = options[:subdomain]
    end

    def call(env)
      if @exclude && @exclude.call(env)
        @app.call(env)
      elsif scheme(env) == 'https'
        status, headers, body = @app.call(env)
        headers = hsts_headers.merge(headers)
        flag_cookies_as_secure!(headers)
        [status, headers, body]
      else
        redirect_to_https(env)
      end
    end

    private
      # Fixed in rack >= 1.3
      def scheme(env)
        if env['HTTPS'] == 'on'
          'https'
        elsif env['HTTP_X_FORWARDED_PROTO']
          env['HTTP_X_FORWARDED_PROTO'].split(',')[0]
        else
          env['rack.url_scheme']
        end
      end

      def redirect_to_https(env)
        req      = Request.new(env)
        location = "https://#{[@subdomain, req.host].compact.join('.')}#{req.fullpath}"

        [301, hsts_headers.merge({'Content-Type' => "text/html", 'Location' => location}), []]
      end

      # http://tools.ietf.org/html/draft-hodges-strict-transport-sec-02
      def hsts_headers
        if @hsts
          value = "max-age=#{@hsts[:expires]}"
          value += "; includeSubDomains" if @hsts[:subdomains]
          { 'Strict-Transport-Security' => value }
        else
          {}
        end
      end

      def flag_cookies_as_secure!(headers)
        if cookies = headers['Set-Cookie']
          headers['Set-Cookie'] = cookies.split("\n").map { |cookie|
            if cookie !~ / secure;/
              "#{cookie}; secure"
            else
              cookie
            end
          }.join("\n")
        end
      end
  end
end
