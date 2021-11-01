# this script is to install hwloc, to identify host CPU parameters for gemini3d.run
#
# cmake -P install_hwloc.cmake
# will install hwloc under the user's home directory.

cmake_minimum_required(VERSION 3.20...3.22)

set(CMAKE_TLS_VERIFY true)

set(prefix "~")

if(NOT HWLOC_VERSION)
  set(HWLOC_VERSION 2.6.0)
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/Modules)

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json _libj)
set(key "source")
if(WIN32)
  set(key ${CMAKE_HOST_SYSTEM_NAME})
endif()
string(JSON hwloc_url GET ${_libj} hwloc ${HWLOC_VERSION} ${key} url)
string(JSON hwloc_sha256 GET ${_libj} hwloc ${HWLOC_VERSION} ${key} sha256)

if(WIN32)
  set(arch $ENV{PROCESSOR_ARCHITECTURE})
  if(NOT arch STREQUAL AMD64)
    message(FATAL_ERROR "HWloc binaries provided for x86_64 only. May need to build HWloc from source.")
  endif()
endif()

cmake_path(GET hwloc_url FILENAME name)

if(CMAKE_VERSION VERSION_LESS 3.21)
  get_filename_component(prefix ${prefix} ABSOLUTE)
else()
  file(REAL_PATH ${prefix} prefix EXPAND_TILDE)
endif()

cmake_path(GET hwloc_url STEM LAST_ONLY stem)
cmake_path(APPEND prefix ${stem} OUTPUT_VARIABLE path)

message(STATUS "Installing hwloc ${HWLOC_VERSION} to ${path}")

cmake_path(APPEND path ${name} OUTPUT_VARIABLE archive)

if(NOT EXISTS ${archive})
  message(STATUS "download ${hwloc_url}")
  file(DOWNLOAD ${hwloc_url} ${archive}
  INACTIVITY_TIMEOUT 15
  EXPECTED_HASH SHA256=${hwloc_sha256}
  )
endif()


function(check_hwloc)

find_program(lstopo
NAMES lstopo
PATHS ${path}
PATH_SUFFIXES bin
NO_DEFAULT_PATH
REQUIRED
)

cmake_path(GET lstopo PARENT_PATH pathbin)
message(STATUS "add to environment variable PATH ${pathbin}")
message(STATUS "add environment variable HWLOC_ROOT ${path}")

endfunction(check_hwloc)


if(WIN32)
  message(STATUS "${archive} => ${path}")
  file(ARCHIVE_EXTRACT
  INPUT ${archive}
  DESTINATION ${prefix}
  )

  check_hwloc()
  return()
endif()

# --- Non-Windows only

find_package(Autotools REQUIRED)

# find tempdir, as cannot extract and install to same directory
# https://systemd.io/TEMPORARY_DIRECTORIES/
if(DEFINED ENV{TMPDIR})
  set(tmpdir $ENV{TMPDIR})
elseif(IS_DIRECTORY /var/tmp)
  set(tmpdir /var/tmp)
elseif(IS_DIRECTORY /tmp)
  set(tmpdir /tmp)
else()
  set(tmpdir ${prefix}/build)
endif()

file(ARCHIVE_EXTRACT
INPUT ${archive}
DESTINATION ${tmpdir}
)

set(workdir ${tmpdir}/${stem})

message(STATUS "Building HWLOC in ${workdir}")
if(NOT EXISTS ${workdir}/Makefile)
  execute_process(COMMAND ./configure --prefix=${path}
  WORKING_DIRECTORY ${workdir}
  COMMAND_ERROR_IS_FATAL ANY
  )
endif()
execute_process(COMMAND ${MAKE_EXECUTABLE} -j
WORKING_DIRECTORY ${workdir}
COMMAND_ERROR_IS_FATAL ANY
)
execute_process(COMMAND ${MAKE_EXECUTABLE} install
WORKING_DIRECTORY ${workdir}
COMMAND_ERROR_IS_FATAL ANY
)

check_hwloc()
