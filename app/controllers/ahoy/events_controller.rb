module Ahoy
  class EventsController < Ahoy::BaseController
    def create
      events =
        if params[:name]
          # legacy API
          [params]
        else
          begin
            ActiveSupport::JSON.decode(request.body.read)
          rescue ActiveSupport::JSON.parse_error
            # do nothing
            []
          end
        end

      events.each do |event|
        time = Time.zone.parse(event["time"]) rescue nil

        # timestamp is deprecated
        time ||= Time.zone.at(event["time"].to_f) rescue nil

        options = {
          id: event["id"],
          time: time
        }
        ahoy.track event["name"], event["properties"], options
        
        # Store visitor 
        if ahoy.visit.nil?
          ahoy.track_visit(event['properties'])
        end
      end
      render json: {}
    end
  end
end
