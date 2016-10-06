#!/bin/bash -
#
# File:        intstall.sh
#
# Description: A utility script that builds FLAP project
#
# License:     GPL3+
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

# DEBUGGING
set -e
set -C # noclobber

# INTERNAL VARIABLES AND INITIALIZATIONS
readonly USERNAME="szaghi"
readonly PROJECT="FLAP"
readonly GITHUB="https://github.com/$USERNAME/$PROJECT"
readonly PROGRAM=`basename "$0"`

function projectdownload () {
  if [ $VERBOSE -eq 1 ]; then
    echo "download project"
  fi

  if command -v $DOWNLOAD >/dev/null 2>&1; then
    if [ $VERBOSE -eq 1 ]; then
      echo "  using $DOWNLOAD"
    fi
  else
    echo "error: $DOWNLOAD tool (to download project) not found"
    exit 1
  fi

  if [ "$DOWNLOAD" == "git" ]; then
    git clone --recursive $GITHUB
    cd $PROJECT
    git submodule update --init --recursive
    cd -
  elif [ "$DOWNLOAD" == "wget" ]; then
    wget $(curl -s https://api.github.com/repos/$USERNAME/$PROJECT/releases/latest | grep 'browser_' | cut -d\" -f4)
    tar xf $PROJECT.tar.gz
    rm -f $PROJECT.tar.gz
  fi

  if [ $VERBOSE -eq 1 ]; then
    echo "project downloaded into: $PROJECT"
  fi
}

function projectbuild () {
  if [ $VERBOSE -eq 1 ]; then
    echo "build project"
  fi

  if [ "$BUILD" == "fobis" ]; then
    BUILD="FoBiS.py"
  fi

  if command -v $BUILD >/dev/null 2>&1; then
    if [ $VERBOSE -eq 1 ]; then
      echo "  using $BUILD"
    fi
  else
    echo "error: $BUILD tool (to build project) not found"
    exit 1
  fi

  if [ "$BUILD" == "FoBiS.py" ]; then
    FoBiS.py build -mode static-gnu
  elif [ "$BUILD" == "make" ]; then
    make -j 1 STATIC=yes
  elif [ "$BUILD" == "cmake" ]; then
    mkdir -p static
    cd static
    cmake ../
    cmake --build .
    cd ../
  fi
}

function usage () {
    echo "Install script of $PROJECT"
    echo "Usage:"
    echo
    echo "$PROGRAM --help|-?"
    echo "    Print this usage output and exit"
    echo
    echo "$PROGRAM --download|-d <arg> [--verbose|-v]"
    echo "    Download the project"
    echo
    echo "    --download|-d [arg]  Download the project, arg=git|wget to download with git or wget respectively"
    echo "    --verbose|-v         Output verbose mode activation"
    echo
    echo "$PROGRAM --build|-b <arg> [--verbose|-v]"
    echo "    Build the project"
    echo
    echo "    --build|-b [arg]  Build the project, arg=fobis|make|cmake to build with FoBiS.py, GNU Make or CMake respectively"
    echo "    --verbose|-v      Output verbose mode activation"
    echo
    echo "Examples:"
    echo
    echo "$PROGRAM --download git"
    echo "$PROGRAM --build make"
    echo "$PROGRAM --download wget --build cmake"
}

DOWNLOAD=0
BUILD=0
VERBOSE=0

# RETURN VALUES/EXIT STATUS CODES
readonly E_BAD_OPTION=254

# PROCESS COMMAND-LINE ARGUMENTS
if [ $# -eq 0 ]; then
  usage
  exit 0
fi
while test $# -gt 0; do
  if [ x"$1" == x"--" ]; then
    # detect argument termination
    shift
    break
  fi
  case $1 in
    --download | -d )
      shift
      DOWNLOAD="$1"
      shift
      ;;

    --build | -b )
      shift
      BUILD="$1"
      shift
      ;;

    --verbose | -v )
      shift
      VERBOSE=1
      ;;

    -? | --help )
      usage
      exit
      ;;

    -* )
      echo "Unrecognized option: $1" >&2
      usage
      exit $E_BAD_OPTION
      ;;

    * )
      break
      ;;
  esac
done

if [ "$DOWNLOAD" != "0" ] && [ "$BUILD" == "0" ]; then
  projectdownload
elif [ "$DOWNLOAD" == "0" ] && [ "$BUILD" != "0" ]; then
  projectbuild
elif [ "$DOWNLOAD" != "0" ] && [ "$BUILD" != "0" ]; then
  projectdownload
  cd $PROJECT
  projectbuild
fi

exit 0
