# Tests for ooida package, called from ../build.tcl

# Configuration options
################################################################################

test ::ooida::HuntFill.Options.Default {
    # The default settings. Some tests rely on this.
} -body {
    set ::ooida::defaultSettings
} -result {-start 1.0 -huntup {Geometric 2.0} -precision {0.25 0.5} -limits {0.0 Inf}}

test ::ooida::HuntFill.Options.Error.-start.0 {} -body {
    ::ooida::HuntFill {} {-start foo} 
} -returnCodes {1} -result "initial value must be number"

test ::ooida::HuntFill.Options.Error.-start.1  {} -body {
    ::ooida::HuntFill {} {-start 0.0}
} -returnCodes {1} -result "initial value must be greater than zero"

test ::ooida::HuntFill.Options.Error.-huntup.0  {} -body {
    ::ooida::HuntFill {} {-huntup foo} 
} -returnCodes {1} -result "wrong # of -huntup args: want \"type step\""

test ::ooida::HuntFill.Options.Error.-huntup.1  {} -body {
    ::ooida::HuntFill {} {-huntup {foo bar}} 
} -returnCodes {1} -result "unknown hunt type, try \"Linear\", \"Quadratic\", or \"Geometric\""

test ::ooida::HuntFill.Options.Error.-huntup.2  {} -body {
    ::ooida::HuntFill {} {-huntup {Linear bar}} 
} -returnCodes {1} -result "hunt step must be number"

test ::ooida::HuntFill.Options.Error.-huntup.3  {} -body {
    ::ooida::HuntFill {} {-huntup {Geometric 1.0}} 
} -returnCodes {1} -result "\"Geometric\" step must be > 1"

test ::ooida::HuntFill.Options.Error.-huntup.4  {} -body {
    ::ooida::HuntFill {} {-huntup {Quadratic 0.0}} 
} -returnCodes {1} -result "\"Quadratic\" step must be > 0"

test ::ooida::HuntFill.Options.Error.-huntup.5  {} -body {
    ::ooida::HuntFill {} {-huntup {Linear 0.0}} 
} -returnCodes {1} -result "\"Linear\" step must be > 0"

test ::ooida::HuntFill.Options.Error.-precision.0  {} -body {
    ::ooida::HuntFill {} {-precision {foo}} 
} -returnCodes {1} -result "wrong # of -precision args: want \"eps1 eps2\""

test ::ooida::HuntFill.Options.Error.-precision.1a  {} -body {
    ::ooida::HuntFill {} {-precision {foo bar}} 
} -returnCodes {1} -result "bracketing precision must be number > 0"

test ::ooida::HuntFill.Options.Error.-precision.1b  {} -body {
    ::ooida::HuntFill {} {-precision {0 bar}} 
} -returnCodes {1} -result "bracketing precision must be number > 0"

test ::ooida::HuntFill.Options.Error.-precision.2a  {} -body {
    ::ooida::HuntFill {} {-precision {1 bar}} 
} -returnCodes {1} -result "fill precision must be number > 0"

test ::ooida::HuntFill.Options.Error.-precision.2b  {} -body {
    ::ooida::HuntFill {} {-precision {1 0}} 
} -returnCodes {1} -result "fill precision must be number > 0"

test ::ooida::HuntFill.Options.Error.-limits.0 {} -body {
    ::ooida::HuntFill {} {-limits foo} 
} -returnCodes {1} -result "wrong # of -limits args: want \"min max\""

test ::ooida::HuntFill.Options.Error.-limits.1 {} -body {
    ::ooida::HuntFill {} {-limits {2 1}} 
} -returnCodes {1} -result "min must be <= max"

test ::ooida::HuntFill.Options.Error.-limits.2 {} -body {
    ::ooida::HuntFill {} {-limits {-0.1 1}} 
} -returnCodes {1} -result "min out of range"

test ::ooida::HuntFill.Options.Error.unknown {} -body {
    ::ooida::HuntFill {} {-foo bar}
} -returnCodes {1} -result "unknown setting \"-foo\""

# Stage 0: Initialization
################################################################################

test ::ooida::HuntFill.Stage0.Default {
    # Default behavior
} -body {
    ::ooida::HuntFill {}
} -result {1.0 0 0.0 Inf}

test ::ooida::HuntFill.Stage0.Default.ZeroPoint {
    # Default behavior, with zero point added. Doesn't change anything
} -body {
    ::ooida::HuntFill {0.0 0}
} -result {1.0 0 0.0 Inf}

test ::ooida::HuntFill.Stage0.Custom {
    # Start at different init point
} -body {
    ::ooida::HuntFill {} {-start 2.0}
} -result {2.0 0 0.0 Inf}

# Bounds change initialization point

test ::ooida::HuntFill.Stage0.BelowBounds {} -body {
    ::ooida::HuntFill {} {-start 1.0 -limits {2.0 Inf}}
} -result {2.0 0 0.0 Inf}

test ::ooida::HuntFill.Stage0.AboveBounds {} -body {
    ::ooida::HuntFill {} {-start 1.0 -limits {0.0 0.5}}
} -result {0.5 0 0.0 Inf}

# Stage 1: Hunt-Up
################################################################################

# Three algorithms for hunt-up: Linear, Quadratic, and Geometric 

# Geometric Hunt-Up (Default)
# ------------------------------------------------------------------------------

test ::ooida::HuntFill.Stage1.Default.0 {} -body {
    ::ooida::HuntFill {1.0 0}
} -result {2.0 1 1.0 Inf}

test ::ooida::HuntFill.Stage1.Default.1 {} -body {
    ::ooida::HuntFill {1.0 0 2.0 0}
} -result {4.0 1 2.0 Inf}

test ::ooida::HuntFill.Stage1.Geometric.0 {} -body {
    ::ooida::HuntFill {1.0 0} {-huntup {Geometric 2.0}}
} -result {2.0 1 1.0 Inf}

test ::ooida::HuntFill.Stage1.Geometric.1 {} -body {
    ::ooida::HuntFill {1.0 0 2.0 0} {-huntup {Geometric 2}}
} -result {4.0 1 2.0 Inf}

test ::ooida::HuntFill.Stage1.Geometric.2 {} -body {
    ::ooida::HuntFill {1.0 0} {-huntup {Geometric 3}}
} -result {3.0 1 1.0 Inf}

test ::ooida::HuntFill.Stage1.Geometric.3 {} -body {
    ::ooida::HuntFill {1.0 0 2.0 0} {-huntup {Geometric 3}}
} -result {6.0 1 2.0 Inf}

# Quadratic Hunt-Up
# ------------------------------------------------------------------------------

test ::ooida::HuntFill.Stage1.Quadratic.0 {
    # Initialization for Quadratic algorithm
} -body {
    ::ooida::HuntFill {1.0 0} {-huntup {Quadratic 0.5}}
} -result {2.5 1 1.0 Inf}

test ::ooida::HuntFill.Stage1.Quadratic.1 {
    # Initialization for Quadratic algorithm
} -body {
    ::ooida::HuntFill {1.0 0 2.5 0} {-huntup {Quadratic 0.5}}
} -result {4.5 1 2.5 Inf}

test ::ooida::HuntFill.Stage1.Quadratic.2 {
    # Initialization for Quadratic algorithm
} -body {
    ::ooida::HuntFill {1.0 0 2.5 0 4.5 0} {-huntup {Quadratic 10.0}}
} -result {16.5 1 4.5 Inf}

# Linear Hunt-Up
# ------------------------------------------------------------------------------

test ::ooida::HuntFill.Stage1.Linear.0 {} -body {
    ::ooida::HuntFill {1.0 0} {-huntup {Linear 1.0}}
} -result {2.0 1 1.0 Inf}

test ::ooida::HuntFill.Stage1.Linear.1 {} -body {
    ::ooida::HuntFill {1.0 0 2.0 0} {-huntup {Linear 1.0}}
} -result {3.0 1 2.0 Inf}

test ::ooida::HuntFill.Stage1.Linear.2 {} -body {
    ::ooida::HuntFill {1.0 0 2.0 0 3.0 0} {-huntup {Linear 5.0}}
} -result {8.0 1 3.0 Inf}


# Stage 2: Bracketing
################################################################################
# Bracketing between capacity bounds

test ::ooida::HuntFill.Stage2.0 {} -body {
    ::ooida::HuntFill {1.0 0 2.0 0 4.0 1} {-precision {0.1 0.2}}
} -result {3.0 2 2.0 4.0}

test ::ooida::HuntFill.Stage2.1 {} -body {
    ::ooida::HuntFill {1.0 0 2.0 0 3.0 1 4.0 1} {-precision {0.1 0.2}}
} -result {2.5 2 2.0 3.0}

test ::ooida::HuntFill.Stage2.2 {
    # This test has a structural resurrection. Ignore it.
} -body {
    ::ooida::HuntFill {1.0 0 2.0 0 3.0 1 4.0 1 5.0 0 6.0 0 7.0 1} {-precision {0.1 0.2}}
} -result {2.5 2 2.0 3.0}

# Stage 3: Fill-in 
################################################################################

test ::ooida::HuntFill.Stage3.Queue {
    # This shows how it prioritizes the largest gaps first.
} -body {
    ::ooida::HuntFill {1.0 0 2.0 0 4.0 0 5.5 0 5.6 1} {-precision {0.5 0.5}}
} -result {{3.0 4.5 5.0 0.5 1.5 2.5 3.5} 3 5.5 5.6}

test ::ooida::HuntFill.Stage3.Limits {
    # Upper limit forces stage 2 into stage 3
} -body {
    ::ooida::HuntFill {1.0 0 2.0 0 2.5 1} {
        -precision {0.25 0.5}
        -limits {0.0 1.5}
    }
} -result {{0.5 1.5} 3 2.0 2.5}

tin import flytrap

test ::ooida::HuntFill.Stage3.Example1 {
    # This is a little example of how the algorithm reaches stage 3
} -body {
    set stage 0
    set x 1.0
    set data ""
    set settings {
        -huntup {Geometric 2.0}
        -precision {0.25 0.5}
    }
    while {$stage < 3} {
        dict set data $x [expr {$x >= 7.5}]
        lassign [::ooida::HuntFill $data $settings] x stage
    }
    assert [dict keys $data] eq {1.0 2.0 4.0 8.0 6.0 7.0 7.5 7.25}
    ::ooida::HuntFill $data $settings
} -result {{3.0 5.0 0.5 1.5 2.5 3.5 4.5 5.5 6.5} 3 7.25 7.5}

test ::ooida::HuntFill.Stage3.Example2 {
    # Example of a structural collapse, encountered in the fill stage
} -body {
    # Define collapse equation
    proc Collapsed {x} {
        expr {$x >= 7.5 || ($x > 3.0 && $x <= 3.5)}
    }
    set stage 0
    set x 1.0
    set data ""
    set settings {
        -huntup {Geometric 2.0}
        -precision {0.25 0.5}
    }
    while {$stage < 4} {
        while {$stage < 3} {
            dict set data $x [Collapsed $x]
            lassign [::ooida::HuntFill $data $settings] x stage
        }
        # Fill-in stage
        set queue $x
        foreach x $queue {
            dict set data $x [Collapsed $x]
            if {[Collapsed $x]} {
                break
            }
        }
        # Check stage
        lassign [::ooida::HuntFill $data $settings] x stage 
    }
    dict keys $data
} -result {1.0 2.0 4.0 8.0 6.0 7.0 7.5 7.25 3.0 5.0 0.5 1.5 2.5 3.5 3.25}


# Stage 4: Complete
################################################################################

test ::ooida::HuntFill.Stage4.FromPreviousTest {
    # Using the results from test ::ooida::HuntFill.Stage3.Example2
} -body {
    ::ooida::HuntFill $data $settings
} -result {{} 4 3.0 3.25}

test ::ooida::HuntFill.Stage4.Partial.ColumnA {
    # Partial IDA, column A, stage 2
} -body {
    assert [::ooida::HuntFill {1.0 0 2.0 1}] eq {1.5 2 1.0 2.0}
    ::ooida::HuntFill {1.0 0 2.0 1} {-limits {2.0 Inf}}
} -result {{} 4 1.0 2.0}

test ::ooida::HuntFill.Stage4.Partial.ColumnsBC {
    # Partial IDA, column A, stage 3
} -body {
    assert [::ooida::HuntFill {1.0 0 2.0 1 1.5 0 1.75 1}] eq {0.5 3 1.5 1.75}
    ::ooida::HuntFill {1.0 0 2.0 1} {-limits {2.0 Inf}}
} -result {{} 4 1.0 2.0}

test ::ooida::HuntFill.Stage4.Partial.ColumnF.Stage1 {
    # Partial IDA, column F
} -body {
    assert [::ooida::HuntFill {1.0 0 2.0 0}] eq {4.0 1 2.0 Inf}
    ::ooida::HuntFill {1.0 0 2.0 0} {-limits {0.0 1.0}}
} -result {{0.5 1.5} 3 2.0 Inf}

test ::ooida::HuntFill.Stage4.Partial.ColumnF.Stage2 {
    # Partial IDA, column F
} -body {
    assert [::ooida::HuntFill {1.0 0 2.0 1}] eq {1.5 2 1.0 2.0}
    ::ooida::HuntFill {1.0 0 2.0 1} {-limits {0.0 0.75}}
} -result {0.5 3 1.0 2.0}

# IDA Class example
################################################################################
# The IDA class streamlines writing scripts to run IDAs.

test ida.class.example.1 {
    # Example of a structural collapse, encountered in the fill stage
} -body {
    # Define collapse equation
    proc Collapsed {x} {
        expr {$x >= 7.5 || ($x > 3.0 && $x <= 3.5)}
    }
    ida new ida {} {
        -huntup {Geometric 2.0}
        -precision {0.25 0.5}
    }
    while {[$ida stage] < 4} {
        set im [$ida next]
        $ida set $im [Collapsed $im]
    }
    assert [$ida capacity] eq {3.0 3.25}
    assert [$ida stage] == 4
    assert [$ida next] eq {}
    dict keys [$ida]
} -result {1.0 2.0 4.0 8.0 6.0 7.0 7.5 7.25 3.0 5.0 0.5 1.5 2.5 3.5 3.25}

test ida.class.example.2 {
    # Modified from previous (remove a few points)
} -body {
    $ida unset 7.0
    assert [$ida stage] == 4
    $ida unset 3.25
    assert [$ida stage] == 2
    while {[$ida stage] < 4} {
        set im [$ida next]
        $ida set $im [Collapsed $im]
    }
    dict keys [$ida]
} -result {1.0 2.0 4.0 8.0 6.0 7.5 7.25 3.0 5.0 0.5 1.5 2.5 3.5 3.25}

