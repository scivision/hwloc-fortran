# used to build and install HWLOC by itself for general use
cmake_minimum_required(VERSION 3.20...3.22)

project(HWLOC LANGUAGES C)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  message(FATAL_ERROR "specify install directory like --install-prefix=/my/install/path")
endif()

message(STATUS "install HWLOC to ${CMAKE_INSTALL_PREFIX}")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake/Modules)

include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/hwloc.cmake)
