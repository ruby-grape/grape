require 'rubygems'
require 'bundler'

Bundler.setup :default, :test, :development

def version
  @version ||= open('VERSION').read.trim
end

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

begin
  require 'yard'
  YARD_OPTS = ['-m', 'markdown', '-M', 'maruku']
  DOC_FILES = ['lib/**/*.rb', 'README.markdown']
  
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = DOC_FILES
    t.options = YARD_OPTS
  end
  
  namespace :doc do
    YARD::Rake::YardocTask.new(:pages) do |t|
      t.files   = DOC_FILES
      t.options = YARD_OPTS + ['-o', '../grape.doc']
    end
    
    namespace :pages do
      desc 'Generate and publish YARD docs to GitHub pages.'
      task :publish => ['doc:pages'] do
        Dir.chdir(File.dirname(__FILE__) + '/../grape.doc') do
          system("git add .")
          system("git add -u")
          system("git commit -m 'Generating docs for version #{version}.'")
          system("git push origin gh-pages")
        end
      end
    end
  end
rescue LoadError
  puts "You need to install YARD."
end