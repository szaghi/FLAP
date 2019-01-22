#################################################################
# Search F90 files recursively in all subdirs
#################################################################

FILE(GLOB_RECURSE LIB_SRC *.f90 *.F90 *.c)
SET(LIB_SRC ${LIB_SRC} PARENT_SCOPE)

#################################################################
# Library target
#################################################################
ADD_LIBRARY(${LIB} ${LIB_SRC})

#################################################################
# External projects
#################################################################
FOREACH(PENF_LIB ${PENF_LIBS} ${FACE_LIBS})
        TARGET_LINK_LIBRARIES(${LIB} ${PENF_LIB})
ENDFOREACH()

SET_TARGET_PROPERTIES(${LIB} PROPERTIES VERSION ${${LIB}_VERSION} SOVERSION ${${LIB}_SOVERSION})
EXPORT(TARGETS ${LIB} APPEND FILE ${PROJECT_BINARY_DIR}/${LIB}Targets.cmake)
