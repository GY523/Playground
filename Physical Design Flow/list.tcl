set lst1 "mango banana"
set lst2 "0,1"
set lst2 [split $lst2 ","]
puts $lst2
foreach a $lst1 b $lst2 {
    puts "$b: $a"
}

set lst1 [concat $lst1 "durian" "lemon"]
puts $lst1

lappend lst1 "coconut"
puts "append coconut: $lst1"

set lst1 [linsert $lst1 0 "apple"]
puts "insert apple: $lst1"

set lst2 [linsert $lst2 2 "3 4"]
puts $lst2

lset lst2 1

set lst2 [lreplace $lst2 1 4 2 3 4 5 ]
puts $lst2

set lst2 [lreplace $lst2 1 4 2]
puts $lst2
