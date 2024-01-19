module Agents
  class ZoomStatusAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule '5m'

    description do
      <<-MD
      The Zoom agent fetches Zoom status.
      I added this agent because with website agent, when indicator is empty for "all ok status", no event was created.

      The `debug` can add verbosity.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "status": {
              "indicator": "none",
              "description": "All Systems Operational"
            }
          }
    MD

    def default_options
      {
        'debug' => 'false',
        'expected_receive_period_in_days' => '2',
        'changes_only' => 'true'
      }
    end

    form_configurable :debug, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :changes_only, type: :boolean

    def validate_options

      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      check_status
    end

    private

    def log_curl_output(code,body)

      log "request status : #{code}"

      if interpolated['debug'] == 'true'
        log "request status : #{code}"
        log "body"
        log body
      end

    end

    def check_status()

      uri = URI.parse("https://status.zoom.us/api/v2/status.json")
      response = Net::HTTP.get_response(uri)

      log_curl_output(response.code,response.body)

      payload = JSON.parse(response.body)
      event = payload.dup
      event = { :status => { :name =>  "#{payload['page']['name']}", :indicator => "#{payload['status']['indicator']}", :description => "#{payload['status']['description']}" } }

      if interpolated['changes_only'] == 'true'
        if payload != memory['last_status']
          memory['last_status'] = payload
          create_event payload: event
        end
      else
        create_event payload: event
        if payload != memory['last_status']
          memory['last_status'] = payload
        end
      end
    end
  end
end
