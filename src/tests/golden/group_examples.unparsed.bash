#!/usr/bin/env bash
_flap_test_group_examples_completion()
{
  local cur prev group w i start skip used words
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD - 1]}
  start=1
  group=""
  skip=0
  for ((i=1; i<COMP_CWORD; i++)); do
    w=${COMP_WORDS[i]}
    if [ $skip -gt 0 ] ; then
      skip=$((skip - 1))
      continue
    fi
    case "$w" in
      gwe|gne) group="$w" ; start=$((i + 1)) ; continue ;;
    esac
    case "$group" in
      '')
        case "$w" in
          --string|-s) skip=1 ;;
        esac ;;
      gwe)
        case "$w" in
          --integer|-i) skip=1 ;;
        esac ;;
      gne)
        case "$w" in
          --float|-f) skip=1 ;;
        esac ;;
    esac
  done
  used="${COMP_WORDS[*]:$start:$((COMP_CWORD - start))}"
  if [ "$group" == "gwe" ] ; then
    words=""
    case " $used " in *" --integer "*|*" --integer="*|*" -i "*|*" -i="*) ;; *) words="$words --integer -i" ;; esac
    case " $used " in *" --help "*|*" --help="*|*" -h "*|*" -h="*) ;; *) words="$words --help -h" ;; esac
    case " $used " in *" --markdown "*|*" --markdown="*|*" -md "*|*" -md="*) ;; *) words="$words --markdown -md" ;; esac
    case " $used " in *" --version "*|*" --version="*|*" -v "*|*" -v="*) ;; *) words="$words --version -v" ;; esac
    COMPREPLY=( $( compgen -W "$words" -- $cur ) )
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
    words=""
    case " $used " in *" --float "*|*" --float="*|*" -f "*|*" -f="*) ;; *) words="$words --float -f" ;; esac
    case " $used " in *" --help "*|*" --help="*|*" -h "*|*" -h="*) ;; *) words="$words --help -h" ;; esac
    case " $used " in *" --markdown "*|*" --markdown="*|*" -md "*|*" -md="*) ;; *) words="$words --markdown -md" ;; esac
    case " $used " in *" --version "*|*" --version="*|*" -v "*|*" -v="*) ;; *) words="$words --version -v" ;; esac
    COMPREPLY=( $( compgen -W "$words" -- $cur ) )
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
    words=""
    case " $used " in *" --string "*|*" --string="*|*" -s "*|*" -s="*) ;; *) words="$words --string -s" ;; esac
    case " $used " in *" --help "*|*" --help="*|*" -h "*|*" -h="*) ;; *) words="$words --help -h" ;; esac
    case " $used " in *" --markdown "*|*" --markdown="*|*" -md "*|*" -md="*) ;; *) words="$words --markdown -md" ;; esac
    case " $used " in *" --version "*|*" --version="*|*" -v "*|*" -v="*) ;; *) words="$words --version -v" ;; esac
    COMPREPLY=( $( compgen -W "$words" -- $cur ) )
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
complete -o default -F _flap_test_group_examples_completion flap_test_group_examples
