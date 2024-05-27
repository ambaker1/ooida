package require tin 1.0
set dir [file normalize ../build]
source ../build/pkgIndex.tcl
tin import mpjobs
tin import ooida
tin import ndlist
tin import vutil
tin import assert from tin

# Simple example (in series)
if {[getPID] == 0} {
    set settings ""
    dict set settings -huntup {Geometric 1.0 2.0}
    dict set settings -collapse {code {y > 10}}
    dict set settings -precision {0.01 0.5}
    ida new idaObj {*}$settings
    $idaObj run x {
        list y [expr {$x**2}]
    }
    table new idaTable [$idaObj table]
    assert [$idaTable keys] eq {0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.125 3.15625 3.1640625 3.171875 3.1875 3.25 3.5 4.0}
    narray new 1 x [$idaTable keys]
    assert [$idaTable cget y] eq [nexpr {$@x ** 2}]
    $idaTable destroy

    suite new suite
    foreach gm {1 2 3 4} {
        $suite add $gm [ida new ida($gm) {*}$settings]
    }
    $suite run gm im {
        list y [expr {$gm + $im**2}]
    }
}

# Job board example
# Initialize job board
jobBoard -wipe -debug IDA {
    # Create IDA objects
    set config(-huntup) {Geometric 0.1 2.0}
    set config(-collapse) {NSC {drift > 0.10}}
    set config(-precision) {0.1 0.2}
    suite new suite
    narray new 1 gm {1 2 3}
    neval {$suite add $@gm [ida new ida($@gm) {*}[array get config]]}

    # Main loop
    $suite run gm im {
        puts [list $gm $im]
        makeJob IDA_Example.tcl gm $gm im $im
    }
    # Check that capacities and minCollapses are to be expected.
    assert [expr {3 - [$suite ida 1 capacity]}] <= 0.1
    assert [$suite ida 1 minCollapse] >= 3
    assert [expr {5 - [$suite ida 2 capacity]}] <= 0.1
    assert [$suite ida 2 minCollapse] >= 5
    assert [expr {sqrt(5) - [$suite ida 3 capacity]}] <= 0.1
    assert [$suite ida 3 minCollapse] >= [expr {sqrt(5)}]
    puts [$suite ida 1 curve drift]
}

exit 1

