#!/bin/bash

gem build grape.gemspec
gem install grape-1.7.0.gem
rackup try.ru