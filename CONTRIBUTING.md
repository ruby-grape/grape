Contributing to Grape
=====================

Grape is work of [hundreds of contributors](https://github.com/ruby-grape/grape/graphs/contributors). You're encouraged to submit [pull requests](https://github.com/ruby-grape/grape/pulls), [propose features and discuss issues](https://github.com/ruby-grape/grape/issues).

#### Fork the Project

Fork the [project on Github](https://github.com/ruby-grape/grape) and check out your copy.

```
git clone https://github.com/contributor/grape.git
cd grape
git remote add upstream https://github.com/ruby-grape/grape.git
```

#### Create a Topic Branch

Make sure your fork is up-to-date and create a topic branch for your feature or bug fix.

```
git checkout master
git pull upstream master
git checkout -b my-feature-branch
```

### Docker

If you're familiar with [Docker](https://www.docker.com/), you can run everything through the following command:

```
docker-compose run --rm --build grape <command_and_parameters>
```

About the execution process:
 - displays Ruby, Rubygems, Bundle and Gemfile version when starting:
    ```
    ruby 3.2.2 (2023-03-30 revision e51014f9c0) [x86_64-linux-musl]
    rubygems 3.4.12
    Bundler version 2.4.1 (2022-12-24 commit f3175f033c)
    Running default Gemfile
    ```
 - keeps the gems to the latest possible version
 - executes under `bundle exec`

Here are some examples:

- running all specs `docker-compose run --rm --build grape rspec`
- running rspec on a specific file `docker-compose run --rm --build grape rspec spec/:file_path`
- running task `docker-compose run --rm --build grape rake <task_name>`
- running rubocop `docker-compose run --rm --build grape rubocop`
- running all specs on a specific ruby version (e.g 3.4) `RUBY_VERSION=3.4 docker-compose run --rm --build grape rspec`
- running specs on a specific gemfile (e.g rails_8_1.gemfile) `docker-compose run -e GEMFILE=rails_8_1 --rm --build grape rspec`

#### Bundle Install and Test

Ensure that you can build the project and run tests.

```
bundle install
bundle exec rake
```

#### Write Tests

Try to write a test that reproduces the problem you're trying to fix or describes a feature that you want to build. Add to [spec/grape](spec/grape).

We definitely appreciate pull requests that highlight or reproduce a problem, even without a fix.

#### Write Code

Implement your feature or bug fix.

Ruby style is enforced with [Rubocop](https://github.com/bbatsov/rubocop), run `bundle exec rubocop` and fix any style issues highlighted.

Make sure that `bundle exec rake` completes without errors.

#### Write Documentation

Document any external behavior in the [README](README.md).

You should also document code as necessary, using current code as examples. This project uses [YARD](https://yardoc.org/). You can run and preview the docs locally by [installing `yard`](https://yardoc.org/), running `yard server --reload` and view the docs at http://localhost:8808.

#### Update Changelog

Add a line to [CHANGELOG](CHANGELOG.md) under *Next Release*. Make it look like every other line, including your name and link to your Github account.

#### Commit Changes

Make sure git knows your name and email address:

```
git config --global user.name "Your Name"
git config --global user.email "contributor@example.com"
```

Writing good commit logs is important. A commit log should describe what changed and why.

```
git add ...
git commit
```

#### Push

```
git push origin my-feature-branch
```

#### Make a Pull Request

Go to https://github.com/contributor/grape and select your feature branch. Click the 'Pull Request' button and fill out the form. Pull requests are usually reviewed within a few days.

#### Rebase

If you've been working on a change for a while, rebase with upstream/master.

```
git fetch upstream
git rebase upstream/master
git push origin my-feature-branch -f
```

#### Update CHANGELOG Again

Update the [CHANGELOG](CHANGELOG.md) with the pull request number. A typical entry looks as follows.

```
* [#123](https://github.com/ruby-grape/grape/pull/123): Reticulated splines - [@contributor](https://github.com/contributor).
```

Amend your previous commit and force push the changes.

```
git commit --amend
git push origin my-feature-branch -f
```

#### Check on Your Pull Request

Go back to your pull request after a few minutes and see whether it passed muster with CI. Everything should look green, otherwise fix issues and amend your commit as described above.

#### Be Patient

It's likely that your change will not be merged and that the nitpicky maintainers will ask you to do more, or fix seemingly benign problems. Hang in there!

#### Thank You

Please do know that we really appreciate and value your time and work. We love you, really.
