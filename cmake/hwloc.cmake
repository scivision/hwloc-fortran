include(ExternalProject)

set(hwloc_external true CACHE BOOL "autobuild HWLOC")

if(NOT hwloc_tag)
  set(hwloc_tag hwloc-2.8.0)
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

list(APPEND hwloc_args --disable-opencl --disable-cuda)

set(HWLOC_INCLUDE_DIRS ${HWLOC_ROOT}/include)


# --- read JSON meta

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json _libj)
string(JSON hwloc_url GET ${_libj} hwloc ${HWLOC_VERSION} url)

set(hwloc_cmake_args
--install-prefix=${HWLOC_ROOT}
-DCMAKE_BUILD_TYPE=Release
-DHWLOC_ENABLE_TESTING:BOOL=off
)

if(WIN32)
  ExternalProject_Add(HWLOC
  GIT_REPOSITORY ${hwloc_url}
  GIT_TAG ${hwloc_tag}
  GIT_SHALLOW true
  SOURCE_SUBDIR contrib/windows-cmake
  CMAKE_ARGS ${hwloc_cmake_args}
  BUILD_BYPRODUCTS ${HWLOC_LIBRARIES}
  INACTIVITY_TIMEOUT 60
  )
else()
  find_program(MAKE_EXECUTABLE
  NAMES gmake make
  NAMES_PER_DIR
  DOC "GNU Make"
  REQUIRED)

  find_package(LibXml2)
  if(NOT LibXml2_FOUND)
    list(APPEND hwloc_args --disable-libxml2)
  endif()

  ExternalProject_Add(HWLOC
  GIT_REPOSITORY ${hwloc_url}
  GIT_TAG ${hwloc_tag}
  GIT_SHALLOW true
  BUILD_BYPRODUCTS ${HWLOC_LIBRARIES}
  CONFIGURE_HANDLED_BY_BUILD ON
  INACTIVITY_TIMEOUT 15
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${HWLOC_ROOT} ${hwloc_args}
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
