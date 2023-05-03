package require tin 0.4.6
set version 0.1
set config [dict create VERSION $version]
tin bake src/install.tin build/install.tcl $config
tin bake src/pkgIndex.tin build/pkgIndex.tcl $config
tin bake src/ooida.tin build/ooida.tcl $config
tin import assert from flytrap

# Run tests
cd tests
# Series OpenSees
puts "Running tests in OpenSees"
catch {exec OpenSees test.tcl} result options
puts $result
assert [lindex [dict get $options -errorcode] end] == 1
# OpenSeesMPI, n = 1 (series)
puts "Running tests in OpenSeesMPI, n = 1"
catch {exec OpenSeesMPI -n 1 test.tcl 2>NUL} result options
puts $result
assert [lindex [dict get $options -errorcode] end] == 1
# OpenSeesMPI, n = 5 (parallel)
puts "Running tests in OpenSeesMPI, n = 5"
catch {exec OpenSeesMPI -n 5 test.tcl 2>NUL} result options
puts $result
assert [lindex [dict get $options -errorcode] end] == 1
cd ..

# Overwrite files
file copy -force {*}[glob build/*.tcl] [pwd]
tin bake doc/template/version.tin doc/template/version.tex $config
# Run installer
exec tclsh install.tcl
assert [tin installed ooida -exact $version] eq $version
