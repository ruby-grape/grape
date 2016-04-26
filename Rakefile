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

require 'rainbow/ext/string' unless String.respond_to?(:color)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: [:rubocop, :spec]

begin
  require 'yard'
  DOC_FILES = ['lib/**/*.rb', 'README.md'].freeze

  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files = DOC_FILES
  end

  namespace :doc do
    YARD::Rake::YardocTask.new(:pages) do |t|
      t.files   = DOC_FILES
      t.options = ['-o', '../grape.doc/docs']
    end

    namespace :pages do
      desc 'Check out gh-pages.'
      task :checkout do
        dir = File.dirname(__FILE__) + '/../grape.doc'
        unless Dir.exist?(dir)
          Dir.mkdir(dir)
          Dir.chdir(dir) do
            system('git init')
            system('git remote add origin git@github.com:ruby-grape/grape.git')
            system('git pull')
            system('git checkout gh-pages')
          end
        end
      end

      desc 'Generate and publish YARD docs to GitHub pages.'
      task publish: ['doc:pages:checkout', 'doc:pages'] do
        Dir.chdir(File.dirname(__FILE__) + '/../grape.doc') do
          system('git checkout gh-pages')
          system('git add .')
          system('git add -u')
          system("git commit -m 'Generating docs for version #{Grape::VERSION}.'")
          system('git push origin gh-pages')
        end
      end
    end
  end
rescue LoadError # rubocop:disable Lint/HandleExceptions
  # ignore
end
