
set project_name [lindex $argv 0]

set part_name [lindex $argv 1]

create_project -part $part_name $project_name tmp

set_property IP_REPO_PATHS tmp/cores [current_project]

set bd_path tmp/$project_name.srcs/sources_1/bd/system

create_bd_design system

source cfg/ports.tcl

proc cell {cell_vlnv cell_name {cell_props {}} {cell_ports {}}} {
  set cell [create_bd_cell -type ip -vlnv $cell_vlnv $cell_name]
  set prop_list {}
  foreach {prop_name prop_value} $cell_props {
    lappend prop_list CONFIG.$prop_name $prop_value
  }
  if {[llength $prop_list] > 1} {
    set_property -dict $prop_list $cell
  }
  foreach {local_name remote_name} $cell_ports {
    set local_port [get_bd_pins $cell_name/$local_name]
    set remote_port [get_bd_pins $remote_name]
    if {[llength $local_port] == 1 && [llength $remote_port] == 1} {
      connect_bd_net $local_port $remote_port
      continue
    }
    set local_port [get_bd_intf_pins $cell_name/$local_name]
    set remote_port [get_bd_intf_pins $remote_name]
    if {[llength $local_port] == 1 && [llength $remote_port] == 1} {
      connect_bd_intf_net $local_port $remote_port
      continue
    }
    error "** ERROR: can't connect $cell_name/$local_name and $remote_port"
  }
}

source projects/$project_name/block_design.tcl

rename cell {}

generate_target all [get_files $bd_path/system.bd]
make_wrapper -files [get_files $bd_path/system.bd] -top

add_files -norecurse $bd_path/hdl/system_wrapper.v

set files [glob -nocomplain projects/$project_name/*.v]
if {[llength $files] > 0} {
  add_files -norecurse $files
}

set files [glob -nocomplain cfg/*.xdc]
if {[llength $files] > 0} {
  add_files -norecurse -fileset constrs_1 $files
}

set_property STRATEGY Flow_PerfOptimized_High [get_runs synth_1]
set_property STRATEGY Performance_NetDelay_high [get_runs impl_1]

close_project
