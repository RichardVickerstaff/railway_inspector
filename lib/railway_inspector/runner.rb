require 'railway_inspector/routes'
require 'httparty'
require 'factory_girl'

module  RailwayInspector
  class Runner

    def initialize
      @all_routes = RailwayInspector::Routes.new.all_routes
      @ok = []
      @bad = []
      @not_run = []
    end

    def handle_response response, route
      if response.code == 200
        @ok << response
        puts Term::ANSIColor.green + "OK: #{route[:path]}"
      else
        @bad << response
        puts Term::ANSIColor.red + "Broken: #{route[:path]} with code #{response.code} #{response.message}"
      end
    end

    def handle_path_error path, route
      @not_run << route
      puts Term::ANSIColor.yellow + "NA: #{route[:path]} could not run because: #{path[:error].message}"
    end

    def create_path route
      if route[:path].match(/.*\/:id/)
        begin
          model = FactoryGirl.create(route[:controller].gsub(/s$/, '').to_sym)
          { path: 'http://localhost:3000' + route[:path].gsub(':id', model.id.to_s) } 
        rescue => e
          { error: e }
        end
      else
        { path: 'http://localhost:3000' + route[:path] }
      end
    end

    def run
      FactoryGirl.find_definitions
      @all_routes.each do|route|
        next unless route[:verbs].include? 'get'
        path = create_path(route)
        if path[:error]
          handle_path_error(path, route)
        else
          response = HTTParty.get(path[:path])
          handle_response(response, route)
        end
      end

      puts Term::ANSIColor.yellow + "There are #{@not_run.length} routes we could not test"
      puts Term::ANSIColor.red + "There are #{@bad.length} broken routes"
    end
  end
end

