require 'rubygems'
require 'bundler'
Bundler.setup :default, :test, :development

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec
task :default => :spec

begin
  require 'yard'
  DOC_FILES = ['lib/**/*.rb', 'README.md']

  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = DOC_FILES
  end

  namespace :doc do
    YARD::Rake::YardocTask.new(:pages) do |t|
      t.files   = DOC_FILES
      t.options = ['-o', '../grape.doc']
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
