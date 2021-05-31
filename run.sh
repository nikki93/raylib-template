#!/bin/bash

export PROJECT_NAME="raylib-template"

set -e

PLATFORM="macOS"
CMAKE="cmake"
CLANG_FORMAT="clang-format"
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
    CMAKE="cmake.exe"
    CLANG_FORMAT="clang-format.exe"
  fi
fi
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

  # Count lines of code
  cloc)
    cloc src --by-file --exclude_list_file=.cloc_exclude_list
    ;;

  # Desktop
  release)
    case $PLATFORM in
      lin|macOS)
        $CMAKE -H. -Bbuild/release -GNinja
        $CMAKE --build build/release
        if [[ -z "$VALGRIND" ]]; then
          ./build/release/$PROJECT_NAME $2
        else
          SUPPRESSIONS="
          {
            ignore_versioned_system_libs
            Memcheck:Leak
            ...
            obj:*/lib*/lib*.so.*
          }
          {
            ignore_iris_dri
            Memcheck:Addr1
            ...
            obj:*/dri/iris_dri.so
          }
          {
            ignore_iris_dri
            Memcheck:Addr2
            ...
            obj:*/dri/iris_dri.so
          }
          {
            ignore_iris_dri
            Memcheck:Addr4
            ...
            obj:*/dri/iris_dri.so
          }
          {
            ignore_iris_dri
            Memcheck:Addr8
            ...
            obj:*/dri/iris_dri.so
          }
          "
          valgrind \
            --log-file="./build/valgrind.log" \
            --suppressions=<(echo "$SUPPRESSIONS") \
            --gen-suppressions=all \
            --leak-check=full \
            -s \
            ./build/release/$PROJECT_NAME $2
          cat build/valgrind.log
        fi
        ;;
      win)
        $CMAKE -H. -Bbuild/msvc -G"Visual Studio 16"
        $CMAKE --build build/msvc --config Release
        ./build/msvc/Release/$PROJECT_NAME.exe $2
        ;;
    esac
    ;;
  debug)
    case $PLATFORM in
      lin|macOS)
        $CMAKE -DCMAKE_BUILD_TYPE=Debug -H. -Bbuild/debug -GNinja
        $CMAKE --build build/debug
        ./build/debug/$PROJECT_NAME $2
        ;;
      win)
        $CMAKE -H. -Bbuild/msvc -G"Visual Studio 16"
        $CMAKE --build build/msvc --config Debug
        ./build/msvc/Debug/$PROJECT_NAME.exe $2
        ;;
    esac
    ;;
  xcode)
    $CMAKE -DCMAKE_BUILD_TYPE=Debug -H. -Bbuild/xcode -GXcode
    $CMAKE --build build/xcode
    ;;
  lib-release)
    case $PLATFORM in
      lin|macOS)
        $CMAKE -DLIB=ON -H. -Bbuild/lib-release -GNinja
        $CMAKE --build build/lib-release
        ;;
      win)
        $CMAKE -DLIB=ON -H. -Bbuild/lib-msvc -G"Visual Studio 16"
        $CMAKE --build build/lib-msvc --config Release
        ;;
    esac
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
    if [[ ! -d "build/web-release" ]]; then
      $CMAKE -DWEB=ON -H. -Bbuild/web-release -GNinja
    fi
    $CMAKE --build build/web-release
    ;;
  web-debug)
    if [[ ! -d "build/web-debug" ]]; then
      $CMAKE -DCMAKE_BUILD_TYPE=Debug -DWEB=ON -H. -Bbuild/web-debug -GNinja
    fi
    $CMAKE --build build/web-debug
    ;;
  web-watch-release)
    find CMakeLists.txt src assets web -type f | entr $TIME_TOTAL ./run.sh web-release
    ;;
  web-watch-debug)
    find CMakeLists.txt src assets web -type f | entr $TIME_TOTAL ./run.sh web-debug
    ;;
  web-serve-release)
    npx http-server -p 9002 -c-1 build/web-release
    ;;
  web-serve-debug)
    npx http-server -p 9002 -c-1 build/web-debug
    ;;
  #web-publish)
  #  ./run.sh web-release
  #  rm -rf web-publish/*
  #  mkdir -p web-publish
  #  cp build/web-release/{index.*,$PROJECT_NAME.*} web-publish/
  #  ;;
esac
