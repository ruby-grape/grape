#!/bin/sh

set -e

# Useful information
echo -e "$(ruby --version)\nrubygems $(gem --version)\n$(bundle version)"

# Keep gems in the latest possible state
(bundle check || bundle install) && bundle update && bundle exec ${@}
