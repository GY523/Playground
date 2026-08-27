string compare "Golden" "Light"

string index "timing" 4

string length "gold"

string range "animal" 1 4

string tolower "LIGHTNING"

string toupper "lightning"

string trimright "s" "newbies   "

string trimleft "./" "./tcl/is/interesting"

string trim ":" ":::Physical Design:::"

# string match pattern string
set a [string match "*@*.com" "test@gmail.com"]
if { $a } {
    puts "match found"
}

# append is a way to concatenate string, but it add to an existing value, not return a value.
puts [append "a for " "apple"]
set str "a for" 
append str " apple"
puts $str

# when storing to an address, no need dereference. Dereference only when read value.
