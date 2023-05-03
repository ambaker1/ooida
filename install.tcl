package require tin 0.4.6
tin depend mpjobs 0.1
tin depend tda 0.1
set dir [tin mkdir -force ooida 0.1]
file copy LICENSE README.md pkgIndex.tcl ooida.tcl $dir
