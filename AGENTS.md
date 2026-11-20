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
- **Spec what a caller sees, not internals.** Don't pin an optimization with `instance_variable_get` or frozen-ivar assertions. Pick the cases it could get wrong and assert the answers, then check that each new spec fails without the change. Leave "the work was skipped" to a benchmark.
- **I18n in specs.** Call `I18n.backend.translations(do_init: true)` before `store_translations` of a key `en.yml` also defines, or the lazy load overwrites it. Never call `I18n.backend.eager_load!` in a spec: every later `I18n.reload!` then reloads eagerly under whatever locales are set, which broke 21 CI jobs on #3059.

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
- Minimum Ruby version is 3.3.1.

Beyond what RuboCop enforces, prefer:

- **Guard clauses over trailing `if/else` (and over `if/elsif/elsif/else` ladders).** When a method ends in branching where one or more arms is a short special case, lift each special case to a `return … if …` / `return … unless …` so the main flow sits at top indentation. Reach for guards even when none of the branches are obviously "the special case" — three guards followed by a bare expression is usually clearer than a three-arm `if/elsif/else`.
- **Don't return from inside a `case/when`.** If a `when` branch should short-circuit the method, lift it to a guard clause above the `case`; the `when` arms then stay as plain expressions evaluating to a value.
- **Don't use `case/when` for class-identity dispatch.** `when SomeClass` matches with `===`, i.e. `value.is_a?(SomeClass)` — that's correct only when dispatching on an *instance*. When dispatching on a class *value* (e.g. `type` is the class itself), use `if type == X` or `[X, Y].include?(type)` instead.
- **No comments restating what the code does.** Reserve comments for *why* something non-obvious is happening (hidden constraint, surprising invariant, workaround) — well-named identifiers carry the *what*.
- **`blank?` / `present?` only on outside input.** Request data (params, headers, query values) and values a developer hands over (a body, `error!` headers or backtrace, `desc` options, translations, a class to register, whose `name` can be overridden) arrive loosely typed, and `blank?`'s leniency is the point there. A request String must be scrubbed first, though: `blank?`'s whitespace regexp raises on an invalid byte sequence. A value Grape built or has already normalized has a known type, so ask exactly what it can be: `empty?` for a collection that is never nil, `nil? || empty?` where nil is a real state, and truthiness for an object or nil. Prefer removing nil at the source (as `stacked` does with `EMPTY_STACK`) over guarding against it. This keeps every `blank?` a place to check for scrubbing.
- **`empty?`, not `== ''`.** Where a value can be of any type (coercers, validators, params), scope the check to Strings: `value.is_a?(String) && value.empty?`. A bare `empty?` raises on an Integer, and `respond_to?(:empty?)` would also turn `[]` and `{}` into nil.
- **Keep `unless x.empty?` on request paths.** `empty?` compiles to its own VM instruction on String, Array and Hash, while `any?` is a method call, and `any?` answers differently when every element is falsy (`[nil].any?` is false). Don't let a cop rewrite them.
- **Forward with `Forwardable`.** Use `extend Forwardable` and `def_delegator`, not hand-written one-line methods or ActiveSupport's `delegate`. The exception is a reader on the request path: a `def_delegator` method checks `defined?` on every call, so write it out with a comment saying why, as `Grape::Endpoint` does.
- **Declare settings with a class macro.** A family of same-bodied reader/writer pairs is declared with a private class macro (`inheritable_property :auth`), not an inline `define_method` loop. Inline loops stay for the DSL verb families already written that way.
- **Share state through an explicit `Data`.** When one object starts from another's state, hold that state in a `Data.define` naming exactly what is carried, and rebuild it with `with`. Don't copy instance variables through reflection with a deny-list, which silently carries any ivar added later.
- **Keep the smallest surface.** When replacing a class, keep only the methods something calls: grep for callers and run the suite without the rest. Anything a released version had gets an UPGRADING note when it goes.
- **Don't work around Rack's internals.** No `defined?(Rack::X)` load-time branches, `bind_call` bypasses of Rack methods, or Rack subclasses that memoize. When Rack is slow to answer, restructure Grape's own question: cheap env checks first, parse once and pass the result down, compare against Rack's public constants.
- **Worked examples in comments go on class docs and public methods**, not on private helpers.
- **YARD `@!method` directives.** Indent the docstring under the directive, and qualify every `(see …)` in full, as in `(see Grape::DSL::Parameters#requires)`. A bare `(see #requires)` resolves to nothing, without a warning.

## Pitfalls

- `Grape::RACK_ERRORS` is an Array of exception classes, for `rescue *Grape::RACK_ERRORS`. The `'rack.errors'` env key is `Rack::RACK_ERRORS`. Inside `Grape::`, an unqualified `RACK_ERRORS` resolves to the Array.
- On Rack 3, `Rack::CONTENT_LENGTH` is the response header name, `content-length`. The request's env key is the literal `'CONTENT_LENGTH'`.
- `Rack::Headers.new(hash)` returns an empty Hash whose *default value* is `hash`. Copy with `Rack::Headers.new.merge!(hash)`, which allocates once (`merge` allocates twice).
- Both mustermann requires in `lib/grape.rb` are needed: `mustermann/ast/pattern` alone raises `NameError` on `URI`. The suite stays green without the first one only because dry-types happens to load `uri` earlier.
- On a request path, never read an exception's `backtrace` eagerly, and never rescue just to re-raise. At request depth either one costs about 25 µs, against 1–3 µs for a plain `raise` and `rescue`. Pass `original_exception:` along, and match in the `rescue` clause with a module that defines `self.===`.

## Performance

Benchmarks live in `benchmark/`. Read [benchmark/README.md](benchmark/README.md) before measuring a change: several traps there make an A/B look like a regression, or make a benchmark measure nothing.

## Commits and PRs

- Never push directly to master — always work on a branch and open a PR targeting `ruby-grape/grape master`.
- **One commit per PR**, kept current by amending — don't stack follow-up "address review" or "fix CI" commits on the branch. After amending, force-push with `git push --force-with-lease` (never plain `--force`).
- Split changes by concern: one logical refactor / feature / fix per PR. When a working tree contains unrelated changes, leave them in place and open them separately rather than bundling.
- **Stage explicit paths**, as in `git add CHANGELOG.md lib/x.rb spec/x_spec.rb`. Never use `git add -A` or `git add .`: a working tree often carries files that aren't yours, such as a fresh `benchmark/version_throughput/RESULTS.md`. Don't `git stash pop` without checking `git stash list` first, since a `git stash push` that found nothing to save leaves someone else's entry on top.
- **No AI session links** in PR descriptions, commit messages or comments. The repository is public.
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

After every rebase, diff `CHANGELOG.md` and `UPGRADING.md` against `origin/master`, even when the rebase was clean:
- A rebase past a release can leave the PR's entries under the version just released.
- A clean rebase appends entries after master's latest, not in PR-number order.
- It can also drop the blank line before an UPGRADING `####` heading.

Then run the full `bundle exec rake`: a textually clean rebase can still break the branch.

## Gem Dependencies

Core runtime dependencies are declared in `grape.gemspec`. Development and test dependencies are in `Gemfile`. Do not add new runtime dependencies without discussion; prefer what is already available (ActiveSupport, dry-types, Rack).

## Multiple Gemfile Variants

The `gemfiles/` directory contains alternate Gemfiles for testing against different Rack and Rails versions. CI runs against all of them. When fixing compatibility issues, test locally with:

```
BUNDLE_GEMFILE=gemfiles/rack_3_2.gemfile bundle exec rspec
```
