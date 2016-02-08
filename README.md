# Norikra::Listener::Zabbix

[![Build Status](https://travis-ci.org/tkuchiki/norikra-listener-zabbix.svg?branch=master)](https://travis-ci.org/tkuchiki/norikra-listener-zabbix)
[![Coverage Status](https://coveralls.io/repos/github/tkuchiki/norikra-listener-zabbix/badge.svg?branch=master)](https://coveralls.io/github/tkuchiki/norikra-listener-zabbix?branch=master)

## Description

Norikra listener plugin to send performance data for Zabbix.

## Installation

```shell
gem install norikra-listener-zabbix
```

## Usage

Add your query with group `ZABBIX(zabbix_server[:port=10051],zabbix_host[,preifx_item_key])`.

## Examples

```sql
SELECT sum(foo) AS sum, avg(foo) AS avg FROM test_table.win:time_batch(1 min)
-- group ZABBIX(localhost, zabbix host, foo.bar)
```

Send data `sum` and `avg` to item key `foo.bar.sum`, `foo.bar.avg`.

```sql
SELECT sum(foo) AS `bar$foo$sum`, avg(foo) AS `bar$foo$avg` FROM test_table.win:time_batch(1 min)
-- group ZABBIX(localhost, zabbix host)
```

Send data `sum` and `avg` to item key `bar.foo.sum`, `bar.foo.avg`.  
Replace `$` with `.`.  

>Identifiers cannot contain the "." (dot) character, i.e. "vol.price" is not a valid identifier for the rename syntax.

See: [5.3.4. Renaming event properties](http://www.espertech.com/esper/release-5.2.0/esper-reference/html/epl_clauses.html#epl-select-renaming)

```sql
SELECT sum(foo) AS sum, avg(foo) AS avg FROM test_table.win:time_batch(1 min)
-- group ZABBIX([::1], zabbix host)
```

IPv6 syntax `[IPADDR]:PORT`.

### Zabbix Items

- Key: `foo.bar.avg`
- Type: `Zabbix trapper`
- Type of information: `Numeric (float)`

## Test

```shell
rake [LOGLEVEL=ERROR]
```

```shell
rake LOGLEVEL=DEBUG
```

Set loglevel as `DEBUG`.

## Misc

Many codes was copied from [fujiwara/fluent-plugin-zabbix](https://github.com/fujiwara/fluent-plugin-zabbix/blob/master/lib/fluent/plugin/out_zabbix.rb).

## License

GPLv2
