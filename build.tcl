package require tin 1.0
tin import assert from tin
tin import tcltest
set version 0.2
set config [dict create VERSION $version VUTIL_VERSION 4.0]

puts "Building from source files..."
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config
tin import assert from tin
source tests/build_examples.tcl

puts "Loading package from build folder..."
source build/ooida.tcl 
namespace import ooida::*

puts "Running tests"
source tests/ooida_tests.tcl
source tests/doc_examples.tcl

# Check number of failed tests
set nFailed $::tcltest::numTests(Failed)

# Clean up and report on tests
cleanupTests

# If tests failed, return error
if {$nFailed > 0} {
    error "$nFailed tests failed"
}

puts "Tests passed, installing..."
# Tests passed, copy build files to main folder and install
file copy -force {*}[glob -directory build *] [pwd]
exec tclsh install.tcl

# Verify installation
puts "Verifying installation..."
tin forget ooida
tin clear
tin import ooida -exact $version

# Build documentation
puts "Building documentation..."
cd doc
exec -ignorestderr pdflatex ooida.tex
cd ..
