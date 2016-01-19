#! /usr/bin/env ruby
#  encoding: UTF-8
#
#
#  check-alerts
#
#  DESCRIPTION:
#    Check Ambari for active alerts and split into individual events
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
#  Originally by Carmelo Lucio  Date: 01/19/2016#
#  Released under the same terms as Sensu (the MIT License); see LICENSE 
#  for details.
#
require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

class CheckAmbariAlerts < Sensu::Plugin::Check::CLI
  option :port,
         short: '-P PORT',
         long: '--port PORT',
         description: 'Ambari Port',
         default: 8080

  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'Ambari host',
         default: '127.0.0.1'

  option :auth_enabled,
         short: '-a',
         long: '--auth',
         description: 'Set if auth is enabled for Ambari',
         boolean: true,
         default: true
 
  option :username,
         short: '-u USERNAME',
         long: '--user USERNAME',
         description: 'Ambari user',
         default: 'sensu'

  option :password,
         short: '-p PASSWORD',
         long: '--password PASSWORD',
         description: 'Ambari user password',
         default: 'sensu'

  option :sensu_client_host,
         long: '--sensu_client_host SENSU_HOST',
         description: 'Sensu Client Host',
         default: '127.0.0.1'

  option :sensu_client_port,
         long: '--sensu_client_port SENSU_PORT',
         description: 'Sensu Client Port',
         default: 3030


  # Execute Ambari API call
  def ambari_cmd(host, port, uri, request_type, post_data = nil)
    begin
      case request_type
      when 'GET'
        return JSON.parse RestClient::Request.execute method: :get, url: "http://#{host}:#{port}#{uri}", user: "#{username}", password: "#{password}" 
        #return JSON.parse RestClient.get "http://#{host}:#{port}#{uri}" 
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


  # Get alerts from ambari, and send each back through sensu client
  def get_alerts(host, port, cluster_id, sensu_client_host, sensu_client_port)
    uri = "/api/v1/clusters/#{cluster_id}/alerts"
    alert_list = ambari_cmd(host, port, uri, "GET")

    # build list of sensu alerts
    alert_list.map do |ambari_alert|
      # Get alert rule info
      uri = "/#{cluster_id}/alerts/#{ambari_alert['alert_rule_id']}"
      alert_rule = ambari_cmd(host, port, uri, "GET")
      
      # Build sensu alert
      sensu_alert = { name: "#{cluster_id}", 
                      address: "#{ambari_alert['host_name']}",
                      datacenter: "#{ambari_alert['dc']}",
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
    ambari_host = config[:host]
    ambari_port = config[:port]
    sensu_client_host = config[:sensu_client_host]
    sensu_client_port = config[:sensu_client_port]

    ## Get list of clusters
    uri = "/clusters"
    cluster_list = ambari_cmd( ambari_host, ambari_port, uri, "GET" )

    # Get alerts for each cluster
    cluster_list.each do |cluster_id, attributes|
      get_alerts( ambari_host, ambari_port, cluster_id, sensu_client_host, sensu_client_port )
    end

    ok
  end
end

