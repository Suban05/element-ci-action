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
        uri = URI("#{@url}/api/#{req['path']}")

        request = new_request(req, uri)
        response = call_request(uri, request)
        return 1 unless response.code.to_i == 200

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
