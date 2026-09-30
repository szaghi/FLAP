#!/usr/bin/env bash
_completion()
{
  local cur prev group w
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD - 1]}
  group=""
  for w in "${COMP_WORDS[@]:1:$((COMP_CWORD - 1))}"; do
    case "$w" in
      gwe|gne) group="$w" ; break ;;
    esac
  done
  if [ "$group" == "gwe" ] ; then
    COMPREPLY=( $( compgen -W " --integer -i --help -h --markdown -md --version -v" -- $cur ) )
    if [ "$prev" == "--integer" ] || [ "$prev" == "-i" ] ; then
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
  elif [ "$group" == "gne" ] ; then
    COMPREPLY=( $( compgen -W " --float -f --help -h --markdown -md --version -v" -- $cur ) )
    if [ "$prev" == "--float" ] || [ "$prev" == "-f" ] ; then
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
    COMPREPLY=( $( compgen -W " --string -s --help -h --markdown -md --version -v" -- $cur ) )
    COMPREPLY+=( $( compgen -W "gwe gne" -- $cur ) )
    if [ "$prev" == "--string" ] || [ "$prev" == "-s" ] ; then
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
  fi
  return 0
}
complete -o default -F _completion flap_test_group_examples
