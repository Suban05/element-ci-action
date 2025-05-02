# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Element::Console do
  let(:console) { described_class.new('login', 'password', 'test-server.com') }
  let(:project) do
    {
      'id' => 'id',
      'name' => 'project-1',
      'group-id' => 'group-1',
      'project-kind' => 'Application'
    }
  end
  let(:fake_object) { { 'id' => 'id' } }

  describe '#default_space_id' do
    it 'returns the default space ID' do
      VCR.use_cassette('console') do
        expect(console.default_space_id).to eq('space-1')
      end
    end
  end

  describe '#project_assembly_info' do
    it 'returns assembly information' do
      VCR.use_cassette('console') do
        expect(console.project_assembly_info('project-1', 'main')).to include(
          {
            'assembly-version' => '1.0.0',
            'project-name' => 'project-1',
            'branch-name' => 'main'
          }
        )
      end
    end
  end

  describe '#project_version_info' do
    it 'returns project version information' do
      VCR.use_cassette('console') do
        expect(console.project_version_info('project-1', '1.0.0')).to include(
          {
            'id' => 'id',
            'image-type' => 'image-type',
            'version' => '1.0.0'
          }
        )
      end
    end
  end

  describe '#project_info' do
    it 'returns project information' do
      VCR.use_cassette('console') do
        expect(console.project_info('project-1')).to include(project)
      end
    end
  end

  describe '#all_projects' do
    it 'returns all projects' do
      VCR.use_cassette('console') do
        expect(console.all_projects).to include(project)
      end
    end
  end

  describe '#app_state' do
    it 'returns app_state' do
      VCR.use_cassette('console') do
        expect(console.app_state('id')).to include({ 'status' => 'Running' })
      end
    end
  end

  describe '#application' do
    it 'returns an application' do
      VCR.use_cassette('console') do
        expect(console.application('id')).to include(fake_object)
      end
    end
  end

  describe '#create_application' do
    it 'creates a new application' do
      VCR.use_cassette('console') do
        expect(console.create_application({})).to include(fake_object)
      end
    end
  end

  describe '#delete_application' do
    it 'deletes a application' do
      VCR.use_cassette('console') do
        expect(console.delete_application('id')).to include(fake_object)
      end
    end
  end

  describe '#create_user_list' do
    it 'creates a new user list' do
      VCR.use_cassette('console') do
        expect(console.create_user_list('list', 'space-id')).to include(fake_object)
      end
    end
  end

  describe '#delete_user_list' do
    it 'deletes an user list' do
      VCR.use_cassette('console') do
        expect(console.delete_user_list('id')).to be_empty
      end
    end
  end
end
