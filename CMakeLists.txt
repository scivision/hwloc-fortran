cmake_minimum_required(VERSION 3.14...3.21)

file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/VERSION PROJECT_VERSION
  REGEX "^([0-9]+\.[0-9]+\.[0-9]+)" LIMIT_INPUT 16 LENGTH_MAXIMUM 16 LIMIT_COUNT 1)

project(HWLOC-Fortran
  LANGUAGES C Fortran
  HOMEPAGE_URL https://github.com/scivision/hwloc-fortran
  VERSION 1.0.0)

include(CTest)

include(CheckIncludeFile)
include(CheckSymbolExists)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules)

find_package(HWLOC)

if(HWLOC_FOUND)

  # separate C object lib to avoid compiler warnings from C <-> Fortran add_compile_options etc.
  add_library(hwloc_c OBJECT get_cpu_hwloc.c)
  target_include_directories(hwloc_c INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
  target_link_libraries(hwloc_c PRIVATE HWLOC::HWLOC)

  # not OBJECT to avoid link issues
  add_library(hwloc_ifc hwloc_ifc.f90)
  target_link_libraries(hwloc_ifc PRIVATE hwloc_c)
  set_target_properties(hwloc_ifc PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)
  target_include_directories(hwloc_ifc INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/include)

else()
  # Fallback if HWLOC not found

  check_include_file(unistd.h HAVE_UNISTD_H)
  if(HAVE_UNISTD_H)
    check_symbol_exists(_SC_NPROCESSORS_ONLN unistd.h HAVE_GNU_COUNT)
  endif()

  if(HAVE_GNU_COUNT)
    # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/sysconf.3.html
    target_sources(hwloc_c PRIVATE get_cpu_sysconf.c)
  elseif(WIN32)
    target_sources(hwloc_c PRIVATE get_cpu_win.c)
  else()
    # this should be almost never encountered
    message(STATUS "did not find hwloc or sysconf. -np Ncpu option will be needed.")
    target_sources(hwloc_c PRIVATE dummy_cpu.c)
  endif()

endif(HWLOC_FOUND)

if(BUILD_TESTING)
  add_executable(get_cpu_count get_cpu_cli.f90)
  target_link_libraries(get_cpu_count PRIVATE hwloc_ifc)

  add_test(NAME HWLOCcli COMMAND $<TARGET_FILE:get_cpu_count>)
  set_tests_properties(HWLOCcli PROPERTIES TIMEOUT 5)
endif()
