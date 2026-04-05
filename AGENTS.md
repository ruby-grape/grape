# AI Agent Instructions

## Starting Work

Before creating a new branch, always sync and clean up:

```
git checkout master
git pull upstream master
git branch --merged master | grep -v '^\* \|^  master$' | xargs -r git branch -d
```

## After Making Code Changes

Always run before committing:

```
bundle exec rake
```

This runs RuboCop and the full RSpec suite. If RuboCop reports offenses, fix them with `bundle exec rubocop -a` then re-run.

For code you write, fix RuboCop offenses directly rather than adding them to `.rubocop_todo.yml`. If a fix is non-trivial, it is acceptable to run `bundle exec rubocop --auto-gen-config` to update the todo file instead.

## Tests

- Tests live in `spec/grape/` and use RSpec.
- Add tests for all new features and bug fixes in the appropriate `spec/grape/` subdirectory.
- Run a single spec file with `bundle exec rspec spec/path/to/file_spec.rb`.
- Run the full RSpec suite with `bundle exec rspec`.
- The test suite uses `rack-test` for HTTP-level specs. Include `Rack::Test::Methods` and define `app` in specs that need it.

## Changelog

Update [CHANGELOG.md](CHANGELOG.md) for every user-facing change. Add a line under `#### Features` or `#### Fixes` in the current unreleased section at the top, in this format:

```
* [#PR](https://github.com/ruby-grape/grape/pull/PR): Description of change - [@username](https://github.com/username).
```

Use a placeholder PR number when the PR is not yet open; update it after opening. The entry for "Your contribution here." must remain as the last line in each section.

## UPGRADING.md

Update [UPGRADING.md](UPGRADING.md) when introducing a **breaking change or behavior change** that users will need to act on when upgrading. Add a subsection under the current version heading (e.g. `### Upgrading to >= 3.2.0`), describing what changed and how to adapt.

## Code Style

- Ruby style is enforced via RuboCop (`.rubocop.yml`), with pinned gem versions in `Gemfile`.
- Run `bundle exec rubocop` to check and `bundle exec rubocop -a` to auto-fix.
- Frozen string literals are required in all files (`# frozen_string_literal: true`).
- Minimum Ruby version is 3.2.

## Commits and PRs

- Never push directly to master — always work on a branch and open a PR targeting `ruby-grape/grape master`.
- One logical commit per PR; squash before merging.
- PR titles and commit messages should be clear and imperative (e.g. "Fix UnknownAuthStrategy when subclassing Auth::Base").
- Reference the related issue in the commit message and PR description (e.g. `Fixes #1234`).

## Gem Dependencies

Core runtime dependencies are declared in `grape.gemspec`. Development and test dependencies are in `Gemfile`. Do not add new runtime dependencies without discussion; prefer what is already available (ActiveSupport, dry-types, Rack).

## Multiple Gemfile Variants

The `gemfiles/` directory contains alternate Gemfiles for testing against different Rack and Rails versions. CI runs against all of them. When fixing compatibility issues, test locally with:

```
BUNDLE_GEMFILE=gemfiles/rack_3_2.gemfile bundle exec rspec
```
