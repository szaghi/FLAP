#!/usr/bin/env bash
_completion()
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
      init|commit|tag) group="$w" ; start=$((i + 1)) ; continue ;;
    esac
    case "$group" in
      commit)
        case "$w" in
          --message|-m) skip=1 ;;
        esac ;;
      tag)
        case "$w" in
          --annotate|-a) skip=1 ;;
        esac ;;
    esac
  done
  used="${COMP_WORDS[*]:$start:$((COMP_CWORD - start))}"
  if [ "$group" == "init" ] ; then
    words=""
    case " $used " in *" --help "*|*" --help="*|*" -h "*|*" -h="*) ;; *) words="$words --help -h" ;; esac
    case " $used " in *" --markdown "*|*" --markdown="*|*" -md "*|*" -md="*) ;; *) words="$words --markdown -md" ;; esac
    case " $used " in *" --version "*|*" --version="*|*" -v "*|*" -v="*) ;; *) words="$words --version -v" ;; esac
    COMPREPLY=( $( compgen -W "$words" -- $cur ) )
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
    words=""
    case " $used " in *" --message "*|*" --message="*|*" -m "*|*" -m="*) ;; *) words="$words --message -m" ;; esac
    case " $used " in *" --help "*|*" --help="*|*" -h "*|*" -h="*) ;; *) words="$words --help -h" ;; esac
    case " $used " in *" --markdown "*|*" --markdown="*|*" -md "*|*" -md="*) ;; *) words="$words --markdown -md" ;; esac
    case " $used " in *" --version "*|*" --version="*|*" -v "*|*" -v="*) ;; *) words="$words --version -v" ;; esac
    COMPREPLY=( $( compgen -W "$words" -- $cur ) )
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
    words=""
    case " $used " in *" --annotate "*|*" --annotate="*|*" -a "*|*" -a="*) ;; *) words="$words --annotate -a" ;; esac
    case " $used " in *" --help "*|*" --help="*|*" -h "*|*" -h="*) ;; *) words="$words --help -h" ;; esac
    case " $used " in *" --markdown "*|*" --markdown="*|*" -md "*|*" -md="*) ;; *) words="$words --markdown -md" ;; esac
    case " $used " in *" --version "*|*" --version="*|*" -v "*|*" -v="*) ;; *) words="$words --version -v" ;; esac
    COMPREPLY=( $( compgen -W "$words" -- $cur ) )
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
    words=""
    case " $used " in *" --authors "*|*" --authors="*|*" -a "*|*" -a="*) ;; *) words="$words --authors -a" ;; esac
    case " $used " in *" --help "*|*" --help="*|*" -h "*|*" -h="*) ;; *) words="$words --help -h" ;; esac
    case " $used " in *" --markdown "*|*" --markdown="*|*" -md "*|*" -md="*) ;; *) words="$words --markdown -md" ;; esac
    case " $used " in *" --version "*|*" --version="*|*" -v "*|*" -v="*) ;; *) words="$words --version -v" ;; esac
    COMPREPLY=( $( compgen -W "$words" -- $cur ) )
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
complete -o default -F _completion test_nested
