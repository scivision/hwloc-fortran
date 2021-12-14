// inspired by: https://stackoverflow.com/a/29414957

#include <hwloc.h>
#include <stdio.h>

int cpu_count_c(void){

hwloc_topology_t sTopology;

// best estimate of fast physical CPU core count
int nPhysicalCPU;

// CPU kind efficiency variables
hwloc_bitmap_t cpuset = hwloc_bitmap_alloc();
unsigned nr_infos;
struct hwloc_info_s *infos;
int efficiency;


if (hwloc_topology_init(&sTopology) != 0){
  fprintf(stderr, "hwloc: could not init topology\n");
  return -1;
}
if (hwloc_topology_load(sTopology) != 0){
  fprintf(stderr, "hwloc: could not load topology\n");
  return -1;
}

// see if CPU is heterogeneous (more than one CPU core type, e.g. fast/slow like Apple Silicon)
int Ncpu_kind = hwloc_cpukinds_get_nr(sTopology, 0);
if (Ncpu_kind > 1){
  printf("CPU is heterogeneous: %d kinds of CPU cores detected.\n", Ncpu_kind);

  for (int i = 0; i < Ncpu_kind; i++){
    if(hwloc_cpukinds_get_info(sTopology, i, cpuset, &efficiency, &nr_infos, &infos, 0) != 0){
      fprintf(stderr, "hwloc: could not get CPU kinds info.\n");
      return -1;
    }
    printf("CPU kind %d efficiency score: %d\n", i, efficiency);
  }

  // TODO: use #ifdef and query variable infos with "DarwinCompatible (Darwin / Mac OS X)"
  // to for loop over each CPU core,
  // counting how many match the desired core type (e.g. fast)
  // https://www.open-mpi.org/projects/hwloc/doc/v2.7.0/a00366.php#topoattrs_cpukinds
}

// https://www.open-mpi.org/projects/hwloc/doc/v2.4.0/a00154.php#gacd37bb612667dc437d66bfb175a8dc55
nPhysicalCPU = hwloc_get_nbobjs_by_type(sTopology, HWLOC_OBJ_CORE);
if (nPhysicalCPU < 1) {
  // assume hyperthreading / 2
  nPhysicalCPU = hwloc_get_nbobjs_by_type(sTopology, HWLOC_OBJ_PU) / 2;
  fprintf(stderr, "hwloc: fallback to HWLOC_OBJ_PU count/2: HWLOC_OBJ_CORE count not available\n");
}

hwloc_topology_destroy(sTopology);


return nPhysicalCPU;

}
