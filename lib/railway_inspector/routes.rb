module  RailwayInspector
  class Routes

    def initialize
      @routes = Rails.application.routes.routes
    end

    def all_routes
      @routes.to_a.map { |route|
        { 
          verbs: verbs_for(route),
          path: path_for(route),
          action: route.defaults[:action],
          controller: route.defaults[:controller], 
        }
      }
    end

    private def verbs_for route
      route.verb.source.to_s.gsub("^","").gsub("$","").downcase.split('|')
    end

    private def path_for route
      route.path.spec.to_s.gsub('(.:format)', '')
    end

  end
end

