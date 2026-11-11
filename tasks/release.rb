# frozen_string_literal: true

require 'ruby-gem-release/workflow/ruby_gem'
require 'ruby-gem-release/changelog'
require 'ruby-gem-release/markdown/section'

module GrapeRelease
  # Grape starts the next minor version after every release, patch releases included,
  # and drops an empty Features or Fixes section from a release.
  def self.workflow(**)
    workflow = RubyGemRelease::Workflow::RubyGem.new(
      version: RubyGemRelease::Version::RubyConstant.new(path: 'lib/grape/version.rb', constant: 'VERSION'),
      changelog: RubyGemRelease::Changelog::Intridea.new(placeholder: '* Your contribution here.', date_format: '%Y-%m-%d', sections: %w[Features Fixes]),
      next_version: :minor,
      **
    )

    readme = RubyGemRelease::Markdown::Section.new(path: 'README.md', heading: '## Stable Release')
    workflow.after(:prepare_release) do |ctx|
      readme.replace!("You're reading the documentation for the stable release of Grape, #{ctx.release.version}.")
    end
    workflow.after(:prepare_next) do |ctx|
      readme.replace!(
        "You're reading the documentation for the next release of Grape, which should be #{ctx.release.next_version}.\n" \
        "The current stable release is [#{ctx.release.version}](https://github.com/ruby-grape/grape/blob/v#{ctx.release.version}/README.md)."
      )
    end
    workflow
  end
end
