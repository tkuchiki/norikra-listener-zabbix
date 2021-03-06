# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "norikra-listener-zabbix"
  spec.version       = "0.2.0"
  spec.authors       = ["KUCHIKI Taku"]
  spec.email         = ["kuchiki.taku@gmail.com"]
  spec.summary       = %q{Norikra listener plugin to send performance data for Zabbix.}
  spec.description   = %q{Norikra listener plugin to send performance data for Zabbix.}
  spec.homepage      = "https://github.com/tkuchiki/norikra-listener-zabbix"
  spec.license       = "GPLv2"
  spec.platform      = "java"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib", "jar"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "json"
  spec.add_runtime_dependency "norikra"
end
