cmake_minimum_required(VERSION 3.25)

# ---- vcpkg integration ----
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE AND DEFINED ENV{VCPKG_ROOT})
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
endif()

project(veles LANGUAGES C)

# ── Dependencies ────────────────────────────────────────────────────────────────
find_package(FreeGLUT CONFIG REQUIRED)
find_package(GLEW CONFIG REQUIRED)
find_package(OpenGL REQUIRED)

# ── Sources ─────────────────────────────────────────────────────────────────────
file(GLOB SRC_FILES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/*.c")
add_executable(veles ${SRC_FILES})

target_include_directories(veles PRIVATE "${CMAKE_SOURCE_DIR}/include")

# ── Compile flags / defs ────────────────────────────────────────────────────────
target_compile_features(veles PRIVATE c_std_99)

if(MSVC)
    target_compile_definitions(veles PRIVATE
        _CRT_SECURE_NO_WARNINGS NOMINMAX _CRT_NONSTDC_NO_DEPRECATE
        GL_GLEXT_PROTOTYPES VT240_NO_BUFFER NDEBUG
    )
    target_compile_options(veles PRIVATE /W3)
    # Only add optimization in Release builds to avoid conflict with /RTC1 in Debug
    target_compile_options(veles PRIVATE $<$<CONFIG:Release>:/O2> $<$<CONFIG:Debug>:/Od>)
    target_compile_options(veles PRIVATE /Zi)
else()
    target_compile_definitions(veles PRIVATE
        UNIX _XOPEN_SOURCE=600 _DEFAULT_SOURCE GL_GLEXT_PROTOTYPES
        VT240_NO_BUFFER NDEBUG
    )
    target_compile_options(veles PRIVATE -O3 -g -Wall -ffunction-sections -fdata-sections)
endif()

# ── Linking ─────────────────────────────────────────────────────────────────────
target_link_libraries(veles PRIVATE
    $<IF:$<TARGET_EXISTS:FreeGLUT::freeglut>,FreeGLUT::freeglut,FreeGLUT::freeglut_static>
    GLEW::GLEW
    OpenGL::GL
)

# ── GLSL embedding ─────────────────────────────────────────────────────────────
file(GLOB GLSL_FILES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/glsl/*.glsl")

set(GLSL_C_FILES)
foreach(GLSL ${GLSL_FILES})
    get_filename_component(BASENAME "${GLSL}" NAME)     # main.vert.glsl -> main.vert.glsl
    string(REPLACE ".glsl" "" SYMBOL_NAME "${BASENAME}") # main.vert.glsl -> main.vert
    string(REPLACE "." "_" SYMBOL_NAME "${SYMBOL_NAME}")   # main.vert -> main_vert
    set(C_FILE "${CMAKE_BINARY_DIR}/glsl_${SYMBOL_NAME}.c") # Use glsl_ prefix to avoid conflicts
    add_custom_command(
        OUTPUT "${C_FILE}"
        COMMAND ${CMAKE_COMMAND}
                -DINPUT_FILE=${GLSL}
                -DOUTPUT_FILE=${C_FILE}
                -DSYMBOL_NAME=${SYMBOL_NAME}
                -P "${CMAKE_SOURCE_DIR}/cmake/embed_file.cmake"
        DEPENDS "${GLSL}"
        COMMENT "Embedding ${BASENAME} as ${SYMBOL_NAME}"
        VERBATIM
    )

    list(APPEND GLSL_C_FILES "${C_FILE}")
endforeach()

# Add GLSL C files to the executable
target_sources(veles PRIVATE ${GLSL_C_FILES})

# ── Output dir ──────────────────────────────────────────────────────────────────
# For single-config generators (Unix Makefiles, Ninja)
set_target_properties(veles PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}")
# For multi-config generators (Visual Studio, Xcode)
if(CMAKE_CONFIGURATION_TYPES)
    foreach(CONFIG ${CMAKE_CONFIGURATION_TYPES})
        string(TOUPPER ${CONFIG} CONFIG_UPPER)
        set_target_properties(veles PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${CONFIG_UPPER} "${CMAKE_SOURCE_DIR}")
    endforeach()
endif()

# ── Clean helper ────────────────────────────────────────────────────────────────
add_custom_target(clean-all
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${CMAKE_BINARY_DIR}/*"
    COMMAND ${CMAKE_COMMAND} -E rm -f  "${CMAKE_SOURCE_DIR}/veles${CMAKE_EXECUTABLE_SUFFIX}"
    COMMENT "Purging build artifacts"
)
