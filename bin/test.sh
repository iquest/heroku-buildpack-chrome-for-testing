#!/usr/bin/env bash

set -euo pipefail

STACK_VERSION="${1:?'Error: The stack version number must be specified as the first argument.'}"
# The second argument selects the build: chrome (default) or headless-shell.
GOOGLE_CHROME_BUILD="${2:-chrome}"
if [[ "${GOOGLE_CHROME_BUILD}" == "headless-shell" ]]; then
  CHROME_BIN="chrome-headless-shell"
else
  CHROME_BIN="chrome"
fi

set -x

docker build --progress=plain --build-arg="STACK_VERSION=${STACK_VERSION}" --build-arg="GOOGLE_CHROME_BUILD=${GOOGLE_CHROME_BUILD}" -t heroku-buildpack-chrome-for-testing .

# Note: All of the container commands must be run via a login bash shell otherwise the profile.d scripts won't be run.

# Check the profile.d scripts correctly added the binaries to PATH.
docker run --rm heroku-buildpack-chrome-for-testing bash -l -c "${CHROME_BIN} --version"
docker run --rm heroku-buildpack-chrome-for-testing bash -l -c 'chromedriver --version'

# Check that there are no missing dynamically linked libraries.
docker run --rm heroku-buildpack-chrome-for-testing bash -l -c "ldd \$(which ${CHROME_BIN})"
docker run --rm heroku-buildpack-chrome-for-testing bash -l -c 'ldd $(which chromedriver)'

# Check Chrome can fully boot.
docker run --rm heroku-buildpack-chrome-for-testing bash -l -c "${CHROME_BIN} --no-sandbox --headless --screenshot https://google.com"

# Display a size breakdown of the directories added by the buildpack to the app.
docker run --rm heroku-buildpack-chrome-for-testing bash -l -c 'du --human-readable --max-depth=1 /app'
