#!/bin/bash

export PROJECT_NAME="raylib-template"

set -e

PLATFORM="macOS"
EXE=""
TIME="time"
TIME_TOTAL="time"

if [[ -f /proc/version ]]; then
  if grep -q Linux /proc/version; then
    PLATFORM="lin"
    TIME="time --format=%es\n"
    TIME_TOTAL="time --format=total\t%es\n"
  fi
  if grep -q Microsoft /proc/version; then
    PLATFORM="win"
    EXE=".exe"
  fi
fi
CMAKE="cmake$EXE"
CLANG_FORMAT="clang-format$EXE"
CMAKE="$TIME $CMAKE"

case "$1" in
  # Compile commands DB (used by editor plugins)
  db)
    $CMAKE -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug -H. -Bbuild/db -GNinja
    cp ./build/db/compile_commands.json .
    ;;

  # Format
  format)
    $CLANG_FORMAT -i -style=file $(find src/ -type f)
    ;;

  # Desktop
  release)
    $CMAKE -H. -Bbuild/release -GNinja
    $CMAKE --build build/release
    ./build/release/$PROJECT_NAME$EXE $2
    ;;
  debug)
    $CMAKE -H. -DCMAKE_BUILD_TYPE=Debug -Bbuild/debug -GNinja
    $CMAKE --build build/debug
    ./build/debug/$PROJECT_NAME$EXE $2
    ;;
  xcode)
    $CMAKE -DCMAKE_BUILD_TYPE=Debug -H. -Bbuild/xcode -GXcode
    $CMAKE --build build/xcode
    ;;

  # Web
  web-init)
    case $PLATFORM in
      lin|macOS)
        cd vendor/emsdk
        ./emsdk install latest
        ./emsdk activate latest
        ;;
      win)
        cd vendor/emsdk
        cmd.exe /c emsdk install latest
        cmd.exe /c emsdk activate latest
        ;;
    esac
    ;;
  web-release)
    if [[ ! -f "vendor/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" ]]; then
      ./run.sh web-init
    fi
    if [[ ! -d "build/web-release" ]]; then
      $CMAKE -DWEB=ON -H. -Bbuild/web-release -GNinja
    fi
    $CMAKE --build build/web-release
    ;;
  web-watch-release)
    find CMakeLists.txt src assets web -type f | entr $TIME_TOTAL ./run.sh web-release
    ;;
  web-serve-release)
    npx http-server -p 9002 -c-1 build/web-release
    ;;
esac
