#!/usr/bin/env bash
_completion()
{
  local cur prev group w
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD - 1]}
  group=""
  for w in "${COMP_WORDS[@]:1:$((COMP_CWORD - 1))}"; do
    case "$w" in
      init|commit|tag) group="$w" ; break ;;
    esac
  done
  if [ "$group" == "init" ] ; then
    COMPREPLY=( $( compgen -W " --help -h --markdown -md --version -v" -- $cur ) )
    if [ "$prev" == "--help" ] || [ "$prev" == "-h" ] ; then
       return 0
    fi
    if [ "$prev" == "--markdown" ] || [ "$prev" == "-md" ] ; then
       return 0
    fi
    if [ "$prev" == "--version" ] || [ "$prev" == "-v" ] ; then
       return 0
    fi
  elif [ "$group" == "commit" ] ; then
    COMPREPLY=( $( compgen -W " --message -m --help -h --markdown -md --version -v" -- $cur ) )
    if [ "$prev" == "--message" ] || [ "$prev" == "-m" ] ; then
       COMPREPLY=( )
       return 0
    fi
    if [ "$prev" == "--help" ] || [ "$prev" == "-h" ] ; then
       return 0
    fi
    if [ "$prev" == "--markdown" ] || [ "$prev" == "-md" ] ; then
       return 0
    fi
    if [ "$prev" == "--version" ] || [ "$prev" == "-v" ] ; then
       return 0
    fi
  elif [ "$group" == "tag" ] ; then
    COMPREPLY=( $( compgen -W " --annotate -a --help -h --markdown -md --version -v" -- $cur ) )
    if [ "$prev" == "--annotate" ] || [ "$prev" == "-a" ] ; then
       COMPREPLY=( )
       return 0
    fi
    if [ "$prev" == "--help" ] || [ "$prev" == "-h" ] ; then
       return 0
    fi
    if [ "$prev" == "--markdown" ] || [ "$prev" == "-md" ] ; then
       return 0
    fi
    if [ "$prev" == "--version" ] || [ "$prev" == "-v" ] ; then
       return 0
    fi
  else
    COMPREPLY=( $( compgen -W " --authors -a --help -h --markdown -md --version -v" -- $cur ) )
    COMPREPLY+=( $( compgen -W "init commit tag" -- $cur ) )
    if [ "$prev" == "--authors" ] || [ "$prev" == "-a" ] ; then
       return 0
    fi
    if [ "$prev" == "--help" ] || [ "$prev" == "-h" ] ; then
       return 0
    fi
    if [ "$prev" == "--markdown" ] || [ "$prev" == "-md" ] ; then
       return 0
    fi
    if [ "$prev" == "--version" ] || [ "$prev" == "-v" ] ; then
       return 0
    fi
  fi
  return 0
}
complete -F _completion test_nested
