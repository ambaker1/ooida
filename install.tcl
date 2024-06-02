package require tin 1.0
tin add -auto vutil https://github.com/ambaker1/vutil install.tcl
tin depend vutil 4.0
set dir [tin mkdir -force ooida 0.2]
file copy LICENSE README.md pkgIndex.tcl ooida.tcl $dir
