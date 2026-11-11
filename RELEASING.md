Releasing Grape
===============

There are no particular rules about when to release Grape. Release bug fixes frequently, features not so frequently and breaking API changes rarely.

### One-Time Setup

Releases use [ruby-gem-release 0.6.0](https://github.com/dblock/ruby-gem-release/tree/v0.6.0), pinned in both the Gemfile and reusable workflow, and RubyGems Trusted Publishing without a stored RubyGems API key.

Create a GitHub environment named `release` in **Settings > Environments**. Configure required release-maintainer reviewers, prevent self-review where appropriate, and restrict deployments to `master`. Creating an unprotected environment alone does not restrict publication: repository writers can dispatch the workflow, and required reviewers gate publication.

In the [grape trusted publishers settings](https://rubygems.org/gems/grape/trusted_publishers), configure these values:

| Field | Value |
| --- | --- |
| Repository owner | `ruby-grape` |
| Repository name | `grape` |
| Workflow filename | `release.yml` |
| Environment | `release` |
| Workflow repository owner | `dblock` |
| Workflow repository name | `ruby-gem-release` |

The workflow repository identifies the reusable workflow, not Grape's caller workflow. Ensure branch and tag rules permit `GITHUB_TOKEN` to push release commits to `master` and create `vVERSION` tags. If rules require PRs or checks that the release token cannot bypass, a repository administrator must establish an approved release policy before dispatching; the workflow does not change repository protections.

### Release

Run tests and check that all tests succeed locally:

```sh
bundle install
bundle exec rake
bundle exec rake build
```

The release specs use `ruby-gem-release/rspec` to exercise the production workflow and README hooks in a disposable Git repository, replacing registry and hosted publication with the library's local adapters. They do not publish to RubyGems or GitHub.

Double-check that the [last build succeeded](https://github.com/ruby-grape/grape/actions) for all supported platforms. Point a Grape-based project at Grape HEAD and run its API tests to catch regressions:

```ruby
gem 'grape', github: 'ruby-grape/grape'
```

Review the next section of [CHANGELOG.md](CHANGELOG.md) and the version in [lib/grape/version.rb](lib/grape/version.rb). Keep one `* Your contribution here.` placeholder in each of Features and Fixes; ruby-gem-release preserves this two-section format. Actual release notes are required.

Dispatch **Release** from `master` in GitHub Actions, or run:

```sh
gh workflow run release.yml --repo ruby-grape/grape --ref master
```

To select a different release version without a separate version-bump commit, pass `-f version=4.2.0`. Dispatching authorizes publication once the `release` environment's approval requirements are satisfied; do not dispatch from PR CI or use it as a dry run.

The workflow validates release preconditions, dates the changelog and removes both contribution placeholders, updates the README to describe the stable release, and runs `bundle exec rake`. It builds and preserves the gem and recovery artifacts, publishes that exact gem to RubyGems, pushes the release commit and tag, and creates a GitHub Release. It then increments the patch version and pushes the next development iteration with both changelog sections and the README's stable-release link restored. No manual release edits or `rake release` invocation are needed.

### Recovery

Inspect the failed run and its `release-gem-*` artifact before retrying. It can contain the built gem, checksum manifest, and Git recovery bundle. RubyGems publication cannot be undone by resetting Git: if a version was uploaded, never publish different bytes under that version or move its tag. Follow the [ruby-gem-release recovery guide](https://github.com/dblock/ruby-gem-release/blob/v0.6.0/RELEASING.md#verify-and-recover) to determine which steps completed and recover deliberately.

### Make an Announcement

Make an announcement on the [ruby-grape@googlegroups.com](mailto:ruby-grape@googlegroups.com) mailing list:

```text
Grape 4.2.0 has been released.

There were N contributors to this release, not counting documentation.

Please note the breaking API change in ...

[copy/paste CHANGELOG here]
```
