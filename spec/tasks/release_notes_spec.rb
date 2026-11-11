# frozen_string_literal: true

require 'ruby-gem-release/rspec'
require_relative '../../tasks/release'

describe GrapeRelease do
  include RubyGemRelease::RSpec

  it 'runs the production README hooks in the release and next development commits' do
    with_release_project do |project|
      project.copy_files(path: File.expand_path('../..', __dir__), files: %w[tasks/release.rb grape.gemspec lib/grape/version.rb README.md CHANGELOG.md])
      project.configure_workflow(require: 'tasks/release', builder: 'GrapeRelease.workflow')
      project.commit!

      project.release!(version: '4.2.9')

      readme = File.read(File.expand_path('../../README.md', __dir__))
      section = /^## Stable Release\n.*?(?=^## |\z)/m
      stable = "You're reading the documentation for the stable release of Grape, 4.2.9."
      development = "You're reading the documentation for the next release of Grape, which should be 4.2.10.\n" \
                    'The current stable release is [4.2.9](https://github.com/ruby-grape/grape/blob/v4.2.9/README.md).'
      expect(project.remote_file('v4.2.9', 'README.md')).to eq(readme.sub(section, "## Stable Release\n\n#{stable}\n\n").strip)
      expect(project.remote_file('master', 'README.md')).to eq(readme.sub(section, "## Stable Release\n\n#{development}\n\n").strip)
      expect(project.git('status', '--porcelain')).to eq('')
    end
  end
end
