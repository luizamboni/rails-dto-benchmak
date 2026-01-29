# -*- encoding: utf-8 -*-
# stub: sorbet-rails 0.7.34 ruby lib

Gem::Specification.new do |s|
  s.name = "sorbet-rails".freeze
  s.version = "0.7.34".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chan Zuckerberg Initiative".freeze]
  s.date = "2019-04-18"
  s.email = "opensource@chanzuckerberg.com".freeze
  s.homepage = "https://github.com/chanzuckerberg/sorbet-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Set of tools to make Sorbet work with Rails seamlessly.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<parlour>.freeze, [">= 4.0.1".freeze])
  s.add_runtime_dependency(%q<sorbet-runtime>.freeze, [">= 0.5.9892".freeze])
  s.add_runtime_dependency(%q<sorbet-coerce>.freeze, [">= 0.2.6".freeze])
  s.add_runtime_dependency(%q<method_source>.freeze, [">= 0.9.2".freeze])
  s.add_runtime_dependency(%q<parser>.freeze, [">= 2.7".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8".freeze, ">= 3.8".freeze])
  s.add_development_dependency(%q<awesome_print>.freeze, ["~> 1.8.0".freeze, ">= 1.8.0".freeze])
  s.add_development_dependency(%q<byebug>.freeze, ["~> 11.1.3".freeze, ">= 11.1.3".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 3.8.2".freeze])
  s.add_development_dependency(%q<puma>.freeze, [">= 3.12.1".freeze])
  s.add_development_dependency(%q<database_cleaner>.freeze, [">= 1.7.0".freeze])
end
