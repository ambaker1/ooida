# Object-Oriented Incremental Dynamic Analysis (ooida)
The package "ooida" provides an Object-Oriented framework for running Incremental Dynamic Analyses (IDAs) in parallel in OpenSees.

Full documentation [here](https://raw.githubusercontent.com/ambaker1/ooida/main/doc/ooida.pdf).

## Installation
This package is a Tin package. Tin makes installing Tcl packages easy, and is available [here](https://github.com/ambaker1/Tin).
After installing Tin, simply include the following in your script to install ooida:
```tcl
package require tin 0.4.6
tin add -auto ooida https://github.com/ambaker1/ooida install.tcl
tin install ooida
```


