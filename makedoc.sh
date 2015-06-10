#!/bin/bash
GITREPO=$1
git config --global user.name "Stefano Zaghi"
git config --global user.email "stefano.zaghi@gmail.com"
git clone --branch=gh-pages https://${GH_TOKEN}@github.com/szaghi/$GITREPO doc/html
FoBiS.py rule -ex makedoc
cd doc/html
git add -f --all *
git commit -m "Travis CI autocommit from travis build ${TRAVIS_BUILD_NUMBER}"
git push -f origin gh-pages
