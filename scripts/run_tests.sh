#!/bin/bash

# TODO re-insert after tests suite refactoring
# all_passed () {
#   local array="$1[@]"
#   local ok=1
#   for element in "${!array}"; do
#     if [ "$element" == 'F' ]; then
#       ok=0
#       break
#     fi
#   done
#   echo $ok
# }

# echo "Run all tests"
# declare -a tests_executed
# for e in $( find ./exe/ -type f -executable -print ); do
#   is_passed=`$e | grep -i "Are all tests passed? " | awk '{print $5}'`
#   tests_executed=("${tests_executed[@]}" "$is_passed")
#   echo "  run test $e, is passed? $is_passed"
#   if [ "$is_passed" == 'F' ]; then
#     echo
#     echo "Test failed"
#     $e
#   fi
# done
# passed=$(all_passed tests_executed)
# echo "Number of tests executed ${#tests_executed[@]}"
# if [ $passed -eq 1 ]; then
#   echo "All tests passed"
#   exit 0
# else
#   echo "Some tests failed"
#   exit 1
# fi
./exe/flap_test_ansi_color_style
./exe/flap_test_basic
./exe/flap_test_basic -v
./exe/flap_test_basic -h
./exe/flap_test_basic -s 'Hello FLAP' -i 2
./exe/flap_test_basic -s 'Hello FLAP' -i 3 -ie 11
./exe/flap_test_basic 33.0 -s 'Hello FLAP' --integer_list 10 -3 87 -i 3 -r 64.123d0  --boolean --boolean_val .false.
./exe/flap_test_basic -s 'Hello FLAP' --man_file FLAP.1
./exe/flap_test_basic -s 'Hello FLAP' -vlI1P 2 1 3 -vlI2P 12 -2 -vlI4P 1 -vlI8P 1 -vlR8P 121.31 -vlR4P 3423121.31 -vlChar foo bar -vlBool T F T F
./exe/flap_test_basic -s 'Hello FLAP' -- foo.bar bar/baz.f90
./exe/flap_test_choices_logical
./exe/flap_test_group
./exe/flap_test_hidden -s 'hello' -i 2
./exe/flap_test_minimal -s 'hello'
./exe/flap_test_nested
./exe/flap_test_nested -h
./exe/flap_test_nested -a
./exe/flap_test_nested init
./exe/flap_test_nested init commit -m 'hello'
./exe/flap_test_nested commit -m 'hello'
./exe/flap_test_nested tag -a 'hello'
./exe/flap_test_string
