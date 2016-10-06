#!/bin/bash
set -ev # echo what we are doing and fail on errors
GITREPO=$1
git config --global user.name "Stefano Zaghi"
git config --global user.email "stefano.zaghi@gmail.com"
if [[ "${TRAVIS}" = "true" && "${TRAVIS_PULL_REQUEST}" != "false" ]]; then
    # Running under travis during a PR. No access to GH_TOKEN so abort
    # documentation deployment, without throwing an error
    FoBiS.py rule -ex makedoc
    exit 0
fi
# either we are not on TRAVIS and maybe you want to manually deploy documentation
# or we are on TRAVIS but not testing a PR so it is safe to deploy documentation
git clone --branch=gh-pages https://${GH_TOKEN}@github.com/$GITREPO.git doc/html
FoBiS.py rule -ex makedoc
cd doc/html
git add -f --all './*'
git commit -m "Travis CI autocommit from travis build ${TRAVIS_BUILD_NUMBER}"
git push -f origin gh-pages > /dev/null 2>&1
