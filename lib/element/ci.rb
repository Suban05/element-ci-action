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
      space_id = @console.default_space_id

      user_list_id = create_user_list(space_id)

      app = create_application(user_list_id, space_id)

      code = 0
      created = @console.application(app['id'])
      begin
        code = 1 if run_commands(created['uri']) == 1
      rescue StandardError => e
        @log.error("Something is wrong: #{e.message}")
        code = 1
      end

      delete_application(app)

      delete_user_list(user_list_id)
      raise 'Errors occurred during the check' unless code.zero?

      code
    end

    private

    def run_commands(url)
      Element::ActionRunner.new(@actions, url, @log).run
    end

    def create_user_list(space_id)
      user_list_id = @console.create_user_list('test user list', space_id)['id']
      @log.info("User list #{user_list_id} created")
      user_list_id
    end

    def create_application(user_list_id, space_id)
      project = project_id_from_console

      assembly_info = @console.project_assembly_info(project, @branch)
      version_info = @console.project_version_info(project, assembly_info['assembly-version'])

      app = @console.create_application(
        {
          'display-name' => 'test-app-dev',
          'technology-version' => @element_version,
          'default-user-list' => user_list_id,
          'user-lists' => [user_list_id],
          'space-id' => space_id,
          'publication-context' => 'test-app-dev',
          'development-mode' => true,
          'autostarting-scheduled-jobs' => true,
          'autostarting-esb' => false,
          'description' => 'test application',
          'source' => {
            'project-version-id' => version_info['id'],
            'project-name' => assembly_info['project-name'],
            'type' => 'repository',
            'image-id' => project,
            'project-version' => assembly_info['assembly-version']
          }
        }
      )

      await_for_app_creation(app)

      if @console.app_state(app['id'])['status'] == 'Error'
        @log.error('An error occurred while the app was being created')
      else
        @log.info("App \"#{app['display-name']}\" successfully created")
      end

      app
    end

    def await_for_app_creation(app)
      @log.info("App \"#{app['display-name']}\" is creating...")
      while @console.app_state(app['id'])['status'] == 'Initializing'
        # wait...
      end
    end

    def project_id_from_console
      project_id = @project_id
      project = @console.project_info(@project_id)
      if project['project-kind'] == 'Group'
        projects = @console.all_projects
        project_id = projects.find do |p|
          p['group-id'] == project['id'] && p['project-kind'] == 'Application'
        end['id']
      end
      project_id
    end

    def delete_user_list(id)
      @console.delete_user_list(id)

      @log.info("User list \"#{id}\" successfully deleted")
    end

    def delete_application(app)
      @console.delete_application(app['id'])

      @log.info("App \"#{app['display-name']}\" is deleting...")

      while @console.app_state(app['id'])['status'] == 'Deleting'
        # wait...
      end

      @log.info("App \"#{app['display-name']}\" successfully deleted")
    end
  end
end
