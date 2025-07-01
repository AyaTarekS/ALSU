vlib work
vlog -f src_files.list
vsim -voptargs=+acc work.topmodule -classdebug -uvmcontrol=all
add wave /topmodule/alsuif/*
run -all