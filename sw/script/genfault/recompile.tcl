vlog -suppress 2583 -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/riscv_lib +incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../ips/riscv/include+incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../ips/riscv/../../rtl/includes -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/ips/riscv/include/riscv_defines.sv;
vlog -suppress 2583 -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/riscv_lib +incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../ips/riscv/include -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/ips/riscv/riscv_tracer.sv;
vlog -suppress 2583 -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/riscv_lib +incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../ips/riscv/include -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/ips/riscv/riscv_load_store_unit.sv; # Force to stop during error
vlog -suppress 2583 -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/riscv_lib +incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../ips/riscv/include -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/ips/riscv/riscv_id_stage.sv; # Force to stop during error

# apb_timer recompile
vlog -suppress 2583 -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/apb_timer_lib -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/ips/apb/apb_timer/apb_timer.sv;
vlog -suppress 2583 -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/apb_gpio_lib -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/ips/apb/apb_gpio/apb_gpio.sv;
# peripheral recompile
vlog -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/pulpino_lib +incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../rtl/includes +define+RISCV -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/rtl/peripherals.sv;
vlog -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/pulpino_lib +incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../rtl/includes +define+RISCV -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/rtl/includes/apb_bus.sv;
vlog -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/pulpino_lib +incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../rtl/includes +define+RISCV -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/rtl/periph_bus_wrap.sv;

vlog -quiet -sv -work /home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/modelsim_libs/pulpino_lib +incdir+/home/m105/m105061614/NTHU/Research/Git/pulpino/vsim/../rtl/includes +define+RISCV -L mtiAvm -L mtiRnm -L mtiOvm -L mtiUvm -L mtiUPF -L infact /home/m105/m105061614/NTHU/Research/Git/pulpino/rtl/pulpino_top.sv;

source tcl_files/run.tcl;
run -all;
