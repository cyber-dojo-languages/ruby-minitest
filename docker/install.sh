#!/bin/bash -Eeu

apk --update add --virtual build-dependencies build-base
gem install mocha --no-document
apk del build-dependencies build-base
rm -vrf /var/cache/apk/*

# Returns the version of an installed gem, as RubyGems resolves it, so the
# record is the gem a kata loads.
gem_version()
{
  ruby -e 'print Gem::Specification.find_by_name(ARGV[0]).version' "${1}"
}

# Appends one test framework to the test_frameworks list the base image
# wrote in /versions.json, keeping any entry an earlier image added. Stops
# the build if the list is not found, rather than record nothing. Short grep
# flags because busybox grep has no long ones.
add_test_framework()
{
  local -r name="${1}"
  local -r version="${2}"
  local -r entry="{\"name\": \"${name}\", \"version\": \"${version}\"}"
  if grep -q '"test_frameworks": \[\]' /versions.json; then
    sed -i "s|\"test_frameworks\": \[\]|\"test_frameworks\": [${entry}]|" /versions.json
  else
    sed -i "/\"test_frameworks\": \[/s|}\]|}, ${entry}]|" /versions.json
  fi
  if ! grep -q -F "${entry}" /versions.json; then
    echo "Could not add ${name} to /versions.json" >&2
    cat /versions.json >&2
    exit 1
  fi
}

add_test_framework MiniTest "$(gem_version minitest)"
add_test_framework Mocha "$(gem_version mocha)"
cat /versions.json
