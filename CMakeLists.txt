cmake_minimum_required(VERSION 3.19...3.22)

file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/VERSION PROJECT_VERSION
  REGEX "^([0-9]+\.[0-9]+\.[0-9]+)" LIMIT_INPUT 16 LENGTH_MAXIMUM 16 LIMIT_COUNT 1)

project(HWLOC-Fortran
LANGUAGES C Fortran
HOMEPAGE_URL https://github.com/scivision/hwloc-fortran
VERSION ${PROJECT_VERSION}
)

include(CTest)

set(CMAKE_TLS_VERIFY true)
set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED true)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR} CACHE PATH "install dir" FORCE)
endif()

# separate C object lib to avoid compiler warnings from C <-> Fortran add_compile_options etc.
add_library(hwloc_c OBJECT get_cpu_hwloc.c)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/get_cpu_hwloc.h TYPE INCLUDE)
install(TARGETS hwloc_c EXPORT ${PROJECT_NAME}Targets)

# not OBJECT to avoid link issues
add_library(hwloc_ifc hwloc_ifc.f90)
target_link_libraries(hwloc_ifc PRIVATE hwloc_c)
set_target_properties(hwloc_ifc PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)
target_include_directories(hwloc_ifc INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
  $<INSTALL_INTERFACE:include>)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/hwloc_ifc.mod TYPE INCLUDE)
install(TARGETS hwloc_ifc EXPORT ${PROJECT_NAME}Targets)

if(NOT hwloc_external)
  find_package(HWLOC)
endif()

if(NOT HWLOC_FOUND)
  include(cmake/hwloc.cmake)
endif()

target_link_libraries(hwloc_c PRIVATE HWLOC::HWLOC)
# separate C object lib to avoid compiler warnings from C <-> Fortran add_compile_options etc.
target_include_directories(hwloc_c INTERFACE
$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
$<INSTALL_INTERFACE:include>
)


if(BUILD_TESTING)
  add_executable(get_cpu_count get_cpu_cli.f90)
  target_link_libraries(get_cpu_count PRIVATE hwloc_ifc)

  add_test(NAME HWLOCcli COMMAND $<TARGET_FILE:get_cpu_count>)
  set_tests_properties(HWLOCcli PROPERTIES TIMEOUT 5)
endif()

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules/FindHWLOC.cmake
  DESTINATION lib/cmake/Modules)


include(cmake/install.cmake)
