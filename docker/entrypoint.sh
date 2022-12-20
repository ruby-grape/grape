#!/bin/sh

set -e

echo ${id}

# install missing gems
bundle check || bundle install

# run passed commands
if [ "$1" = "update" ];
then
  bundle ${@}
else
  bundle exec ${@}
fi