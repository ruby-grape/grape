require 'rubygems'
require 'bundler'

Bundler.setup :default, :test, :development

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "grape"
    gem.summary = %Q{A Ruby framework for rapid API development.}
    gem.description = %Q{A Ruby framework for rapid API development with great conventions.}
    gem.email = "michael@intridea.com"
    gem.homepage = "http://github.com/intridea/grape"
    gem.authors = ["Michael Bleigh"]
    gem.add_bundler_dependencies
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies
task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "grape #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
