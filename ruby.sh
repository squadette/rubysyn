#! /bin/bash

set -e

source /var/rubysyn/rvm/scripts/rvm

rvm install `cat .ruby-version`

exec /bin/bash
