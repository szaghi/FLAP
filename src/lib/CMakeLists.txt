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
FOREACH(PENF_LIB ${PENF_LIBS})
        TARGET_LINK_LIBRARIES(${LIB} ${PENF_LIB})
ENDFOREACH()

SET_TARGET_PROPERTIES(${LIB} PROPERTIES VERSION ${${PROJECT_NAME}_VERSION} SOVERSION ${${PROJECT_NAME}_SOVERSION})

