quit -sim
.main clear

vlog apb_interface.sv
vlog apb_agent.sv  
vlog slave.sv
vlog tb_apb.sv

vopt +acc tb_apb -o test

vsim test

add wave -r *

vlog *.sv +cover=bcesft
vsim -coverage tb_apb -do "run -all; coverage save apb_coverage.ucdb; coverage report -detail"

run 1500ns