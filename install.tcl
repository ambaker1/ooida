package require tin 1.0
tin depend mpjobs 0.1
tin depend tda 0.1
set dir [tin mkdir -force ooida 0.1.1]
file copy LICENSE README.md pkgIndex.tcl ooida.tcl $dir
