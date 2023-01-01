#!/bin/sh

set -e

# echoes version of ruby, rubygems and bundle
echo -e "$(ruby --version)\nrubygems $(gem --version)\n$(bundle version)"

# keep gems in the latest possible state
(bundle check || bundle install) && bundle update && bundle exec ${@}
