# frozen_string_literal: true

require 'net/http'
require 'logger'
require 'uri'
require_relative 'console'
require_relative 'action_runner'

module Element
  class CI
    def initialize(config)
      console = if config['testing']
                  Element::Console::Fake
                else
                  Element::Console
                end
      @console = console.new(config['login'], config['password'], config['server'] || '1cmycloud.com')
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
        project_id = projects.find do |p|
          p['group-id'] == project['id'] && p['project-kind'] == 'Application'
        end['id']
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

      code = 0
      created = @console.application(app['id'])
      begin
        code = 1 if run_commands(created['uri']) == 1
      rescue StandardError => e
        @log.error("Something is wrong: #{e.message}")
        code = 1
      end
      @console.delete_application(app['id'])
      @log.info("App \"#{app['display-name']}\" is deleting...")
      while @console.app_state(app['id'])['status'] == 'Deleting'
        # wait...
      end
      @log.info("App \"#{app['display-name']}\" successfully deleted")

      @console.delete_user_list(user_list_id)

      @log.info("User list \"#{user_list_id}\" successfully deleted")
      code
    end

    private

    def run_commands(url)
      Element::ActionRunner.new(@actions, url, @log).run
    end
  end
end
