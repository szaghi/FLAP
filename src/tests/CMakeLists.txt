include(GNUInstallDirs)

SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/tests/${CMAKE_INSTALL_BINDIR}")

function(add_flap_test test_src libraries)
    get_filename_component(test_name ${test_src} NAME_WE)
    get_filename_component(test_dir ${test_src} DIRECTORY)
    set(result_src "${test_dir}/${test_name}.result")

    add_executable(${test_name} ${test_src})
    foreach(lib IN LISTS libraries)
        target_link_libraries(${test_name} ${lib})
    endforeach()
    add_test(NAME ${test_name} COMMAND ${test_name})
#
#    file(STRINGS ${result_src} result_raw)
#    string(REGEX REPLACE "([+.])([^+.]*)" "\\\\\\1\\2" result ${result_raw})
#
#    set_tests_properties(${test_name} PROPERTIES
#        PASS_REGULAR_EXPRESSION "${result}"
#    )
endfunction()

# shared test utilities (assertions, output capture, self re-invocation); *.F90 is not globbed as a test program
add_library(flap_test_utils STATIC flap_test_utils.F90)
target_link_libraries(flap_test_utils FLAP::FLAP)

file(GLOB_RECURSE flap_tests *.f90)

foreach(flap_test IN LISTS flap_tests)
    add_flap_test(${flap_test} "FLAP::FLAP;flap_test_utils")
endforeach()

# golden baselines are read from the source tree, while ctest runs in the build tree
set_tests_properties(flap_test_golden PROPERTIES ENVIRONMENT "FLAP_TEST_GOLDEN_DIR=${CMAKE_CURRENT_SOURCE_DIR}/golden")
