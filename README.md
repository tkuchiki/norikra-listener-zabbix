# Norikra::Listener::Zabbix

[![Build Status](https://travis-ci.org/tkuchiki/norikra-listener-zabbix.svg?branch=master)](https://travis-ci.org/tkuchiki/norikra-listener-zabbix)
[![Coverage Status](https://coveralls.io/repos/github/tkuchiki/norikra-listener-zabbix/badge.svg?branch=master)](https://coveralls.io/github/tkuchiki/norikra-listener-zabbix?branch=master)

## Description

Norikra listener plugin to send performance data for Zabbix.

## Installation

```
gem install norikra-listener-zabbix
```

## Usage

Add your query with group ZABBIX(zabbix_server,zabbix_host,preifx_item_key,[port=10051]).

## Examples

```
SELECT sum(foo) AS sum, avg(foo) AS avg FROM test_table.win:time_batch(1 min)
-- group ZABBIX(localhost, zabbix host, foo.bar)
```

Send data `sum` and `avg` to item key `foo.bar.sum`, `foo.bar.avg`.

### Zabbix Items

- Key: `foo.bar.svg`
- Type: `Zabbix trapper`
- Type of information: `Numeric (float)`


## Misc

Many codes was copied from [fujiwara/fluent-plugin-zabbix](https://github.com/fujiwara/fluent-plugin-zabbix/blob/master/lib/fluent/plugin/out_zabbix.rb).
