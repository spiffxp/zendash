require 'sinatra/base'
require 'haml'
require 'rest-client'
require 'json'
require 'digest/md5'

# --- Monkey patches -----------------------------

class Array
  def to_hash(&f)
    self.inject({}) { |a,i| a.merge!(f.call(i)) }
  end
end

class String
  def abbrev_to(n)
    self.length < n ? self : self[0..(n-4)] + "..."
  end
end

class ZenDash < Sinatra::Base
  zen_uri_real = 'https://www.agilezen.com/api/v1'
  zen_uri_fake = 'http://localhost:4567'
  zen_api_uri = zen_uri_real

  set :root, File.dirname(__FILE__)

  # --- Helpers ------------------------------------

  helpers do
    def get_parsed(uri, headers = { :x_zen_apikey => 'YOUR_ZEN_API_KEY', :accept => 'json'})
      JSON.parse(RestClient.get uri, headers)
    end

    # - Filters out stories that haven't made it to 'Archive'
    # - Adds the shortcut 'finished' property to stories
    # - Sorts stories by when they were finished
    # - Picks the five most recent stories
    def prep_stories(stories)
      stories = stories.select { |s| s['milestones'].last['phase']['name'] == 'Archive' }
      stories.each { |s| s['finished'] = s['milestones'].last['startTime'] }
      stories.sort! { |x,y| y['finished'] <=> x['finished'] }
      stories[0..4]
    end
    
    # - Reverses phase order to get HighCharts to put first phase on bottom
    # - Excludes the 'Archive' phase from durations
    def prep_phases(phases)
      phases.reverse!
      phases.select { |p| p['name'] != 'Archive' }
    end

    # - Computes individual story-in-phase durations in hours instead of seconds
    # - Abbreviates story text to 50 chars
    def compute_story_info(stories)
      stories.collect do |s|
        durations = s['milestones'].to_hash do |m|
          { m['phase']['name'] => m['duration'] / 3600.0 }
        end
        { :id => s['id'], :text => s['text'].abbrev_to(50), :finished => s['finished'], :durations => durations }
      end
    end

    def compute_chart_data(stories, phases)
      stories = prep_stories(stories)
      phases = prep_phases(phases)
      story_info = compute_story_info(stories)
      series = phases.collect do |p|
        { :name => p['name'], :data => story_info.collect { |si| si[:durations].fetch(p['name'],0) } }
      end
      story_info.each { |si| si.delete(:durations) }
      { :series => series , :storyInfo => story_info}
    end

    # AgileZen's API doesn't expose project member e-mails from project resource,
    # so we ha(cki)sh-uniq them out of the project roles' members
    def compute_users(roles)
      roles.to_hash { |r| r['members'].to_hash { |m| { m['id'] => m } } }.values
    end

    def add_gravatar_uri(users, email_key)
      users.each { |u| u['gravatar_uri'] = "http://gravatar.com/avatar/#{Digest::MD5.hexdigest(u['email'])}" }
    end
  end

  # --- Resources ------------------------------------
  # though really more like routes that want to use resources

  get '/' do
    projects_json = get_parsed "#{zen_api_uri}/projects"
    @projects = projects_json['items']
    haml :index
  end

  get '/dash/:project_id' do |project_id|
    @project = get_parsed "#{zen_api_uri}/projects/#{project_id}"
    @users = get_parsed "#{zen_uri_fake}/projects/#{project_id}/users"
    add_gravatar_uri(@users, 'email')
    phases = get_parsed "#{zen_api_uri}/projects/#{project_id}/phases"
    @phases = phases['items']
    haml :dash
  end

  get '/chart_data/:project_id' do |project_id|
    stories = get_parsed "#{zen_api_uri}/projects/#{project_id}/stories?with=milestones"
    phases = get_parsed "#{zen_api_uri}/projects/#{project_id}/phases"
    chart_data = compute_chart_data(stories['items'], phases['items'])
    content_type :json
    chart_data.to_json
  end

  get '/projects/:project_id/users' do |project_id|
    roles = get_parsed "#{zen_api_uri}/projects/#{project_id}/roles"
    users = compute_users(roles['items'])
    content_type :json
    users.to_json
  end

  # --- Mocks -----------------------------------------

  get '/projects' do
    content_type :json
    File.read("public/json/projects.json")
  end

  get '/projects/:project_id' do |project_id|
    content_type :json
    File.read("public/json/project.json")
  end

  get '/projects/:project_id/stories' do |project_id|
    content_type :json
    File.read("public/json/stories.json")
  end

  get '/projects/:project_id/phases' do |project_id|
    content_type :json
    File.read("public/json/phases.json")
  end

  get '/projects/:project_id/roles' do |project_id|
    content_type :json
    File.read("public/json/roles.json")
  end
end
