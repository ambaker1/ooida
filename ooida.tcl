# ooida.tcl
################################################################################
# Implementation of the hunt-fill algorithm by Vamvatsikos and Cornell

# Copyright (C) 2024 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# External package dependencies
package require vutil 4.0

# Define namespace, variables, and exported commands
namespace eval ::ooida {
    variable defaultSettings [dict create {*}{
        -start 1.0
        -huntup {Geometric 2.0}
        -precision {0.25 0.5}
        -limits {0.0 Inf}
    }]
    # Exported commands
    namespace export ida
}

# ida --
#
# TclOO class for Incremental Dynamic Analysis
#
# Syntax:
# ida new $varName <$data> <$settings>
# ida create $name $varName <$data> <$settings>
#
# Arguments:
# varName       Variable name for garbage collection
# data          IDA dictionary (see ::ooida::HuntFill)
# settings      Settings dictionary, default blank. (see ::ooida::HuntFill)

# Methods:
# configure:    Modify/access settings
# add:          Add a point to the IDA
# remove:       Remove a point to the IDA
# next:         Get next intensity measure
# stage:        Get stage of IDA (0-4)
# capacity:     Get lower and upper bounds on capacity

oo::class create ::ooida::ida {
    superclass ::vutil::ValueContainer
    # Class variables
    variable config; # Settings dictionary
    variable myValue; # Variable from superclass, stores value
    variable stage; # IDA stage integer (0-4)
    variable queue; # Ordered list of intensities to run
    variable capacity; # Bounds on capacity
    
    # ida new/create --
    #
    # Create an IDA object
    # 
    # Syntax:
    # ida new $varName <$data> <$settings>
    # ida create $name $varName <$data> <$settings>
    # 
    # Arguments:
    # varName       Variable to store object in for garbage collection.
    # name          Name of IDA object.
    # settings      Dictionary of configuration settings.
    
    constructor {varName {data {}} {settings {}}} {             
        # Define default settings and apply user defined configuration
        set config $::ooida::defaultSettings
        my configure {*}$settings
        # Call the superclass constructor
        next $varName $data
    }
    
    # my SetValue --
    #
    # Modified to process IDA input data and initialize variables
    
    method SetValue {value} {
        # Ensure that value is an IDA dictionary
        set value [::ooida::IDA_Dict $value]
        # Initialize defaults
        set stage -1
        set queue ""
        set capacity {0.0 Inf}
        # Call superclass method
        next $value
    }
    
    # $ida configure --
    #
    # Queries or updates configuration settings.
    # If no arguments, returns entire settings dictionary.
    # If one argument, returns the settings for that option.
    # If an even number of arguments, defines the settings.
    #
    # Syntax:
    # $ida configure
    # $ida configure $option
    # $ida configure $option $value ...
    # 
    # Arguments:
    # option        Settings option
    # value         Value for settings option
    
    method configure {args} {
        # Switch for arity (based on how fconfigure works with Tcl)
        if {[llength $args] == 0} {
            # Query all settings
            return $config
        } elseif {[llength $args] == 1} {
            # Query specific option
            set option [lindex $args 0]
            if {![dict exists $config $option]} {
                return -code error "Unknown option \"$option\""
            }
            return [dict get $config $option]
        } elseif {[llength $args] % 2 == 1} {
            return -code error "wrong # of args: want option-value pairs"
        }
        # Use "HuntFill" to check options
        ::ooida::HuntFill {} $args
        # Merge with settings
        set config [dict merge $config $args]
        # Flag IDA for update
        set stage -1
        # Return object
        return [self]
    }
    
    # $ida set --
    #
    # Add a point to the IDA. Returns object
    #
    # Syntax:
    # $ida set $im $code
    #
    # Arguments:
    # im            Intensity measure
    # code          Collapse code
    
    method set {im code} {
        set im [expr {double($im)}]
        set code [expr {bool($code)}]
        if {$im < 0} {
            return -code error "intensity measure must be >= 0.0"
        }
        # Modify queue if necessary.
        # -------------------------------------------------------------
        if {$im == [lindex $queue 0]} {
            set queue [lrange $queue 1 end]
        }
        # Trigger reset of queue
        # -------------------------------------------------------------
        if {$code || [llength $queue] == 0} {
            set stage -1; # flags IDA for update
        }
        # Save results (appends to data)
        # -------------------------------------------------------------
        dict set myValue $im $code
        return [self]
    }

    # $ida unset --
    #
    # Remove a point in the IDA. 
    # Resets the queue if the point exists.
    # Returns object
    #
    # Syntax:
    # $ida unset $im
    #
    # Arguments:
    # im        Intensity measure
    
    method unset {im} {
        set im [expr {double($im)}]
        if {[dict exists $myValue $im]} {
            dict unset myValue $im
            set stage -1; # flag IDA for update
        }
        return [self]
    }
    
    # $ida next --
    #
    # Updates the IDA and gets the next intensity measure. 
    # Returns blank if IDA is complete
    #
    # Syntax:
    # $ida next
    
    method next {} { 
        # If stage is -1, update IDA
        if {$stage == -1} {
            set results [::ooida::HuntFill $myValue $config]
            set capacity [lassign $results queue stage]
        }
        # Return the first element in the queue
        return [lindex $queue 0]
    }
    
    # $ida stage --
    #
    # Return the current stage of the IDA algorithm
    #
    # Syntax:
    # $ida stage
    
    method stage {} {
        my next; # updates IDA if needed
        return $stage
    }
    
    # $ida capacity --
    #
    # Returns the lower and upper bounds on capacity
    
    method capacity {} {
        my next; # updates IDA if needed
        return $capacity
    }
}; # end class definition

# ooida::HuntFill --
#
# Private procedure that is used to process IDA collapse data and return the
# queue, stage, and bounds for capacity estimation. 
#
# Syntax:
# ooida::HuntFill $data $settings
#
# Arguments:
# data:         Key-value pairing of intensity measure and collapse codes
# settings:     Configurations settings dictionary
#
# Configuration options
# -start $init
# init:         First point. Default 1.0
# -huntup "$type $step"
# type:         Hunt-up type: Linear, Quadratic or Geometric. Default Geometric
# step:         Hunt-up step. Differs for the three types. Default 2.0
# -precision "$eps1 $eps2"
# eps1:         Bracketing precision on intensity measure. Default 0.5
# eps2:         Fill precision on intensity measure. Default 1.0
# -limits "$min $max"
# min:          Lower limit for IDA refining. Default 0.0
# max:          Upper limit for IDA refining. Default Inf

proc ::ooida::HuntFill {data {settings {}}} {
    variable defaultSettings
    # Process IDA data (ensure it is valid IDA dictionary)
    set data [IDA_Dict $data]
    # Merge default and user-defined settings
    dict for {option value} [dict merge $defaultSettings $settings] {
        # Switch for option, with basic config checks
        switch $option {
            -start { # -start defines initial point for IDA
                set init $value
                if {![string is double -strict $init]} {
                    return -code error "initial value must be number"
                } elseif {$init <= 0.0} {
                    return -code error "initial value must be greater than zero"
                }
            }
            -huntup { # -huntup defines initial IDA behavior
                #   Geometric multiplies the last IM by the step.
                #   Quadratic adds the step to the IM gap.
                #   Linear simply steps by the step size.
                # Example: -huntup "Geometric 2.0"
                if {[llength $value] != 2} {
                    return -code error \
                            "wrong # of -huntup args: want \"type step\""
                }
                lassign $value type step
                if {$type ni {Geometric Quadratic Linear}} {
                    return -code error "unknown hunt type, try\
                            \"Linear\", \"Quadratic\", or \"Geometric\""
                }
                if {![string is double -strict $step]} {
                    return -code error "hunt step must be number"
                } elseif {$type eq {Geometric} && $step <= 1.0} {
                    return -code error "\"Geometric\" step must be > 1"
                } elseif {$type eq {Quadratic} && $step <= 0.0} {
                    return -code error "\"Quadratic\" step must be > 0"
                } elseif {$type eq {Linear} && $step <= 0.0} {
                    return -code error "\"Linear\" step must be > 0"
                }
            }
            -precision { # -precision defines the hunt and fill precision.
                # Example: -precision "0.5 1.0"
                if {[llength $value] != 2} {
                    return -code error \
                            "wrong # of -precision args: want \"eps1 eps2\""
                }
                lassign $value eps1 eps2
                if {![string is double -strict $eps1] || $eps1 <= 0.0} {
                    return -code error "bracketing precision must be number > 0"
                }
                if {![string is double -strict $eps2] || $eps2 <= 0.0} {
                    return -code error "fill precision must be number > 0"
                }
            }
            -limits { # -limits defines bounds of refining
                # Example: -limits "0 Inf"
                if {[llength $value] != 2} {
                    return -code error \
                            "wrong # of -limits args: want \"min max\""
                }
                lassign $value min max
                if {$min > $max} {
                    return -code error "min must be <= max"
                }
                if {$min < 0.0} {
                    return -code error "min out of range"
                }
            }
            default {
                return -code error "unknown setting \"$option\""
            }
        }; # end switch
    }
    
    # Get sorted intensity measures and list of collapses
    dict set data 0.0 0; # Prepend with zero point
    set sortedIMs [lsort -real [dict keys $data]]
    set collapses [dict keys [dict filter $data value 1]]
    
    # Determine bounds on capacity, and preliminary IDA stage
    # --------------------------------------------------------------
    if {[llength $collapses] == 0} {
        # Collapse not reached
        set capacity1 [lindex $sortedIMs end]
        set capacity2 Inf
        # Determine preliminary stage
        if {$capacity1 == 0} {
            set stage 0
        } else {
            set stage 1
        }
    } else {
        # Collapse reached
        # Maximum capacity is minimum collapse
        set capacity2 Inf
        foreach im $collapses {
            if {$im < $capacity2} {
                set capacity2 $im
            }
        }
        # Minimum capacity is maximum intensity below minimum collapse 
        set i [lsearch -sorted -exact -real $sortedIMs $capacity2]
        set capacity1 [lindex $sortedIMs $i-1]
        # Determine preliminary stage
        if {($capacity2 - $capacity1) > $eps1} {
            set stage 2
        } else {
            set stage 3
        }
    }
    
    # Modify the stage for partial IDA limits (see Figure 3 in docs)
    # --------------------------------------------------------------
    # Column A: Skip stage 2 if max capacity is <= lower limit.
    if {$stage == 2 && $capacity2 <= $min} {
        set stage 4
    }
    # Column B & C: Skip stage 3 if min capacity <= lower limit.
    if {$stage == 3 && $capacity1 <= $min} {
        set stage 4
    }
    # Columns D & E: No change        
    # Column F: Skip to stage 3 if min capacity is > upper limit 
    # Basically, don't hunt or bracket above the max limit.
    if {$stage in {1 2} && $capacity1 > $max} {
        set stage 3
    }
    
    # Generate the queue based on the stage of the algorithm
    # --------------------------------------------------------------
    set queue ""
    if {$stage == 0} {
        # Stage 0: Initialization
        if {$init < $min} {
            set queue $min
        } elseif {$init > $max} {
            set queue $max
        } else {
            set queue $init
        }
    } elseif {$stage == 1} {
        # Stage 1: Hunt-up
        set im1 [lindex $sortedIMs end-1]
        set im2 [lindex $sortedIMs end]
        switch $type {
            Geometric {
                set queue [expr {double($im2 * $step)}]
            }
            Quadratic {
                set queue [expr {double($im2 + ($im2 - $im1) + $step)}]
            }
            Linear {
                set queue [expr {double($im2 + $step)}]
            }
        }
    } elseif {$stage == 2} {
        # Stage 2: Bracketing
        set queue [expr {($capacity1 + $capacity2)/2.0}]
    } elseif {$stage == 3} {
        # Stage 3: Fill-in
        # Get list of intensity measures to fill
        if {$capacity1 <= $max} {
            # Zone 2
            set i [lsearch -sorted -real -bisect $sortedIMs $capacity1]
            set fillList [lrange $sortedIMs 0 $i]
        } else {
            # Zone 3 ($capacity > $max)
            set i [lsearch -sorted -real -bisect $sortedIMs $max]
            set fillList [lrange $sortedIMs 0 $i+1]
        }
        # Generate queue for fill stage
        set queue [GenerateQueue $fillList $eps2]
    }
    
    # Check for completion criteria
    if {[llength $queue] == 0} {
        set stage 4
    }
    
    # Ensure that results are double-precision floating point
    set queue [lmap value $queue {expr {double($value)}}]
    set capacity1 [expr {double($capacity1)}]
    set capacity2 [expr {double($capacity2)}]
    
    # Return the results
    return [list $queue $stage $capacity1 $capacity2]
}

# IDA_Dict --
#
# Takes dictionary input, returns IDA dict, which is a series of IDA points.

proc ::ooida::IDA_Dict {value} {
    set ida_dict ""
    dict for {im code} $value {
        set im [expr {double($im)}]
        set code [expr {bool($code)}]
        if {$im < 0} {
            return -code error "intensity measure must be >= 0.0"
        }
        dict set ida_dict $im $code
    }
    return $ida_dict
}

# GenerateQueue --
#
# Get priority list of intensity measures to run (by bisection and trisection)
#
# Syntax:
# GenerateQueue $ims $epsilon
#
# Arguments:
# ims           List of intensity measures, in increasing order
# epsilon       Maximum gap size

proc ::ooida::GenerateQueue {ims epsilon} {
    # Initialize gapMap and call recursive function.
    set gapMap ""
    GetGaps $ims $epsilon
    # Return the ims of "map", in order of decreasing gap size
    return [dict keys [lsort -stride 2 -index 1 -real -decreasing $gapMap]]
}

# GetGaps --
# 
# Recursive function called within GenerateQueue to get a list of gaps 
# for the purpose of refining the IDA curve.
# Bisects and calls itself if the gap between consecutive intensities is too 
# large to meet the precision by trisection or bisection.
# "gapMap" is a dictionary of intensities and the gaps they split up.
#
# Syntax:
# GetGaps $ims $epsilon
#
# Arguments:
# ims           List of intensity measures, in increasing order
# epsilon       Maximum gap size

proc ::ooida::GetGaps {ims epsilon} {
    upvar gapMap gapMap
    foreach im2 [lassign $ims im1] {
        set gap [expr {$im2 - $im1}]
        if {$gap > 3*$epsilon} {
            # Bisect and recurse
            set mid [expr {$im1 + $gap/2.0}]
            dict set gapMap $mid $gap
            GetGaps [list $im1 $mid $im2] $epsilon
        } elseif {$gap > 2*$epsilon} {
            # Trisect to meet precision
            dict set gapMap [expr {$im1 + $gap/3.0}] $gap
            dict set gapMap [expr {$im1 + $gap*(2.0/3.0)}] $gap
        } elseif {$gap > $epsilon} {
            # Bisect to meet precision
            dict set gapMap [expr {$im1 + $gap/2.0}] $gap
        }
        set im1 $im2
    }
    return
}

# Finally, provide the package
package provide ooida 0.2
