# This scripts is responsible for getting the input files directly, just change the directory value to search for then.
# THe script auto find filename using wildcard.
# Group them according to the types of files: netlist, sdc, lib, LEF, DEF, GDS, upf (optional)

# read the lef files. 

set root_import_dir "/home/vchip9/work_lab/lab2/tools..."
set lib_dir [string join $root_import_dir "/lib"]

# get all the lef files
set var(...) [exec { find $lib_dir -name "*.lef"}]

string 
