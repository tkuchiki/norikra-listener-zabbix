require "test_helper"
require "socket"
require "json"

Norikra::Log.init(ENV["LOGLEVEL"] || "ERROR", nil, {})

class Norikra::Listener::ZabbixTest < Minitest::Test
  def do_tcpserver(response)
    t = Thread.start do
      server = TCPServer.open(0)
      @port = server.addr[1]
      
      loop do
        Thread.start(server.accept) do |sock|
          response.call(sock)
          sock.close
        end
      end
      server.close
    end

    sleep 1

    return t
  end
  
  def test_label
    assert_equal "ZABBIX", Norikra::Listener::Zabbix.label
  end

  def test_argument
    args = ["localhost", "zabbix-host", "prefix"]
    assert_equal Norikra::Listener::Zabbix.parse_argument("localhost,zabbix-host,prefix"), args
    assert_equal Norikra::Listener::Zabbix.parse_argument("localhost, zabbix-host, prefix"), args
    assert_equal Norikra::Listener::Zabbix.parse_argument(" localhost, zabbix-host , prefix "), args
  end

  def test_initialize
    args = ["localhost", "zabbix-host", "prefix"]
    listener = Norikra::Listener::Zabbix.new("localhost,zabbix-host,prefix", "query_name", "ZABBIX(localhost,zabbix-host,prefix)")
    assert_equal listener.zabbix_server, args[0]
    assert_equal listener.host, args[1]
    assert_equal listener.prefix_item_key
    assert_equal listener.port, 10051

    listener = Norikra::Listener::Zabbix.new("localhost,zabbix-host,prefix,60051", "query_name", "ZABBIX(localhost,zabbix-host,prefix,60051)")
    assert_equal listener.zabbix_server, args[0]
    assert_equal listener.host, args[1]
    assert_equal listener.prefix_item_key, args[2]
    assert_equal listener.port, 60051
  end

  def test_format_value
    listener = Norikra::Listener::Zabbix.new("localhost,zabbix-host,prefix", "query_name", "ZABBIX(localhost,zabbix-host,prefix)")
    assert_equal "1.2345", listener.format_value(1.23454) # round off
    assert_equal "1.2346", listener.format_value(1.23456) # round up
    assert_equal "1.2345", listener.format_value(1.2345)
    assert_equal "string", listener.format_value("string")
  end

  def test_send_to_zabbix
    response = Proc.new do |s|
      res = JSON.generate({
        "response" => "success",
        "info" => "Processed 0 Failed 1 Total 1 Seconds spent 0.000103"
      })
      
      s.write("ZBXD\x01" + [ res.size ].pack("q") + res)
      s.flush
    end
    t = do_tcpserver(response)
    
    listener = Norikra::Listener::Zabbix.new("localhost,zabbix-host,prefix,#{@port}", "query_name", "ZABBIX(localhost,zabbix-host,prefix,#{@port})")
    epoch = Time.now.to_i
    data = [{ host: "zabbix-host", time: epoch, key: "prefix.val1", value: 1.2345 }]
    refute listener.send(epoch, data)
    
    t.exit 
  end

  def test_process_async
    response = Proc.new do |s|
      res = JSON.generate({
        "response" => "success",
        "info" => "Processed 2 Failed 0 Total 2 Seconds spent 0.000103"
      })
      
      s.write("ZBXD\x01" + [ res.size ].pack("q") + res)
      s.flush
    end
    t = do_tcpserver(response)
    
    listener = Norikra::Listener::Zabbix.new("localhost,zabbix-host,prefix,#{@port}", "query_name", "ZABBIX(localhost,zabbix-host,prefix,#{@port})")
    assert listener.process_async([[1454556814, {"val1"=>0, "val2"=>1.2345,}]])
    
    t.exit 
  end
end
