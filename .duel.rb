# frozen_string_literal: true

# Duel's configuration: https://github.com/sferik/duel-ruby/blob/main/docs/configuration.md
#
# Duel follows conventions, so set only what differs: benchmarks are in
# duel/**/*_duel.rb, each version's lib/ is first on the load path, a
# change is compared when it touches lib/ or ext/ (or the benchmarks, or
# this file), and releases are tagged v*.
Duel.configure do |c|
  # The library each version's workers require (from the gemspec, unless
  # this says otherwise).
  # c.library = 'grape'

  # When the workflow comments on a pull request with the report: :always,
  # :results (passed or failed), :failures (failed, or couldn't compare),
  # or :never.
  # c.comment = :failures

  # Each benchmark warms up for 2 seconds before it's measured, rather
  # than until it's steady (for up to 10): Grape's requests take tens of
  # microseconds, so YJIT has compiled them long before.
  c.warm = 2

  # A label that accepts a regression in a pull request, for a change
  # that's slower on purpose (nil for none).
  # c.accept_label = 'duel: accept'
end
