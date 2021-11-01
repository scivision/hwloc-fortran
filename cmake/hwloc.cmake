include(ExternalProject)

set(hwloc_external true CACHE BOOL "autobuild HWLOC")

if(NOT HWLOC_VERSION)
  set(HWLOC_VERSION 2.6.0)
endif()

# need to be sure _ROOT isn't empty, DEFINED is not enough
if(NOT HWLOC_ROOT)
  set(HWLOC_ROOT ${CMAKE_INSTALL_PREFIX})
endif()

if(BUILD_SHARED_LIBS)
  set(HWLOC_LIBRARIES ${HWLOC_ROOT}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}hwloc${CMAKE_SHARED_LIBRARY_SUFFIX})
  set(hwloc_args --disable-static --enable-shared)
else()
  set(HWLOC_LIBRARIES ${HWLOC_ROOT}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}hwloc${CMAKE_STATIC_LIBRARY_SUFFIX})
  set(hwloc_args --disable-shared --enable-static)
endif()
set(HWLOC_INCLUDE_DIRS ${HWLOC_ROOT}/include)


# --- read JSON meta

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json _libj)
if(WIN32)
  set(key windows)
else()
  set(key source)
endif()
string(JSON hwloc_url GET ${_libj} hwloc ${HWLOC_VERSION} ${key} url)
string(JSON hwloc_sha256 GET ${_libj} hwloc ${HWLOC_VERSION} ${key} sha256)

if(WIN32)
  ExternalProject_Add(HWLOC
  URL ${hwloc_url}
  URL_HASH SHA256=${hwloc_sha256}
  BUILD_BYPRODUCTS ${HWLOC_LIBRARIES}
  INACTIVITY_TIMEOUT 15
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_BINARY_DIR}/HWLOC-prefix/src/HWLOC/ ${PROJECT_BINARY_DIR}/
  TEST_COMMAND ""
  )
else()
  find_package(Autotools REQUIRED)

  find_package(LibXml2)
  if(NOT LibXml2_FOUND)
    list(APPEND hwloc_args --disable-libxml2)
  endif()

  ExternalProject_Add(HWLOC
  URL ${hwloc_url}
  URL_HASH SHA256=${hwloc_sha256}
  BUILD_BYPRODUCTS ${HWLOC_LIBRARIES}
  CONFIGURE_HANDLED_BY_BUILD ON
  INACTIVITY_TIMEOUT 15
  CONFIGURE_COMMAND ${PROJECT_BINARY_DIR}/HWLOC-prefix/src/HWLOC/configure --prefix=${HWLOC_ROOT} ${hwloc_args}
  BUILD_COMMAND ${MAKE_EXECUTABLE} -j
  INSTALL_COMMAND ${MAKE_EXECUTABLE} install
  TEST_COMMAND ""
  )
endif()

file(MAKE_DIRECTORY ${HWLOC_INCLUDE_DIRS})
# avoid race condition

# this GLOBAL is required to be visible via other project's FetchContent
add_library(HWLOC::HWLOC INTERFACE IMPORTED GLOBAL)
target_include_directories(HWLOC::HWLOC INTERFACE "${HWLOC_INCLUDE_DIRS}")
target_link_libraries(HWLOC::HWLOC INTERFACE "${HWLOC_LIBRARIES}")
if(APPLE)
  target_link_libraries(HWLOC::HWLOC INTERFACE "-framework Foundation" "-framework IOKit" "-framework OpenCL")
endif()
if(LibXml2_FOUND)
  target_link_libraries(HWLOC::HWLOC INTERFACE LibXml2::LibXml2)
endif()

add_dependencies(HWLOC::HWLOC HWLOC)