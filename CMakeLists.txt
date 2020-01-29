# The target of the library FLAP is exported
# as FLAP::FLAP to a package config file for FLAP
#
# usage:
#     find_package(FLAP)
#     ...
#     target_link_library(<target> FLAP)
#
# the config file is generatet in the build and install directories

cmake_minimum_required(VERSION 3.10...3.13)
project(FLAP VERSION 1.1.8 LANGUAGES Fortran)

# seach path for additional cmake modules
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)


# set export variables needed for building
set(TARGETS_EXPORT_NAME "${PROJECT_NAME}Targets")
set(NAMESPACE "${PROJECT_NAME}::")

#add dependencies from subdirs
if(NOT TARGET PENF)
    add_subdirectory(src/third_party/PENF)
endif()

if(NOT TARGET FACE)
add_subdirectory(src/third_party/FACE)
endif()

if(NOT TARGET fortran_tester)
add_subdirectory(src/third_party/fortran_tester)
endif()
# generate the library and install instructions
add_subdirectory(src/lib)

# testing
if(${PROJECT_SOURCE_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
    set(main_project TRUE)
else()
    set(main_project FALSE)
endif()

include(CMakeDependentOption)
cmake_dependent_option(BUILD_TESTING_${PROJECT_NAME}
     "Build the testing tree for project ${PROJECT_NAME}." OFF
     "BUILD_TESTING;NOT main_project" OFF
)

if (main_project AND NOT DEFINED BUILD_TESTING)
    set(BUILD_TESTING ON)
endif()

if((main_project AND BUILD_TESTING) OR BUILD_TESTING_${PROJECT_NAME})
    enable_testing()
    add_subdirectory(src/tests)
endif()

# generate package config files
include(GNUInstallDirs)
set(project_config "${PROJECT_NAME}Config.cmake")
set(cmake_files_dir "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles")
set(config_install_dir "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
set(config_build_dir "${CMAKE_CURRENT_BINARY_DIR}/${config_install_dir}")

# export targets for install
install(EXPORT ${TARGETS_EXPORT_NAME}
    NAMESPACE
        ${NAMESPACE}
    DESTINATION
        ${config_install_dir}
    COMPONENT Development
)

# export targets into build
export(EXPORT ${TARGETS_EXPORT_NAME}
    NAMESPACE
        ${NAMESPACE}
    FILE
        ${config_build_dir}/${TARGETS_EXPORT_NAME}.cmake
)

#create package config
include(CMakePackageConfigHelpers)
configure_package_config_file(cmake/PackageConfig.cmake.in ${cmake_files_dir}/${project_config}
    INSTALL_DESTINATION ${config_install_dir}
)
install(FILES ${cmake_files_dir}/${project_config}
    DESTINATION ${config_install_dir}
)

configure_package_config_file(cmake/PackageConfig.cmake.in ${config_build_dir}/${project_config}
    INSTALL_DESTINATION ${config_build_dir}
    INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}
)
