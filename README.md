# HWLOC Fortran

Simple Fortran binding for
[HWLOC](https://www.open-mpi.org/projects/hwloc/)
to get CPU count, with fallback to alternative methods.

Provides Fortran module `hwloc_ifc` with `integer(int32)` function get_cpu_count().

Normally this project is used via CMake FetchContent or ExternalProject in your own Fortran project to obtain an accurate CPU count.
This can be useful for managing MPI runs or estimating memory requirements.
