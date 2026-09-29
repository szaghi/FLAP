#/usr/bin/env bash
_completion()
{
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD - 1]}
  groups=( "gwe" "gne" )
  for g in ${groups[@]}; do
    if [ "$prev" == "$g" ] ; then
      group=$prev 
    fi
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
    COMPREPLY=( )
    COMPREPLY+=( $( compgen -W "
    COMPREPLY=( $( compgen -W " --string -s --help -h --markdown -md --version -v" -- $cur ) ) --string -s --help -h --markdown -md --version -v" -- $cur ) )
    COMPREPLY+=( $( compgen -W "gwe" -- $cur ) )
    COMPREPLY+=( $( compgen -W "gne" -- $cur ) )
  fi
  return 0
}
complete -F _completion flap_test_group_examples
