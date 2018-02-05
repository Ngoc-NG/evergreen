require 'concurrent/array'
require 'hashie'
require 'sinatra/base'
require 'sinatra/json'
require 'thread'

require 'app/pusher'
require 'app/updates/jenkins'

module Updates
  class App < Sinatra::Base
    set :show_exceptions => true
    set :views, File.expand_path(File.dirname(__FILE__) + '/../views/updates/')
    set :haml, :format => :html5

    before do
      if Thread.current[:apps].nil?
        Thread.current[:apps] = {
          :jenkins => Updates::Jenkins.new
        }
      end
      @apps = Thread.current[:apps]
    end

    get '/' do
      haml :index
    end

    get '/health' do
      content_type :json
      response = { :status => :ok }
      json response
    end

    post '/ping' do
      content_type :json
      payload = {
        :data => Time.now.utc.iso8601,
        :event => 'ping',
      }
      Pusher::Q.push(payload)
      redirect back
    end

    post '/validate/:app' do |app|
      content_type :json

      if updater = @apps[app.to_sym]
        halt 400 if request.body.size <= 0

        request.body.rewind
        inbound_manifest = JSON.parse(request.body.read)
        Hashie.symbolize_keys! inbound_manifest

        json updater.should_update?(inbound_manifest)
      else
        status 404
      end
    end

    head '/validate/:app' do |app|
      content_type :json

      if updater = @apps[app.to_sym]
        status 200
        headers 'Last-Modified' => updater.last_refreshed?
      else
        status 404
      end
    end
  end
end