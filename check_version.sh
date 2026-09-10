#!/usr/bin/env bash
set -Eeu

readonly MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly REGEX="image_name\": \"(.*)\""
readonly JSON=`cat ${MY_DIR}/docker/image_name.json`
[[ ${JSON} =~ ${REGEX} ]]
readonly IMAGE_NAME="${BASH_REMATCH[1]}"

# Fails when the named gem is absent or is not at the named version. Both gems
# are checked because the start-point's manifest.json names both of them, and a
# version printed there that the image does not hold is a lie to the learner.
check_gem_version()
{
  local -r gem_name="${1}"
  local -r expected="${2}"
  local -r actual=$(docker run --rm --interactive ${IMAGE_NAME} sh -c "gem list | grep ${gem_name}")

  if echo "${actual}" | grep --quiet "${expected}"; then
    echo "VERSION CONFIRMED as ${gem_name} ${expected}"
  else
    echo "VERSION EXPECTED: ${gem_name} ${expected}"
    echo "VERSION   ACTUAL: ${actual}"
    exit 42
  fi
}

check_gem_version minitest 6.0
check_gem_version mocha 3.1
