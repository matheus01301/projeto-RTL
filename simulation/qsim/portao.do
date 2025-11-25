onerror {quit -f}
vlib work
vlog -work work portao.vo
vlog -work work portao.vt
vsim -novopt -c -t 1ps -L cycloneii_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.portao_vlg_vec_tst
vcd file -direction portao.msim.vcd
vcd add -internal portao_vlg_vec_tst/*
vcd add -internal portao_vlg_vec_tst/i1/*
add wave /*
run -all
