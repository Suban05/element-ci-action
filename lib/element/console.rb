# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'base64'

module Element
  class Console
    def initialize(login, password)
      @login = login
      @password = password
    end

    def project_assembly_info(project_id, branch)
      uri = uri("api/v2/projects/#{project_id}/assemblies")
      assemblies = response(uri, get_request(uri))
      assemblies.select do |assembly|
        assembly['branch-name'] == branch
      end.first
    end

    def project_version_info(project_id, version)
      uri = uri("api/v2/projects/#{project_id}/versions")
      versions = response(uri, get_request(uri))
      version = versions.select { |v| v['version'] == version }.first
    end

    def project_info(project_id)
      uri = uri("api/v2/projects/#{project_id}")
      response(uri, get_request(uri))
    end

    def all_projects
      uri = uri('api/v2/projects')
      response(uri, get_request(uri))
    end

    def app_state(id)
      uri = uri("api/v2/applications/#{id}/status")
      response(uri, get_request(uri))
    end

    def create_application(body)
      uri = uri('api/v2/applications')

      response(uri, post_request(uri, body))
    end

    def application(id)
      uri = uri("api/v2/applications/#{id}")

      response(uri, get_request(uri))
    end

    def delete_application(id)
      uri = uri("api/v2/applications/#{id}")

      response(uri, delete_request(uri))
    end

    def delete_user_list(id)
      uri = uri("api/v2/user-lists/#{id}")

      call_request(uri, delete_request(uri))
    end

    def create_user_list(presentation, space_id)
      uri = uri('api/v2/user-lists')
      response(
        uri,
        post_request(
          uri,
          {
            'presentation' => presentation,
            'space-id' => space_id,
            'include-personal-data-in-messages' => true,
            'self-registration' => {
              'enabled' => true,
              'phone-required' => true,
              'email-required' => true
            }
          }
        )
      )
    end

    def default_space_id
      uri = uri('api/v2/spaces')
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/json'
      request['Authorization'] = "Bearer #{token}"
      response(uri, request).first['id']
    end

    private

    def token
      uri = uri('sys/token')
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(@login, @password)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request['Accept'] = 'application/json'
      request.body = 'grant_type=client_credentials'
      @token ||= response(uri, request)['id_token']
    end

    def uri(action)
      URI.parse("https://1cmycloud.com/console/#{action}")
    end

    def post_request(uri, body)
      request = Net::HTTP::Post.new(uri)
      request['Accept'] = 'application/json'
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{token}"
      request.body = body.to_json
      request
    end

    def delete_request(uri)
      request = Net::HTTP::Delete.new(uri)
      request['Accept'] = 'application/json'
      request['Authorization'] = "Bearer #{token}"
      request
    end

    def get_request(uri)
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/json'
      request['Authorization'] = "Bearer #{token}"
      request
    end

    def response(uri, request)
      JSON.parse(call_request(uri, request).body)
    end

    def call_request(uri, request)
      response = new_response(uri, request)
      if response.code.to_i == 401
        token
        response = new_response(uri, request)
      end
      response
    end

    def new_response(uri, request)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end
    end
  end
end
