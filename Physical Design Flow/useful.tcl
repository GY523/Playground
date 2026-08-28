foreach m [get_db insts -if {.base_cell.base_class == block}] {
    puts "NAME : [get_db $m .name]"
    puts "cell : [get_db $m .base_cell.name]"
    puts "location : [get_db $m .location]"
    puts "size : [get_db $m .bbox]" 
    puts "--------"
}

get_db insts -if {.base_cell.base_class == block } -foreach {
puts " $obj(.name) :  $obj(.orient)"
}

get_db insts -if {.base_cell.base_class == block } -foreach {
    puts " $obj(.name) :  $obj(.place_status)"
}