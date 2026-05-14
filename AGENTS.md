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

Keep the entry to a single short line — one clause naming the change at a high level. Detail belongs in the PR description, not the changelog. Open the PR with no changelog entry first (or with a placeholder), then amend the commit with the real entry once the PR number is assigned. The "Your contribution here." line must remain last in each section.

## UPGRADING.md

Update [UPGRADING.md](UPGRADING.md) only when introducing a **contract break** — a change in documented behavior or public API that an upgrading user has to act on. Pure refactors, internal cleanups, performance work, and additive options do not need an UPGRADING entry. Add a subsection under the current version heading (e.g. `### Upgrading to >= 3.2.0`), describing what changed and how to adapt.

## Code Style

- Ruby style is enforced via RuboCop (`.rubocop.yml`), with pinned gem versions in `Gemfile`.
- Run `bundle exec rubocop` to check and `bundle exec rubocop -a` to auto-fix.
- Frozen string literals are required in all files (`# frozen_string_literal: true`).
- Minimum Ruby version is 3.2.

Beyond what RuboCop enforces, prefer:

- **Guard clauses over trailing `if/else` (and over `if/elsif/elsif/else` ladders).** When a method ends in branching where one or more arms is a short special case, lift each special case to a `return … if …` / `return … unless …` so the main flow sits at top indentation. Reach for guards even when none of the branches are obviously "the special case" — three guards followed by a bare expression is usually clearer than a three-arm `if/elsif/else`.
- **Don't return from inside a `case/when`.** If a `when` branch should short-circuit the method, lift it to a guard clause above the `case`; the `when` arms then stay as plain expressions evaluating to a value.
- **Don't use `case/when` for class-identity dispatch.** `when SomeClass` matches with `===`, i.e. `value.is_a?(SomeClass)` — that's correct only when dispatching on an *instance*. When dispatching on a class *value* (e.g. `type` is the class itself), use `if type == X` or `[X, Y].include?(type)` instead.
- **No comments restating what the code does.** Reserve comments for *why* something non-obvious is happening (hidden constraint, surprising invariant, workaround) — well-named identifiers carry the *what*.

## Commits and PRs

- Never push directly to master — always work on a branch and open a PR targeting `ruby-grape/grape master`.
- **One commit per PR**, kept current by amending — don't stack follow-up "address review" or "fix CI" commits on the branch. After amending, force-push with `git push --force-with-lease` (never plain `--force`).
- Split changes by concern: one logical refactor / feature / fix per PR. When a working tree contains unrelated changes, stash the others and open them separately rather than bundling.
- PR titles and commit messages should be clear and imperative (e.g. "Fix UnknownAuthStrategy when subclassing Auth::Base").
- Reference the related issue in the commit message and PR description (e.g. `Fixes #1234`).

## Rebasing Open PRs

When `origin/master` advances and an open branch needs to catch up:

```
git fetch origin master
git checkout <branch>
git rebase origin/master
# resolve conflicts, run the touched specs
git push --force-with-lease origin <branch>
```

CHANGELOG conflicts are common when two open PRs both add entries at the bottom of `#### Features` / `#### Fixes` — resolve by keeping both entries in PR-number order (oldest first). Mixed conflicts in `lib/` should be resolved on their merits: preserve the master version's structural changes and re-apply the branch's intent on top, rather than reverting either side wholesale.

## Gem Dependencies

Core runtime dependencies are declared in `grape.gemspec`. Development and test dependencies are in `Gemfile`. Do not add new runtime dependencies without discussion; prefer what is already available (ActiveSupport, dry-types, Rack).

## Multiple Gemfile Variants

The `gemfiles/` directory contains alternate Gemfiles for testing against different Rack and Rails versions. CI runs against all of them. When fixing compatibility issues, test locally with:

```
BUNDLE_GEMFILE=gemfiles/rack_3_2.gemfile bundle exec rspec
```
