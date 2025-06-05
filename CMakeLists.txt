cmake_minimum_required(VERSION 3.15)
project(veles C)

# Set C standard and optimization flags
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_FLAGS_RELEASE "-O3 -g -Wall -ffunction-sections -fdata-sections -DUNIX -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -DGL_GLEXT_PROTOTYPES -DVT240_NO_BUFFER -DNDEBUG")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_RELEASE}")

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include ${CMAKE_BINARY_DIR})

# Source files
file(GLOB SRC_FILES "${CMAKE_SOURCE_DIR}/src/*.c")
file(GLOB GLSL_FILES "${CMAKE_SOURCE_DIR}/glsl/*.glsl")

# Custom command to compile GLSL shaders to .o using glslangValidator and bin2o
set(GLSL_O_FILES "")
foreach(GLSL ${GLSL_FILES})
    get_filename_component(GLSL_NAME ${GLSL} NAME_WE)
    set(O_FILE "${CMAKE_BINARY_DIR}/${GLSL_NAME}.o")
    add_custom_command(
        OUTPUT ${O_FILE}
        COMMAND glslangValidator ${GLSL}
        COMMAND bin2o -t -l${GLSL_NAME} -i${GLSL} -o${O_FILE}
        DEPENDS ${GLSL}
        COMMENT "Compiling GLSL shader ${GLSL_NAME}.glsl"
    )
    list(APPEND GLSL_O_FILES ${O_FILE})
endforeach()

# Object files for C sources
add_library(veles_objs OBJECT ${SRC_FILES})

# Main executable
add_executable(veles $<TARGET_OBJECTS:veles_objs> ${GLSL_O_FILES})

# Link libraries
target_link_libraries(veles GL glut m)

# Set output directory
set_target_properties(veles PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}
)

# Clean target
add_custom_target(clean-all
    COMMAND ${CMAKE_COMMAND} -E rm -rf ${CMAKE_BINARY_DIR}/*
    COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_SOURCE_DIR}/veles
    COMMENT "Cleaning all build files"
)

# Optional: install target
# install(TARGETS veles DESTINATION bin)
