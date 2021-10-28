# this script is to install hwloc, to identify host CPU parameters for gemini3d.run
#
# cmake -P install_hwloc.cmake
# will install hwloc under the user's home directory.

cmake_minimum_required(VERSION 3.20...3.22)

set(CMAKE_TLS_VERIFY true)

set(prefix "~")

set(version 2.6.0rc2)

string(SUBSTRING ${version} 0 3 subver)

set(host https://download.open-mpi.org/release/hwloc/v${subver}/)

if(APPLE)
  find_program(brew
  NAMES brew
  PATHS/opt/homebrew /usr/local
  )

  if(brew)
    execute_process(COMMAND ${brew} install hwloc
      COMMAND_ERROR_IS_FATAL ANY)
    return()
  endif()
endif()

if(WIN32)
  set(arch $ENV{PROCESSOR_ARCHITECTURE})
  if(arch STREQUAL AMD64)
    set(stem hwloc-win64-build-${version})
    set(sha256 cac82da11c5578c4b5255e9eb86766789ba2b672e26ac1f94ae2273ec6dfce3f)
    set(name ${stem}.zip)
  else()
    message(FATAL_ERROR "HWloc binaries provided for x86_64 only. May need to build HWloc from source.")
  endif()
else()
  set(stem hwloc-${version})
  set(sha256 c4926a60eca045cdc3f082c60b1684bcca1327e29c330283c3609d9716db4811)
  set(name ${stem}.tar.bz2)
endif()

set(url ${host}${name})

if(CMAKE_VERSION VERSION_LESS 3.21)
  get_filename_component(prefix ${prefix} ABSOLUTE)
else()
  file(REAL_PATH ${prefix} prefix EXPAND_TILDE)
endif()
set(path ${prefix}/${stem})

message(STATUS "installing hwloc ${version} to ${path}")

set(archive ${path}/${name})

if(NOT EXISTS ${archive})
  message(STATUS "download ${url}")
  file(DOWNLOAD ${url} ${archive}
  INACTIVITY_TIMEOUT 15
  EXPECTED_HASH SHA256=${sha256}
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

find_program(MAKE_COMMAND NAMES make REQUIRED)

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

file(ARCHIVE_EXTRACT INPUT ${archive}
  DESTINATION ${tmpdir})

set(workdir ${tmpdir}/${stem})

message(STATUS "Building HWLOC in ${workdir}")
if(NOT EXISTS ${workdir}/Makefile)
  execute_process(COMMAND ./configure --prefix=${path}
    WORKING_DIRECTORY ${workdir}
    COMMAND_ERROR_IS_FATAL ANY)
endif()
execute_process(COMMAND ${MAKE_COMMAND} -j
  WORKING_DIRECTORY ${workdir}
  COMMAND_ERROR_IS_FATAL ANY)
execute_process(COMMAND ${MAKE_COMMAND} install
  WORKING_DIRECTORY ${workdir}
  COMMAND_ERROR_IS_FATAL ANY)

check_hwloc()
