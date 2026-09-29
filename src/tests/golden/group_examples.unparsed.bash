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
    COMPREPLY=( $( compgen -W " --integer -i" -- $cur ) )
    if [ "$prev" == "--integer" ] || [ "$prev" == "-i" ] ; then
       COMPREPLY=( )
       return 0
    fi
  elif [ "$group" == "gne" ] ; then
    COMPREPLY=( $( compgen -W " --float -f" -- $cur ) )
    if [ "$prev" == "--float" ] || [ "$prev" == "-f" ] ; then
       COMPREPLY=( )
       return 0
    fi
  else    
    COMPREPLY=( )
    COMPREPLY+=( $( compgen -W "
    COMPREPLY=( $( compgen -W " --string -s" -- $cur ) ) --string -s" -- $cur ) )
    COMPREPLY+=( $( compgen -W "gwe" -- $cur ) )
    COMPREPLY+=( $( compgen -W "gne" -- $cur ) )
  fi
  return 0
}
complete -F _completion flap_test_group_examples
