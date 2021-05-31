cmake_minimum_required(VERSION 3.16)
set(PROJECT_NAME $ENV{PROJECT_NAME})

# Make CMake a little quieter...
function(message)
  list(GET ARGV 0 MessageType)
  if(MessageType STREQUAL FATAL_ERROR OR
     MessageType STREQUAL SEND_ERROR OR
     MessageType STREQUAL WARNING OR
     MessageType STREQUAL AUTHOR_WARNING)
    list(REMOVE_AT ARGV 0)
    _message(${MessageType} "${ARGV}")
  endif()
endfunction()


#
# Toolchain
#

if(WEB)
  # Emscripten
  set(CMAKE_TOOLCHAIN_FILE vendor/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake)
elseif(WIN32)
  set(CMAKE_C_COMPILER "C:/Program Files/LLVM/bin/clang.exe")
  set(CMAKE_CXX_COMPILER "C:/Program Files/LLVM/bin/clang++.exe")
elseif(APPLE AND (NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "iOS"))
  # Homebrew LLVM for compatibility with Homebrew 'clang-tidy'
  set(CMAKE_C_COMPILER /usr/local/opt/llvm/bin/clang)
  set(CMAKE_CXX_COMPILER /usr/local/opt/llvm/bin/clang++)
else()
  set(CMAKE_C_COMPILER clang)
  set(CMAKE_CXX_COMPILER clang++)
endif()


#
# Project
#

project(${PROJECT_NAME})
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release) # Release build by default
endif()


#
# Target
#

add_executable(${PROJECT_NAME})

# Sources
target_sources(${PROJECT_NAME} PRIVATE src/all.cc)
target_include_directories(${PROJECT_NAME} PRIVATE src)

# Standard
set_target_properties(${PROJECT_NAME} PROPERTIES CXX_STANDARD 20)

# Warnings
if(NOT MSVC)
  target_compile_options(${PROJECT_NAME} PRIVATE -fcolor-diagnostics -fdiagnostics-absolute-paths
    -pedantic-errors -Wall -Wextra 
    -Wno-pragma-once-outside-header -Wno-pragma-pack -Wno-unused-const-variable
    -Wno-gnu-zero-variadic-macro-arguments -Wno-unused-parameter
    #-Wno-missing-braces  -Wno-nested-anon-types 
    #-Wno-pragma-pack -Wno-gnu-anonymous-struct -Wno-deprecated-copy
    )
  target_link_options(${PROJECT_NAME} PRIVATE -fcolor-diagnostics -fdiagnostics-absolute-paths
    -pedantic-errors -Wall -Wextra)
endif()

# Disable exceptions and rtti
if(WEB)
  target_compile_options(${PROJECT_NAME} PRIVATE -fno-exceptions -fno-rtti)
endif()

# Precompiled header
if(NOT CMAKE_EXPORT_COMPILE_COMMANDS)
  target_precompile_headers(${PROJECT_NAME} PRIVATE src/precomp.h)
endif()

# Web flags
if(WEB)
  target_compile_definitions(${PROJECT_NAME} PRIVATE EMSCRIPTEN_HAS_UNBOUND_TYPE_NAMES=0)
  target_link_options(${PROJECT_NAME} PRIVATE "SHELL:--bind")
  target_link_options(${PROJECT_NAME} PRIVATE "SHELL:-s WASM=1")
  target_link_options(${PROJECT_NAME} PRIVATE "SHELL:-s MAX_WEBGL_VERSION=2")
  target_link_options(${PROJECT_NAME} PRIVATE "SHELL:-s INITIAL_MEMORY=256MB")
  if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    target_compile_options(${PROJECT_NAME} PRIVATE "SHELL:-g4 --source-map-base file://${CMAKE_BINARY_DIR}/ -fsanitize=leak")
    target_link_options(${PROJECT_NAME} PRIVATE "SHELL:-g4 --source-map-base file://${CMAKE_BINARY_DIR}/ -fsanitize=leak")
  else()
    target_compile_options(${PROJECT_NAME} PRIVATE -O0) # Makes build much faster
    target_link_options(${PROJECT_NAME} PRIVATE -O0) # Makes build much faster
    #target_compile_options(${PROJECT_NAME} PRIVATE "SHELL:--profiling") # Makes build slightly slower
    #target_link_options(${PROJECT_NAME} PRIVATE "SHELL:--profiling")
  endif()
  file(GLOB MY_ASSETS CONFIGURE_DEPENDS ${PROJECT_SOURCE_DIR}/assets/*)
  set_target_properties(${PROJECT_NAME} PROPERTIES LINK_DEPENDS "${MY_ASSETS}")
endif()

# Add debug info in desktop release builds
if((NOT WEB) AND (NOT MSVC))
  target_compile_options(${PROJECT_NAME} PRIVATE -g)
  target_link_options(${PROJECT_NAME} PRIVATE -g)
endif()


#
# Dependencies
#

# raylib
if(WEB)
  target_link_options(${PROJECT_NAME} PRIVATE "SHELL:-s USE_GLFW=3")
  set(PLATFORM "Web" CACHE STRING "" FORCE)
else()
  set(OpenGL_GL_PREFERENCE "GLVND" CACHE STRING "" FORCE)
endif()
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
add_subdirectory(vendor/raylib)
target_link_libraries(${PROJECT_NAME} PRIVATE raylib)

# fmt
#add_subdirectory(vendor/fmt EXCLUDE_FROM_ALL)
#target_link_libraries(${PROJECT_NAME} PRIVATE fmt::fmt)

# entt
#target_include_directories(${PROJECT_NAME} PRIVATE vendor/entt/src)

# rapidjson
#target_include_directories(${PROJECT_NAME} PRIVATE vendor/rapidjson/include)


#
# Assets
#

# Bundle 'assets/'
if(WEB)
  target_link_options(${PROJECT_NAME} PRIVATE "SHELL:--preload-file ${PROJECT_SOURCE_DIR}/assets@assets")
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "iOS")
  target_sources(${PROJECT_NAME} PRIVATE "assets")
  set_target_properties(${PROJECT_NAME} PROPERTIES RESOURCE "assets")
endif()

# Static web files
if(WEB)
  configure_file(web/index.html index.html)
endif()
