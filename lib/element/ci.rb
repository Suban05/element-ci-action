# frozen_string_literal: true

require 'net/http'
require 'logger'
require 'uri'
require_relative 'console'

module Element
  class CI
    def initialize(config)
      @console = Element::Console.new(config['login'], config['password'], config['server'] || "1cmycloud.com")
      @log = Logger.new($stdout)
      @project_id = config['project_id']
      @element_version = config['element-version']
      @branch = config['branch']
      @actions = config['actions']
    end

    def run
      project_id = @project_id
      project = @console.project_info(@project_id)
      if project['project-kind'] == 'Group'
        projects = @console.all_projects
        project_id = projects.select do |p|
          p['group-id'] == project['id'] && p['project-kind'] == 'Application'
        end.first['id']
      end

      assembly_info = @console.project_assembly_info(project_id, @branch)
      version_info = @console.project_version_info(project_id, assembly_info['assembly-version'])

      space_id = @console.default_space_id

      user_list = @console.create_user_list('test user list', space_id)
      user_list_id = user_list['id']
      @log.info("User list #{user_list_id} created")

      app = @console.create_application(
        {
          'display-name' => 'test-app',
          'technology-version' => @element_version,
          'default-user-list' => user_list_id,
          'user-lists' => [user_list_id],
          'space-id' => space_id,
          'publication-context' => 'test-app',
          'development-mode' => true,
          'autostarting-scheduled-jobs' => true,
          'autostarting-esb' => false,
          'description' => 'test application',
          'source' => {
            'project-version-id' => version_info['id'],
            'project-name' => assembly_info['project-name'],
            'type' => 'repository',
            'image-id' => project_id,
            'project-version' => assembly_info['assembly-version']
          }
        }
      )

      @log.info("App \"#{app['display-name']}\" is creating...")
      while @console.app_state(app['id'])['status'] == 'Initializing'
        # wait...
      end

      if @console.app_state(app['id'])['status'] == 'Error'
        @log.error('An error occurred while the app was being created')
      else
        @log.info("App \"#{app['display-name']}\" successfully created")
      end

      created = @console.application(app['id'])
      begin
        run_commands(created['uri'])
      rescue StandardError => e
        @log.error("Something is wrong: #{e.message}")
      end
      @console.delete_application(app['id'])
      @log.info("App \"#{app['display-name']}\" is deleting...")
      while @console.app_state(app['id'])['status'] == 'Deleting'
        # wait...
      end
      @log.info("App \"#{app['display-name']}\" successfully deleted")

      @console.delete_user_list(user_list_id)

      @log.info("User list \"#{user_list_id}\" successfully deleted")
    end

    private

    def run_commands(url)
      return if @actions.nil?

      @actions.each do |req|
        @log.info(req['title'])
        uri = URI("#{url}/api/#{req['path']}")

        request = case req['method'].downcase
                  when 'post'
                    Net::HTTP::Post.new(uri)
                  when 'get'
                    Net::HTTP::Post.new(uri)
                  else
                    raise "Unsupported method: #{req['method']}"
                  end
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end
        return 1 unless response.code.to_i == 200

        @log.info(response.body)
        result = JSON.parse(response.body)
        if result['code'] != 0
          @log.error("Action #{req['name']} is failed")
          return 1
        end
        return 0
      end
    end
  end
end
