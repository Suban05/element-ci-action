# frozen_string_literal: true

module Element
  class ActionRunner
    def initialize(actions, url, log)
      @actions = actions
      @url = url
      @log = log
    end

    def run
      return 0 if @actions.nil?

      @actions.each do |req|
        @log.info(req['title'])
        uri = uri(req)

        request = new_request(req, uri)
        response = call_request(uri, request)
        return 1 unless ok?(response)

        @log.info(response.body)
        result = JSON.parse(response.body)
        if result['code'] != 0
          @log.error("Action #{req['name']} is failed")
          return 1
        end
      end
      0
    end

    private

    def ok?(response)
      response.code.to_i == 200
    end

    def uri(action)
      URI("#{@url}/api/#{action['path']}")
    end

    def new_request(req, uri)
      case req['method'].downcase
      when 'post'
        Net::HTTP::Post.new(uri)
      when 'get'
        Net::HTTP::Get.new(uri)
      else
        raise "Unsupported method: #{req['method']}"
      end
    end

    def call_request(uri, request)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end
    end
  end
end
