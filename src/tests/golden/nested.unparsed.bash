#/usr/bin/env bash
_completion()
{
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD - 1]}
  groups=( "init" "commit" "tag" )
  for g in ${groups[@]}; do
    if [ "$prev" == "$g" ] ; then
      group=$prev 
    fi
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
    COMPREPLY=( )
    COMPREPLY+=( $( compgen -W "
    COMPREPLY=( $( compgen -W " --authors -a --help -h --markdown -md --version -v" -- $cur ) ) --authors -a --help -h --markdown -md --version -v" -- $cur ) )
    COMPREPLY+=( $( compgen -W "init" -- $cur ) )
    COMPREPLY+=( $( compgen -W "commit" -- $cur ) )
    COMPREPLY+=( $( compgen -W "tag" -- $cur ) )
  fi
  return 0
}
complete -F _completion test_nested
