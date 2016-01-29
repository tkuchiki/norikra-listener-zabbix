require 'norikra/logger'
require 'norikra/listener'
require 'socket'
require 'json'
include Norikra::Log

module Norikra
  module Listener
    class Zabbix < Norikra::Listener::Base
      def self.label
        "ZABBIX"
      end

      def initialize(argument, query_name, query_group)
        super
        args = argument.split(",").map(&:strip)
        @zabbix_server = args[0]
        @host = args[1]
        @key_prefix = args[2]
        @port = args[3] || 10051
        
        raise Norikra::ArgumentError, "zabbix_server is not specified" unless @zabbix_server
        raise Norikra::ArgumentError, "host is not specified" unless @host
        raise Norikra::ArgumentError, "key_prefix is not specified" unless @key_prefix
        raise Norikra::ArgumentError, "invalid port: #{@port}" if @port.to_i == 0
      end

      def process_async(events)
        data = []
        t = nil
        events.each do |time, record|
          t = time if t.nil?
          record.each do |key, value|
            data.push({ host: @host, time: time.to_i, key: "#{@key_prefix}.#{key}", value: format_value(value) })
          end
        end
        debug "send data #{@zabbix_sever}:#{@port} #{@host} #{data}"
        begin
          send(t, data)
        rescue => e
          warn "send data failed #{e}"
        end
      end

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
        data.each do |d|
        end
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
      end
      
      def send_to_zabbix(sock, time, data)
        zbxd = "ZBXD\x01"
        req = JSON.generate({
          :request => 'agent data',
          :clock => time.to_i,
          :data => data,
        })
        sock.write(zbxd + [ req.size ].pack('q') + req)
        sock.flush

        header = sock.read(5)
        if header != zbxd
          return false
        end
        len = sock.read(8).unpack('q')[0]
        res = JSON.parse(sock.read(len))
        debug "response: #{res}"
        return res['response'] == "success"
      end
    end
  end
end
