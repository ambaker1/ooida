switch $gm {
    1 { # Structural resurrection
        if {$im > 3 && $im < 4} {
            return [list drift Inf]
        } else {
            return [list drift [expr {$im/50.0}]]
        }
    }
    2 { # Linear
        return [list drift [expr {$im/50.0}]]
    }
    3 { # Quadratic
        return [list drift [expr {$im**2/50.0}]]
    }
}