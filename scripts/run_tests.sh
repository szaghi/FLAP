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
./exe/test_minimal -s 'hello'
./exe/test_hidden -s 'hello' -i 2
./exe/test_basic
./exe/test_basic -v
./exe/test_basic -h
./exe/test_basic -s 'Hello FLAP' -i 2
./exe/test_basic -s 'Hello FLAP' -i 3 -ie 11
./exe/test_basic 33.0 -s 'Hello FLAP' --integer_list 10 -3 87 -i 3 -r 64.123d0  --boolean --boolean_val .false.
./exe/test_basic -s 'Hello FLAP' --man_file FLAP.1
./exe/test_basic -s 'Hello FLAP' -vlI1P 2 1 3 -vlI2P 12 -2 -vlI4P 1 -vlI8P 1 -vlR8P 121.31 -vlR4P 3423121.31 -vlChar foo bar -vlBool T F T F
./exe/test_basic -s 'Hello FLAP' -- foo.bar bar/baz.f90
./exe/test_nested
./exe/test_nested -h
./exe/test_nested -a
./exe/test_nested init
./exe/test_nested init commit -m 'hello'
./exe/test_nested commit -m 'hello'
./exe/test_nested tag -a 'hello'
./exe/test_string
./exe/test_choices_logical
