require "norikra/logger"
require "norikra/listener"
require "socket"
require "json"
include Norikra::Log

module Norikra
  module Listener
    class Zabbix < Norikra::Listener::Base
      attr_reader :zabbix_server, :host, :prefix_item_key, :port
      
      def self.label
        "ZABBIX"
      end

      def self.parse_argument(args)
        args.split(",").map(&:strip)
      end

      def self.split_host_port(address)
        colon = address.count(":")
        
        case
        when colon == 0 # IPv4 or FQDN
          host = address
          port = 10051
        when colon == 1 # IPv4 or FQDN
          hosts = address.split(":")
          len   = hosts.size - 1
          host  = hosts[0, len].join(":")
          port  = hosts[len].to_i
        when colon >= 2 # IPv6
          begin
            hosts = address.match(/\[(.+)\]:?(.+)?/)
            host  = hosts[1]
            port  = (hosts[2] || 10051).to_i
          rescue
            host = nil
            port = nil
          end
        end

        [host, port]
      end

      def initialize(argument, query_name, query_group)
        super
        args = Zabbix::parse_argument(argument)
        @zabbix_server, @port = Zabbix::split_host_port(args[0])
        @host = args[1]
        @prefix_item_key = args[2]
        
        raise Norikra::ArgumentError, "zabbix_server is not specified" unless @zabbix_server
        raise Norikra::ArgumentError, "invalid port: #{@port}" if @port == 0
        raise Norikra::ArgumentError, "host is not specified" unless @host
        raise Norikra::ArgumentError, "prefix_item_key is not specified" unless @prefix_item_key
      end

      def process_async(events)
        data = []
        t = nil
        events.each do |time, record|
          t = time if t.nil?
          record.each do |key, value|
            data.push({ host: @host, time: time.to_i, key: "#{@prefix_item_key}.#{key}", value: format_value(value) })
          end
        end
        debug "send data #{@zabbix_sever}:#{@port} #{@host} #{data}"
        begin
          send(t, data)
        rescue => e
          warn "send data failed #{e}"
        end
      end

      # https://github.com/fujiwara/fluent-plugin-zabbix/blob/master/lib/fluent/plugin/out_zabbix.rb
      
      def format_value(value)
        if value.kind_of?(Float)
          # https://www.zabbix.com/documentation/2.4/manual/config/items/item
          # > Allowed range (for MySQL): -999999999999.9999 to 999999999999.9999 (double(16,4)).
          # > Starting with Zabbix 2.2, receiving values in scientific notation is also supported. E.g. 1e+70, 1e-70.
          value.round(4).to_s
        else
          value.to_s
        end
      end

      def send(time, data)
        begin
          sock = TCPSocket.open(@zabbix_server, @port)
          debug "zabbix: #{sock} #{data}, ts: #{time}"
          result = send_to_zabbix(sock, time, data)
        rescue => e
          warn "exception: #{e}"
          result = false
        ensure
          sock.close if sock
        end

        unless result
          warn "failed to send to zabbix_server: #{@zabbix_server}:#{@port} #{data}"
        end

        result
      end
      
      def send_to_zabbix(sock, time, data)
        zbxd = "ZBXD\x01"
        req = JSON.generate({
          :request => "agent data",
          :clock => time.to_i,
          :data => data,
        })
        sock.write(zbxd + [ req.size ].pack("q") + req)
        sock.flush

        header = sock.read(5)
        if header != zbxd
          return false
        end
        len = sock.read(8).unpack("q")[0]
        res = JSON.parse(sock.read(len))
        
        info = res["info"].split(" ")
        processed = info[1].to_i
        failed = info[3].to_i
        debug "response: #{res}"
        warn "failed response: Processed #{processed} Failed #{failed}" if processed == 0
        
        return res["response"] == "success" && processed > 0
      end
    end
  end
end
