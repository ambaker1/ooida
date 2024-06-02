# Documentation examples

test {Example 1} {Installing and Importing ``ooida''} -body {
puts {}
package require tin
tin add -auto ooida https://github.com/ambaker1/ooida install.tcl
tin import ooida
puts -nonewline {}
} -output {
}

test {Example 2} {Creating IDA objects} -body {
puts {}
ida new x {1.0 0 2.0 1}; # create new IDA object
$x --> y; # copy IDA object to new variable
unset x; # destroys object stored in x
puts -nonewline {}
} -output {
}

test {Example 3} {Creating and Modifying IDA objects} -body {
puts {}
ida new x; # create new IDA object
$x = {1.0 0 2.0 1}
$x set 1.5 1
$x unset 2.0
puts [$x]
puts -nonewline {}
} -output {
1.0 0 1.5 1
}

test {Example 4} {Example Application} -body {
puts {}
# Define place-holder collapse equation (with structural resurrection)
proc Collapsed {x} {
    expr {$x >= 7.5 || ($x > 3.0 && $x <= 3.5)}
}
# Create IDA object
ida new ida {} {
    -huntup {Geometric 2.0}
    -precision {0.25 0.5}
}
# Run IDA
while {[$ida stage] < 4} {
    set im [$ida next]
    $ida set $im [Collapsed $im]
}
# Print out capacity, and history of analysis
puts [$ida capacity]
puts [dict keys [$ida]]
puts -nonewline {}
} -output {
3.0 3.25
1.0 2.0 4.0 8.0 6.0 7.0 7.5 7.25 3.0 5.0 0.5 1.5 2.5 3.5 3.25
}
