if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded ooida 0.1.1 [list source [file join $dir ooida.tcl]]
