#! /usr/bin/env ruby
#  encoding: UTF-8
#
#
#  check-alerts
#
#  DESCRIPTION:
#    Check Opscenter for active alerts and split into individual events
#
#  OUTPUT:
#    plain text
#
#  PLATFORMS:
#    Linux
#
#  DEPENDENCIES:
#    gem:  sensu-client
#    gem:  rest-client
#    gem:  json
#
#  USAGE:
#   
#  NOTES:
#
#  LICENSE:
#  Originally by Timothy Given  Date: 10/09/2015#
#  Released under the same terms as Sensu (the MIT License); see LICENSE 
#  for details.
#
require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

class CheckOpscenterAlerts < Sensu::Plugin::Check::CLI
  option :port,
         short: '-P PORT',
         long: '--port PORT',
         description: 'Opscenter Port',
         default: 8888

  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'Opscenter host',
         default: '127.0.0.1'

  option :auth_enabled,
         short: '-a',
         long: '--auth',
         description: 'Set if auth is enabled for Cassandra/Opscenter',
         boolean: true,
         default: false
 
  option :username,
         short: '-u USERNAME',
         long: '--user USERNAME',
         description: 'Opscenter user',
         default: 'sensu'

  option :password,
         short: '-p PASSWORD',
         long: '--password PASSWORD',
         description: 'Opscenter user password',
         default: ''

  option :sensu_client_host,
         long: '--sensu_client_host SENSU_HOST',
         description: 'Sensu Client Host',
         default: '127.0.0.1'

  option :sensu_client_port,
         long: '--sensu_client_port SENSU_PORT',
         description: 'Sensu Client Port',
         default: 3030


  # Execute Opcenter API call
  def opscenter_cmd(host, port, uri, request_type, post_data = nil)
    begin
      case request_type
      when 'GET'
        return JSON.parse RestClient.get "http://#{host}:#{port}#{uri}" 
      when 'POST'
        ## to be added
      else
        warning 'Invalid http request'
      end

    rescue => err
      warning "ERROR: #{err}" 
    end
  end


  # Forward Alert to Sensu Client
  def forward_alert(host, port, alert_info)
    begin
      sensu_client_socket = TCPSocket.open(host, port)
      sensu_client_socket.print(alert_info.to_json)
      resp_sensu_client_raw = sensu_client_socket.read
    rescue => err
      warning "ERROR: #{err}"
    end
  end


  # Get alerts from opscenter, and send each back through sensu client
  def get_alerts(host, port, cluster_id, sensu_client_host, sensu_client_port)
    uri = "/#{cluster_id}/alerts/fired"
    alert_list = opscenter_cmd(host, port, uri, "GET")

    # build list of sensu alerts
    alert_list.map do |opscenter_alert|
      # Get alert rule info
      uri = "/#{cluster_id}/alert-rules/#{opscenter_alert['alert_rule_id']}"
      alert_rule = opscenter_cmd(host, port, uri, "GET")
      
      # Build sensu alert
      sensu_alert = { name: "#{cluster_id}", 
                      address: "#{opscenter_alert['node']}",
                      datacenter: "#{opscenter_alert['dc']}",
                      output: "#{alert_rule['type']}",
                      status: 2
      }
      
      # Forward alert directly to sensu client
      puts sensu_alert
      forward_alert( sensu_client_host, sensu_client_port, sensu_alert )
    end
  end
    

  # Check entry point
  def run
    opscenter_host = config[:host]
    opscenter_port = config[:port]
    sensu_client_host = config[:sensu_client_host]
    sensu_client_port = config[:sensu_client_port]

    ## Get list of clusters
    uri = "/cluster-configs"
    cluster_list = opscenter_cmd( opscenter_host, opscenter_port, uri, "GET" )

    # Get alerts for each cluster
    cluster_list.each do |cluster_id, attributes|
      get_alerts( opscenter_host, opscenter_port, cluster_id, sensu_client_host, sensu_client_port )
    end

    ok
  end
end

