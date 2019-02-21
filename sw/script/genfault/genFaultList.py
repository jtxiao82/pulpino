import subprocess
from subprocess import call
import os, sys
import filecmp
import time
import compare_register

###############################
#                             #
#     Fault configuration     # 
#                             #
###############################
fault_config_file_name  = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/fault_config.data'
fault_effect_file       = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/fault_effect.log'
iss_fault_location_list = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/fault_location.txt'
faultfree_stdout        = 'stdout_faultfree' 
iss_fault_effect        = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/fault_effect_list.txt'
rtl_fault_effect        = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/fault_effect.log'

SW                      = 'gcd'
fault_inject_component  = 0 # 0: data register
                            # 1: program counter
                            # 2: if stage instr rdata

read_rtl_fault_list     = 2 # 0: gen_one_fault_list()
                            # 1: gen_fix_datareg_sequential_bitpos_fault_list()
                            # 2: read_iss_fault_location_list()
time_arr                = []

###################################
#                                 #
#     Fault List Generation       #
#                                 #
###################################
def gen_one_fault_list():
  inject_begin_cycle    = []
  inject_end_cycle      = []
  inject_end_next_cycle = []
  inject_datareg        = []
  inject_bitpos         = []

  # Modify by hand
  Inject_Begin_Cycle    = 1420
  Inject_End_Cycle      = Inject_Begin_Cycle + 1
  Inject_End_Next_Cycle = 1422
  Inject_Datareg        = 5
  Inject_Bitpos         = 29

  inject_begin_cycle.append(Inject_Begin_Cycle)
  inject_end_cycle.append(Inject_End_Cycle)
  inject_datareg.append(Inject_Datareg)
  inject_bitpos.append(Inject_Bitpos)
  inject_end_next_cycle.append(Inject_End_Next_Cycle)
  
  injectnum = 1

  return inject_begin_cycle, inject_end_cycle, inject_end_next_cycle, inject_datareg, inject_bitpos, injectnum

def gen_fix_datareg_sequential_bitpos_fault_list():
  inject_begin_cycle = []
  inject_end_cycle   = []
  inject_datareg     = []
  inject_bitpos      = []

  # Modify by hand
  Inject_Begin_Cycle = 30743
  Inject_End_Cycle   = 30744
  Inject_Datareg     = 15
  injectnum          = 32

  for i in range(0, injectnum, 1):
    inject_begin_cycle.append(Inject_Begin_Cycle)
    inject_end_cycle.append(Inject_End_Cycle)
    inject_datareg.append(Inject_Datareg)
    inject_bitpos.append(i)

  return inject_begin_cycle, inject_end_cycle, inject_datareg, inject_bitpos, injectnum

def read_iss_fault_location_list():
  inject_begin_cycle    = []
  inject_end_cycle      = []
  inject_end_next_cycle = []
  inject_datareg        = []
  inject_bitpos         = []
  injectnum             = 0

  with open(iss_fault_location_list, 'rb') as csvfile:
    for line in csvfile.readlines():
      array = line.split(',')
      inject_begin_cycle.append(int(array[1]))
      inject_end_cycle.append(int(array[1])+1)
      inject_datareg.append(int(array[3]))
      inject_bitpos.append(int(array[4]))
      inject_end_next_cycle.append(int(array[5]))
      injectnum += 1

  return inject_begin_cycle, inject_end_cycle, inject_end_next_cycle, inject_datareg, inject_bitpos, injectnum

def FaultFreeSimulation():
  fault_sim = 0

  #if(read_rtl_fault_list == 0):
  inject_begin_cycle, inject_end_cycle, inject_end_next_cycle, inject_datareg, inject_bitpos, injectnum = gen_one_fault_list()

  fault_location = open(fault_config_file_name, 'w')
  for num in range(0, 1, 1):
    fault_location.write("%x\n" % (fault_sim))
    fault_location.write("%x\n" % (inject_datareg[num]))
    fault_location.write("%x\n" % (inject_bitpos[num]))
    fault_location.write("%x\n" % (inject_begin_cycle[num]))
    fault_location.write("%x\n" % (inject_end_cycle[num]))
    fault_location.write("%x\n" % (0))
    fault_location.write("%s\n" % (inject_end_next_cycle[num]))
  fault_location.close()

  start = time.time();

  bashCommand = 'sh ../../recompile.sh'
  output = subprocess.call(bashCommand, shell=True)
  bashCommand = 'sh ../../remove_log.sh'
  output = subprocess.call(bashCommand, shell=True)
  bashCommand = 'cp trace_core_00_0.log trace_core_00_0_faultfree.log'
  output = subprocess.call(bashCommand, shell=True)
  bashCommand = 'cp trace_core_regfile_en.log trace_core_faultfree_regfile_en.log'
  output = subprocess.call(bashCommand, shell=True)
  bashCommand = 'cp stdout/uart stdout_faultfree'
  output = subprocess.call(bashCommand, shell=True)
  bashCommand = 'cp trace_core_regfile_10_cycles.log trace_core_faultfree_regfile_10_cycles.log'
  output = subprocess.call(bashCommand, shell=True)
  bashCommand = 'cp trace_core_regfile_dump.log trace_core_faultfree_regfile_dump.log'
  output = subprocess.call(bashCommand, shell=True)

  end = time.time();
  time_arr.append(end - start)


def FaultSimulation():

  fault_sim = 1

  if(read_rtl_fault_list == 0):
    inject_begin_cycle, inject_end_cycle, inject_end_next_cycle, inject_datareg, inject_bitpos, injectnum = gen_one_fault_list()
  elif(read_rtl_fault_list == 1):
    inject_begin_cycle, inject_end_cycle, inject_datareg, inject_bitpos, injectnum = gen_fix_datareg_sequential_bitpos_fault_list()
  elif(read_rtl_fault_list == 2):
    inject_begin_cycle, inject_end_cycle, inject_end_next_cycle, inject_datareg, inject_bitpos, injectnum = read_iss_fault_location_list()
   

  fault_effect_arr = []

  for num in range(0, injectnum, 1):
    fault_location = open(fault_config_file_name, 'w')
    fault_location.write("%x\n" % (fault_sim))
    fault_location.write("%x\n" % (inject_datareg[num]))
    fault_location.write("%x\n" % (inject_bitpos[num]))
    fault_location.write("%x\n" % (inject_begin_cycle[num]))
    fault_location.write("%x\n" % (inject_end_cycle[num]))
    global fault_inject_component
    fault_location.write("%x\n" % (fault_inject_component))
    fault_location.write("%x\n" % (inject_end_next_cycle[num]))
    fault_location.close()

    start = time.time();

    bashCommand = 'sh ../../recompile.sh'
    output = subprocess.call(bashCommand, shell=True)
    #bashCommand = 'cp trace_core_00_0.log trace_core_00_0_fault' + str(num) + '.log' # Avoid the disk space not enough
    #output = subprocess.call(bashCommand, shell=True)
    bashCommand = 'cp stdout/uart stdout_fault' + str(num)
    output = subprocess.call(bashCommand, shell=True)
    bashCommand = 'cp trace_core_regfile_10_cycles.log trace_core_fault_regfile_10_cycles_' + str(num) + '.log'
    output = subprocess.call(bashCommand, shell=True)
    bashCommand = 'cp trace_core_regfile_dump.log trace_core_fault_regfile_dump_' + str(num) + '.log'
    output = subprocess.call(bashCommand, shell=True)

    fault_stdout = 'stdout_fault' + str(num)
    fault_effect_arr.append(filecmp.cmp(fault_stdout, faultfree_stdout))

    end = time.time();
    time_arr.append(end - start)


  fault_effect = open(fault_effect_file, 'w')
  for i in range(0, len(fault_effect_arr), 1):
    if(fault_effect_arr[i] == 0):
      fault_effect.write("output error\n")
    elif(fault_effect_arr[i] == 1):
      fault_effect.write("output correct\n")
  fault_effect.close()
  return injectnum

def runtime(time_arr):
  total_run_time = 0
  ffs_run_time   = time_arr[0]
  fs_run_time    = 0

  for i in range(0, len(time_arr), 1):
    total_run_time += time_arr[i]
  for i in range(1, len(time_arr), 1):
    fs_run_time    += time_arr[i]
  return total_run_time, ffs_run_time, fs_run_time

def compare_reg(injectnum):

  if(fault_inject_component == 2):
    non_arch_fault_file_name  = 'non_arch_fault_location.txt'
    non_arch_fault_location   = open(non_arch_fault_file_name, 'w')
    propagation_log_file_name = 'propagation_log_location.txt'
    propagation_log_location  = open(propagation_log_file_name,'w')

    for i in range(0, injectnum, 1):
      faultfreelog = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/apps/' + SW + '/trace_core_faultfree_regfile_10_cycles.log'
      faultlog     = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/apps/' + SW + '/trace_core_fault_regfile_10_cycles_' + str(i) + '.log'
      compare_register.compare_register(SW, faultfreelog, faultlog, non_arch_fault_location, propagation_log_location)
    non_arch_fault_location.close()
    propagation_log_location.close()


    propagation_log_file_name = 'propagation_log_location.txt'
    compare_register.fault_propagation(injectnum, propagation_log_file_name)

def compare_fault_effect(injectnum, rtl_fault_effect, iss_fault_effect):
  match                = 0
  rtl_fault_effect_arr = []
  iss_fault_effect_arr = []

  with open(rtl_fault_effect, 'rb') as csvfile:
    for line in csvfile.readlines():
      array = line.split(',')
      rtl_fault_effect_arr.append(array[0])

  with open(iss_fault_effect, 'rb') as csvfile:
    for line in csvfile.readlines():
      array = line.split(',')
      iss_fault_effect_arr.append(array[0])
 
  for i in range(0, len(rtl_fault_effect_arr), 1):
    if(iss_fault_effect_arr[i] == rtl_fault_effect_arr[i]):
      match += 1  
      
  return match

if __name__== "__main__":

  FaultFreeSimulation()
  injectnum = FaultSimulation()

  compare_reg(injectnum)
  
  num_fault_effect_match = compare_fault_effect(injectnum, rtl_fault_effect, iss_fault_effect)

  total_run_time, ffs_run_time, fs_run_time = runtime(time_arr)
 
  print("\n----- CPU Time -----")
  print("Total Run Time: [%s sec]" % (total_run_time))
  print("Fault Free Simulation Run Time [%s sec]" % (ffs_run_time))
  print("Fault Simulation Run Time [%s sec]" % (fs_run_time))
  print("----- # of Fault Simulated -----")
  print("[%d]\n" % injectnum)
  print("Match fault effect: [%d/%d]\n" %  (num_fault_effect_match, injectnum))
