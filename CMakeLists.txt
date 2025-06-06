
cmake_minimum_required(VERSION 3.15)

# ---- vcpkg integration ----
if(DEFINED ENV{VCPKG_ROOT} AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")
endif()


project(veles C)

# vcpkg and OpenGL/GLUT/GLEW integration
find_package(OpenGL REQUIRED)
find_package(GLUT REQUIRED)
find_package(GLEW REQUIRED)
include_directories(${OPENGL_INCLUDE_DIRS} ${GLUT_INCLUDE_DIRS} ${GLEW_INCLUDE_DIRS})
link_libraries(${OPENGL_LIBRARIES} ${GLUT_LIBRARIES} ${GLEW_LIBRARIES})

# Set C standard and optimization flags

set(CMAKE_C_STANDARD 99)
if (MSVC)
    # MSVC flags
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    add_definitions(-DNOMINMAX)
    add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
    add_definitions(-DGL_GLEXT_PROTOTYPES)
    add_definitions(-DVT240_NO_BUFFER)
    add_definitions(-DNDEBUG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W3 /O2 /Zi")
else()
    set(CMAKE_C_FLAGS_RELEASE "-O3 -g -Wall -ffunction-sections -fdata-sections -DUNIX -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -DGL_GLEXT_PROTOTYPES -DVT240_NO_BUFFER -DNDEBUG")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_RELEASE}")
endif()

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include ${CMAKE_BINARY_DIR})

# Source files
file(GLOB SRC_FILES "${CMAKE_SOURCE_DIR}/src/*.c")
file(GLOB GLSL_FILES "${CMAKE_SOURCE_DIR}/glsl/*.glsl")


# -- Validate GLSL shaders using glslangValidator (OpenGL, not SPIR-V) --
find_program(GLSLANG_VALIDATOR
             NAMES glslangValidator glslangValidator.exe)
if(NOT GLSLANG_VALIDATOR)
    message(FATAL_ERROR "glslangValidator not found")
endif()

set(GLSL_VALIDATED)
foreach(GLSL ${GLSL_FILES})
    get_filename_component(GLSL_BASENAME "${GLSL}" NAME)
    set(VALIDATE_FILE "${CMAKE_BINARY_DIR}/glsl/${GLSL_BASENAME}.validated")
    # Use auto-stage detection for .vert, .frag, .vert.glsl, .frag.glsl, etc.
    if(GLSL_BASENAME MATCHES ".*\\.(vert|frag|tesc|tese|geom|comp|mesh|task|rgen|rint|rahit|rchit|rmiss|rcall)(\\.glsl)?$")
        add_custom_command(
            OUTPUT   "${VALIDATE_FILE}"
            COMMAND  "${GLSLANG_VALIDATOR}" -G "${GLSL}" && ${CMAKE_COMMAND} -E touch "${VALIDATE_FILE}"
            DEPENDS  "${GLSL}"
            COMMENT  "Validating GLSL shader ${GLSL_BASENAME} (OpenGL 330, auto-stage)"
            VERBATIM
        )
    else()
        # Fallback: try to guess stage from filename (legacy logic)
        add_custom_command(
            OUTPUT   "${VALIDATE_FILE}"
            COMMAND  "${GLSLANG_VALIDATOR}" -G -S $<IF:$<STREQUAL:${GLSL_BASENAME}[-4:],frag>,frag,vert> -e main "${GLSL}" && ${CMAKE_COMMAND} -E touch "${VALIDATE_FILE}"
            DEPENDS  "${GLSL}"
            COMMENT  "Validating GLSL shader ${GLSL_BASENAME} (OpenGL 330, fallback)"
            VERBATIM
        )
    endif()
    list(APPEND GLSL_VALIDATED "${VALIDATE_FILE}")
endforeach()
add_custom_target(shaders ALL DEPENDS ${GLSL_VALIDATED})

# Object files for C sources
add_library(veles_objs OBJECT ${SRC_FILES})

# Main executable
add_executable(veles $<TARGET_OBJECTS:veles_objs> ${GLSL_O_FILES})



# Link libraries
target_link_libraries(veles PRIVATE ${OPENGL_LIBRARIES} ${GLUT_LIBRARIES} ${GLEW_LIBRARIES})

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
