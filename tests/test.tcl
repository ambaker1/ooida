package require tin 1.0
set dir [file normalize ../build]
source ../build/pkgIndex.tcl
tin import mpjobs
tin import ooida
tin import tda
tin import vutil
tin import assert from tin

# Simple example (in series)
if {[getPID] == 0} {
    set settings ""
    dict set settings -huntup {Geometric 1.0 2.0}
    dict set settings -collapse {code {y > 10}}
    dict set settings -precision {0.01 0.5}
    set idaObj [ida new {*}$settings]
    $idaObj run x {
        list y [expr {$x**2}]
    }
    set idaTable [$idaObj table]
    assert [$idaTable keys] eq {0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.125 3.15625 3.1640625 3.171875 3.1875 3.25 3.5 4.0}
    assert [$idaTable cget y] eq [vop [$idaTable keys] ** 2]
    $idaTable destroy

    set suite [suite new]
    $suite add 1 [ida new {*}$settings]
    $suite add 2 [ida new {*}$settings]
    $suite add 3 [ida new {*}$settings]
    $suite add 4 [ida new {*}$settings]

    $suite run gm im {
        list y [expr {$gm + $im**2}]
    }
}

# Job board example
# Initialize job board
jobBoard -wipe -debug IDA {
    # Create IDA objects
    set settings ""
    dict set settings -huntup {Geometric 0.1 2.0}
    dict set settings -collapse {NSC {drift > 0.10}}
    dict set settings -precision {0.1 0.2}
    set suite [suite new]
    $suite add 1 [ida new {*}$settings]
    $suite add 2 [ida new {*}$settings]
    $suite add 3 [ida new {*}$settings]

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

