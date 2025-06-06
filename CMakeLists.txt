cmake_minimum_required(VERSION 3.25)

# ---- vcpkg integration ----
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE AND DEFINED ENV{VCPKG_ROOT})
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
endif()

project(veles LANGUAGES C)

# ── Dependencies ────────────────────────────────────────────────────────────────
find_package(FreeGLUT CONFIG REQUIRED)  # exports FreeGLUT::FreeGLUT
find_package(GLEW CONFIG REQUIRED)      # exports GLEW::GLEW
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

# ── GLSL validation (syntax-only) ───────────────────────────────────────────────
find_program(GLSLANG_VALIDATOR NAMES glslangValidator glslangValidator.exe)

if(GLSLANG_VALIDATOR)
    file(GLOB GLSL_FILES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/glsl/*.glsl")
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/glsl")

    set(GLSL_VALIDATED)
    foreach(GLSL ${GLSL_FILES})
        get_filename_component(NAME "${GLSL}" NAME)
        get_filename_component(EXT  "${GLSL}" LAST_EXT)   # .frag or .vert

        if(EXT STREQUAL ".frag")
            set(STAGE frag)
        else()
            set(STAGE vert)
        endif()

        set(VALIDATED "${CMAKE_BINARY_DIR}/glsl/${NAME}.validated")

        add_custom_command(
            OUTPUT  "${VALIDATED}"
            COMMAND "${GLSLANG_VALIDATOR}" -S ${STAGE} -l -Od "${GLSL}"
            COMMAND ${CMAKE_COMMAND} -E touch "${VALIDATED}"
            DEPENDS "${GLSL}"
            COMMENT "Validating ${NAME} (${STAGE})"
            VERBATIM
        )
        list(APPEND GLSL_VALIDATED "${VALIDATED}")
    endforeach()

    add_custom_target(shaders ALL DEPENDS ${GLSL_VALIDATED})
    add_dependencies(veles shaders)
else()
    message(WARNING "glslangValidator not found – shader validation disabled")
endif()

# ── Output dir ──────────────────────────────────────────────────────────────────
set_target_properties(veles PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}")

# ── Clean helper ────────────────────────────────────────────────────────────────
add_custom_target(clean-all
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${CMAKE_BINARY_DIR}/*"
    COMMAND ${CMAKE_COMMAND} -E rm -f  "${CMAKE_SOURCE_DIR}/veles${CMAKE_EXECUTABLE_SUFFIX}"
    COMMENT "Purging build artifacts"
)
