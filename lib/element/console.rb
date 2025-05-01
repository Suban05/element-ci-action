# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'base64'

module Element
  class Console
    def initialize(login, password, server)
      @login = login
      @password = password
      @server = server
    end

    def project_assembly_info(project_id, branch)
      uri = uri("api/v2/projects/#{project_id}/assemblies")
      assemblies = response(uri, get_request(uri))
      assemblies.find do |assembly|
        assembly['branch-name'] == branch
      end
    end

    def project_version_info(project_id, version)
      uri = uri("api/v2/projects/#{project_id}/versions")
      versions = response(uri, get_request(uri))
      version = versions.find { |v| v['version'] == version }
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
      URI.parse("https://#{@server}/console/#{action}")
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

    class Fake
      def initialize(login, password, server)
        @login = login
        @password = password
        @server = server
        @state = 'Running'
      end

      def project_assembly_info(_project_id, branch)
        {
          'assembly-version' => '1.0.0',
          'branch-name' => branch
        }
      end

      def project_version_info(project_id, version)
        {
          'id' => 'version-id',
          'project-id' => project_id,
          'version' => version
        }
      end

      def project_info(project_id)
        {
          'id' => project_id,
          'name' => 'Test Project',
          'description' => 'Test Project Description',
          'project-kind' => { 'project-1' => 'Group', 'project-2' => 'Application' }[project_id]
        }
      end

      def all_projects
        [
          {
            'id' => 'project-1',
            'name' => 'Test Project 1',
            'description' => 'Test Project 1 Description',
            'group-id' => nil,
            'project-kind' => 'Group'
          },
          {
            'id' => 'project-2',
            'name' => 'Test Project 2',
            'description' => 'Test Project 2 Description',
            'group-id' => 'project-1',
            'project-kind' => 'Application'
          }
        ]
      end

      def app_state(_id)
        {
          'status' => @state
        }
      end

      def create_application(body)
        {
          'id' => {
            'project-1' => 'app-1',
            'project-2' => 'app-2'
          }[body['source']['image-id']],
          'uri' => "https://#{@server}/console/api/v2/applications/app-1",
          'display-name' => 'Test Application'
        }
      end

      def application(id)
        {
          'id' => id,
          'uri' => "https://#{@server}/applications/app",
          'display-name' => 'Test Application',
          'status' => { 'app-1' => 'Error', 'app-2' => 'Running' }[id]
        }
      end

      def delete_application(_id)
        @state = 'Deleted'
        {
          'status' => @state
        }
      end

      def delete_user_list(_id)
        ''
      end

      def create_user_list(presentation, space_id)
        {
          'id' => 'user-list-1',
          'presentation' => presentation,
          'space-id' => space_id
        }
      end

      def default_space_id
        'default-space-id'
      end
    end
  end
end
