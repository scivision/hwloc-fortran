program cpu_count

use hwloc_ifc, only : get_cpu_count

print *, "Number of CPUs: ", get_cpu_count()

end program
