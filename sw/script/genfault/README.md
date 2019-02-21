# Fault Generation/Simulation of PULPino platform

## Fault simulation on PULPino
- Copy all of file in this folder to pulpino/sw/build
   - $ cp * DIR/pulpino/sw/build

## Manual to modify script for fault injection
- Modify **./genFaultList.py** 
   - SW                      
      - Set the target simulation program= 'gcd'
   - fault_inject_component
      - 0: data register
      - 1: program counter
      - 2: if stage instr rdata

   - read_rtl_fault_list
      - 0: gen_one_fault_list()
      - 1: gen_fix_datareg_sequential_bitpos_fault_list()
      - 2: read_iss_fault_location_list()

- Modify **fault_config.data**
   - 1st row
      - 0: fault-free simulation
      - 1: fault simulation
   - 2nd row
      - One bit signal: core_region_i.CORE.RISCV_CORE.regfile_waddr_fw_wb_o
         - For decision of injection on **core_region_i.CORE.RISCV_CORE.regfile_wdata** or **core_region_i.CORE.RISCV_CORE.id_stage_i.registers_i.mem[i]**
   - 3rd row
      - Not use now!
   - 4th row
      - Begin of cycle injection
   - 5th row
      - End of cycle injection
   - 6th row
      - Not use now!

## Fault simulation steps on PULPino and dump the necessary trace for ISS fault simulator

```
Operation Platform: PULPino and Modelsim.   

First Time to Compile RISCV BIN and Turn on ModelSim. 
Check the Correctness of Program Simulation.         
Can not get the sych Program Trace Due to Different  
RISCV Bin Ld(Different Start Address)                 
```

- Suppose the necessary file is copied to DIR/pulpino/sw/build
- Modify the program linker script **DIR/pulpino/sw/ref/link.common.ld** with original 
   -  **original    => instrram    : ORIGIN = 0x000000000, LENGTH = 0x8000**
   -  gcd         => instrram    : ORIGIN = 0x0000114e4, LENGTH = 0x8000 
   -  adaline     => instrram    : ORIGIN = 0x000010680, LENGTH = 0x8000 
   -  qsort_small => instrram    : ORIGIN = 0x000011688, LENGTH = 0x8000 

- Restore the RISCV bin
   - $ cd DIR/pulpino/sw/app/gcd # Example
   - $ vim gcd.c # use :w store txt file to ensure recompilation 

- Set the **DIR/pulpino/ips/riscv/riscv_defines.sv** to **original**, revising the **parameter EXC_OFF_RST, parameter EXC_OFF_ILLINSN, parameter EXC_OFF_ECALL, parameter EXC_OFF_LSUERR** 
   - **original:    80   , 84   , 88   , 8c**      
   - gcd:         114e4, 114e8, 114ec, 114f0  
   - adaline:     10680, 10684, 10688, 1068c  
   - qsort_small: 11688, 1168c, 11690, 10694  
  
- Set the **DIR/pulpino/ips/riscv/riscv_tracer.sv** for target program from function **function void printInstrTrace()**
   - **pc+70884 (gcd         offset: 0x114e4)**
   - pc+71120 (gcd+hwacc   offset: 0x115d0)
   - pc+67200 (adaline     offset: 0x10630)
   - pc+71304 (qsort_small offset: 0x11688)

- Run time PULpino program RTL simulation first time. Pure RISCV bin program simulation (But result of simulation start address can't sync up with ISS program simulation)
   - $ cd DIR/pulpino/sw/build
   - $ make gcd.vsim (Take gcd for example)
   - On the Modelsim GUI
      - $ source ../../recompile.tcl # for check the correctness of program execution

```
Operation Platform: PULPino and Modelsim             
                                                      
Fault-Free and Fault Simulation Once Respectively    
To Generate the program trace for ISS Timing Model   
generation                                           
```

- Suppose the Modelsim is opened!! Now, enter the second fault-free simulation for sych up the simulation result with ISS

- Set the **DIR/pulpino/ips/riscv/riscv_defines.sv** to **target program**, revising the **parameter EXC_OFF_RST, parameter EXC_OFF_ILLINSN, parameter EXC_OFF_ECALL, parameter EXC_OFF_LSUERR** 
   - **gcd:         114e4, 114e8, 114ec, 114f0**  
   - adaline:     10680, 10684, 10688, 1068c  
   - qsort_small: 11688, 1168c, 11690, 10694 
- Modify the program linker script **DIR/pulpino/sw/ref/link.common.ld** with **target program**
   -  **gcd         => instrram    : ORIGIN = 0x0000114e4, LENGTH = 0x8000**
   -  adaline     => instrram    : ORIGIN = 0x000010680, LENGTH = 0x8000 
   -  qsort_small => instrram    : ORIGIN = 0x000011688, LENGTH = 0x8000 
- Restore the RISCV bin
   - $ cd DIR/pulpino/sw/app/gcd # Example
   - $ vim gcd.c # use :w store txt file to ensure recompilation 

- Modify the **DIR/pulpino/sw/build/genFaultList.py**
   - fault_inject_component
      - 0: data register
   - read_rtl_fault_list
      - 0: gen_one_fault_list()

- Run time PULpino program RTL simulation second time (The result of simulation start address can sync up with ISS program simulation)
   - $ cd DIR/pulpino/sw/build
   - $ make gcd.read (Generate new binary.Take gcd for example)
   - On the Modelsim GUI
      - $ python ../../genFaultList.py # for check the correctness of program execution
  
```
Operation Platform: ISS Fault Simulator (On ws32)     
                                                       
Generate the RISCV ELF from ws32                          
```

- Suppose the ISS fault simulation is installed
- Suppose the RISCV bin linker script on ISS is the following
   - MEMORY
   - {
   -  instrram    : ORIGIN = 0x00000050, LENGTH = 0x800000
   -  dataram     : ORIGIN = 0x00900000, LENGTH = 0x600000
   -  stack       : ORIGIN = 0x01006000, LENGTH = 0x2000
   - }
- Recompile the RISCV BIN for ISS (gcd for example)
   - $ cd DIR/FaultInjectionPlatform/src/RISCV_ISS/riscv/tests/gcd
   - $ sh build_pulpino_bin.sh

```
Operation Platform: ISS Fault Simulator (On local PC) 
                                                       
Go Back to ISS Fault Simulator for Generation of      
Fault List                                            
```

- Copy the program-ASM ans program-ELF from server to local pc (gcd for example)
   - $ scp m105061614@140.114.24.31:/home/m105/m105061614/NTHU/Research/Git/FaultInjectionPlatform/src/RISCV_ISS/riscv/tests/gcd/gcd.elf DIR/FaultInjectionPlatform/src/RISCV_ISS/riscv/tests/gcd
   - $ scp m105061614@140.114.24.31:/home/m105/m105061614/NTHU/Research/Git/FaultInjectionPlatform/src/RISCV_ISS/riscv/tests/gcd/gcd.read

- Modify the ISS **genFaultList.py** (in DIR/FaultInjectionPlatform/src/RISCV_ISS/build)
   - register_name_id    
      - 8 for ArchC-CPU register file
   - injectNum          
      - Total number to simulate fault
   - read_rtl_fault_list
      - 1: gen_random_fault_list_with_regen()               # data register fault effect matched
      - 2: gen_random_fault_list_without_regen()
      - 4: read_current_fault_list()                        # data reigster fault for debug
      - 6: non_read_non_arch_propagation_table_fault_list() # non-arch reigster fault
   - faultmodel
      - 1 forbit flip
   - SW
      - Ex: 'gcd'

- Execute the ISS fault simulation
   - $ cd DIR/FaultInjectionPlatform/src/RISCV_ISS/build
   - $ python genFaultList.py
      - Note
         - Instruction count and corresponding cycle mapping
         - Pick up the fault injectable instruction by skipping the system-call injection.
         - Randomly select the fault location
         - Copy the fault list and corresponding fault simulation output to ws32 for PULPino fault simulation and compare the ISS fault simulation correctness

```
Operation Platform: PULPino and Modelsim (ws32)       
                                                      
RTL Fault Simulation and Compare Result from ISS FSIM 
```
- Change directory to pulpino/sw/build
   - $ cd DIR/pulpino/sw/build
- Modify the **DIR/pulpino/sw/build/genFaultList.py**
   - fault_inject_component
      - 0: data register
   - read_rtl_fault_list
      - 2: read_iss_fault_location_list()
- Change GUI to Modelsim to execute the fault simulation which fault lists are from generation of ISS FSIM
   - $ python ../../genFaultList.py
- The end of RTL FSIM will show the accuracy of ISS FSIM
