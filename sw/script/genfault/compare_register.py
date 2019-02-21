import subprocess
from subprocess import call
import os, sys
import filecmp
import time


SW                        = 'gcd'
faultfreelog              = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/apps/' + SW + '/trace_core_faultfree_regfile_10_cycles.log'
faultlog                  = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/apps/' + SW + '/trace_core_fault_regfile_10_cycles_0.log'
non_arch_fault_file_name  = 'non_arch_fault_location.txt'
propagation_log_file_name = 'propagation_log_location.txt'

injectNum                 = 30

def compare_register(SW, faultfreelog, faultlog, non_arch_fault_location, propagation_log_location):
   
  faultfreearr = []
  faultarr     = []

  with open(faultfreelog, 'rb') as csvfile:
    cnt = 0
    for line in csvfile.readlines():
      array = line.split(',')

      faultfreearr.append([])
      for i in range(0, len(array), 1):
        faultfreearr[cnt].append(array[i])
      cnt = cnt + 1

  with open(faultlog, 'rb') as csvfile:
    cnt = 0
    for line in csvfile.readlines():
      array = line.split(',')

      faultarr.append([])
      for i in range(0, len(array), 1):
        faultarr[cnt].append(array[i])
      cnt = cnt + 1

  # Find the begin of fault injection cycle from fault free log
  match_cycle_cond = 0
  match_cycle_cnt  = 0
  match_cycle      = 0
  while(match_cycle_cond == 0):
    if(faultfreearr[match_cycle_cnt][1].strip() == faultarr[0][1].strip()):
      match_cycle_cond = 1
      match_cycle      = match_cycle_cnt
      break
    match_cycle_cnt = match_cycle_cnt + 1

  

  # Compare PC
  print_once = 0
  for i in range(0, len(faultarr), 1):
    if((faultfreearr[match_cycle+i][2].strip() != faultarr[i][2].strip()) and print_once == 0):
      diff = caldiff(faultfreearr[match_cycle+i][2].strip(), faultarr[i][2].strip(), 'pc')
      #print('         original cycle,%s,propagation cycles,%s,original pc         ,%s,affected pc         ,%s,diff,%d' % (faultfreearr[match_cycle+0][1], faultarr[i][1], faultfreearr[match_cycle+i][2], faultarr[i][2], diff))
      non_arch_fault_location.write('       %s,pc     ,%s,\n' % (faultarr[i][1], diff))
      print_once = 1
  if(print_once == 0):
    #print('(No aff) original cycle,%s' % (faultfreearr[match_cycle+0][1]))
    non_arch_fault_location.write('       %s,pc     ,%s,\n' % (faultarr[i][1], 0))

  # Compare Regfile
  print_once     = 0
  print_reg_once = 0    
  reg_once       = []
  for i in range(0, len(faultarr), 1):

    for j in range(0, 32, 1):
      if((faultfreearr[match_cycle+i][3+j].strip() != faultarr[i][3+j].strip()) and print_once == 0):
        diff = caldiff(faultfreearr[match_cycle+i][3+j].strip(), faultarr[i][3+j].strip(), 'regfile')
        print('         original cycle,%s,propagation cycles,%s,original x%s regfile,%s,affected x%s regfile,%s,diff,%d' % (faultfreearr[match_cycle+0][1], faultarr[i][1], j, faultfreearr[match_cycle+i][j+3], j, faultarr[i][3+j], diff))
        non_arch_fault_location.write('       %s,regfile,%s,\n' % (faultarr[i][1], diff))

        propagation_log_location.write('%s,\n'% (j))
        #reg_once.append(j)
        #for k in range(0, len(reg_once), 1):
        #  if(reg_once[k] != j):
        #    print_once = 1
        #    break
        #  else:
        #    print_once = 0
        print_once = 1
      
  if(print_once == 0):
    print('(No aff) original cycle,%s' % (faultfreearr[match_cycle+0][1]))
    non_arch_fault_location.write('       %s,regfile,%s,\n' % (faultarr[i][1], 0))
   
def caldiff(faultfree, fault, component):
  if(fault.strip().find('xx') < 0 and faultfree.strip().find('xx')):
    hex_faultfree = int(faultfree.strip(),16)
    hex_fault     = int(fault.strip(), 16)

    if(component == 'pc'):
      diff          = hex_fault - hex_faultfree
    elif(component == 'regfile'):
      #diff          = hex_fault - hex_faultfree
      diff          = hex_fault ^ hex_faultfree # cal diff number of bit
  
     
      mask     = 1
      number_1 = 0
      for i in range(0, 32, 1):
        if(diff & mask*pow(2,i) > 0):
          number_1 += 1
      print('Number of bit-flip: %d' % number_1)

    return diff        
  else:
    return 0

def gen_new_fault_list(SW, issfaultreglog, rtlfaultreglog, fault_location):
  iss_reg_log        = []
  rtl_reg_log        = []
  old_fault_location = []
  new_fault_location = []

  for i in range(0, len(issfaultreglog), 1):
    with open(issfaultreglog[i], 'rb') as csvfile:
      iss_reg_log.append([])
      for line in csvfile.readlines():
        array  = line.split(',')
        string = array[0].rjust(8, '0') # zero padding    
        iss_reg_log[i].append(string.strip()) # iss register value

  for i in range(0, len(rtlfaultreglog), 1):
    with open(rtlfaultreglog[i], 'rb') as csvfile:
      rtl_reg_log.append([])
      for line in csvfile.readlines():
        array = line.split(',')
        rtl_reg_log[i].append(array[3]) # rtl register value

  with open(fault_location, 'rb') as csvfile:
    cnt = 0
    for line in csvfile.readlines():
      array = line.split(',')
      old_fault_location.append([])
      for i in range(0, len(array), 1):
        old_fault_location[cnt].append(array[i])
      cnt = cnt + 1

  fault_location = open(fault_location, 'w')
  for i in range(0, len(old_fault_location), 1):
    #print('%s,%s,%s,%s' % (iss_reg_log[i][0], rtl_reg_log[i][0], iss_reg_log[i][1], rtl_reg_log[i][1]))
    if(iss_reg_log[i][0] == rtl_reg_log[i][0] and 
       iss_reg_log[i][1] == rtl_reg_log[i][1]):
      #print('%s' % (old_fault_location[i]))
      for j in range(0, len(old_fault_location[i])-1, 1):
        print('%s,' % (old_fault_location[i][j])),
        fault_location.write('%s,' % (old_fault_location[i][j]))
      print()
      fault_location.write('\n')
  fault_location.close()
  
def fault_propagation(injectNum, propagation_log_location):

  reg = []
  x0  = 0
  x1  = 0
  x2  = 0
  x3  = 0
  x4  = 0
  x5  = 0
  x6  = 0
  x7  = 0
  x8  = 0 
  x9  = 0
  x10 = 0
  x11 = 0
  x12 = 0
  x13 = 0
  x14 = 0
  x15 = 0
  x16 = 0
  x17 = 0
  x18 = 0 
  x19 = 0
  x20 = 0
  x21 = 0
  x22 = 0
  x23 = 0
  x24 = 0
  x25 = 0
  x26 = 0
  x27 = 0
  x28 = 0 
  x29 = 0
  x30 = 0
  x31 = 0

  with open('./propagation_log_location.txt', 'rb') as csvfile:
    for line in csvfile.readlines():
      array = line.split(',')
      reg.append(array[0])

  for i in range(0, len(reg), 1):
    if(int(reg[i])   == 0):
      x0 += 1
    elif(int(reg[i]) == 1):
      x1 += 1
    elif(int(reg[i]) == 2):
      x2 += 1
    elif(int(reg[i]) == 3):
      x3 += 1
    elif(int(reg[i]) == 4):
      x4 += 1
    elif(int(reg[i]) == 5):
      x5 += 1
    elif(int(reg[i]) == 6):
      x6 += 1
    elif(int(reg[i]) == 7):
      x7 += 1
    elif(int(reg[i]) == 8):
      x8 += 1
    elif(int(reg[i]) == 9):
      x9 += 1
    elif(int(reg[i]) == 10):
      x10 += 1
    elif(int(reg[i]) == 11):
      x11 += 1
    elif(int(reg[i]) == 12):
      x12 += 1
    elif(int(reg[i]) == 13):
      x13 += 1
    elif(int(reg[i]) == 14):
      x14 += 1
    elif(int(reg[i]) == 15):
      x15 += 1
    elif(int(reg[i]) == 16):
      x16 += 1
    elif(int(reg[i]) == 17):
      x17 += 1
    elif(int(reg[i]) == 18):
      x18 += 1
    elif(int(reg[i]) == 19):
      x19 += 1
    elif(int(reg[i]) == 20):
      x20 += 1
    elif(int(reg[i]) == 21):
      x21 += 1
    elif(int(reg[i]) == 22):
      x22 += 1
    elif(int(reg[i]) == 23):
      x23 += 1
    elif(int(reg[i]) == 24):
      x24 += 1
    elif(int(reg[i]) == 25):
      x25 += 1
    elif(int(reg[i]) == 26):
      x26 += 1
    elif(int(reg[i]) == 27):
      x27 += 1
    elif(int(reg[i]) == 28):
      x28 += 1
    elif(int(reg[i]) == 29):
      x29 += 1
    elif(int(reg[i]) == 30):
      x30 += 1
    elif(int(reg[i]) == 31):
      x31 += 1

  print('Data register propagation probability' % ())
  print('x0:  %f, x1:  %f, x2:  %f, x3:  %f, x4:  %f, x5:  %f, x6:  %f, x7:  %f' % (float(x0)/float(injectNum), float(x1)/float(injectNum), 
                                                                            float(x2)/float(injectNum), float(x3)/float(injectNum), 
                                                                            float(x4)/float(injectNum), float(x5)/float(injectNum), 
                                                                            float(x6)/float(injectNum), float(x7)/float(injectNum)))
  print('x8:  %f, x9:  %f, x10: %f, x11: %f, x12: %f, x13: %f, x14: %f, x15: %f' % (float(x8)/float(injectNum), float(x9)/float(injectNum), 
                                                                            float(x10)/float(injectNum), float(x11)/float(injectNum), 
                                                                            float(x12)/float(injectNum), float(x13)/float(injectNum), 
                                                                            float(x14)/float(injectNum), float(x15)/float(injectNum)))
  print('x16: %f, x17: %f, x18: %f, x19: %f, x20: %f, x21: %f, x22: %f, x23: %f' % (float(x16)/float(injectNum), float(x17)/float(injectNum), 
                                                                            float(x18)/float(injectNum), float(x19)/float(injectNum), 
                                                                            float(x20)/float(injectNum), float(x21)/float(injectNum), 
                                                                            float(x22)/float(injectNum), float(x23)/float(injectNum)))
  print('x24: %f, x25: %f, x26: %f, x27: %f, x28: %f, x29: %f, x30: %f, x31: %f' % (float(x24)/float(injectNum), float(x15)/float(injectNum), 
                                                                            float(x26)/float(injectNum), float(x27)/float(injectNum), 
                                                                            float(x28)/float(injectNum), float(x29)/float(injectNum), 
                                                                            float(x30)/float(injectNum), float(x31)/float(injectNum)))
if __name__== "__main__":

  non_arch_fault_location  = open(non_arch_fault_file_name, 'w')
  propagation_log_location = open(propagation_log_file_name, 'w')
  for i in range(0, injectNum, 1):
    faultlog = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/apps/' + SW + '/trace_core_fault_regfile_10_cycles_' + str(i) + '.log'
    compare_register(SW, faultfreelog, faultlog, non_arch_fault_location, propagation_log_location)
  non_arch_fault_location.close()
  propagation_log_location.close()

  issfaultreglogarr = []
  rtlfaultreglogarr = []
  fault_location = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/fault_location.txt'
  for i in range(0, injectNum, 1):
    issfaultreglog = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/apps/' + SW + '/register_fault_dump' + str(i) + '.log'
    rtlfaultreglog = '/home/m105/m105061614/NTHU/Research/Git/pulpino/sw/build/apps/' + SW + '/trace_core_fault_regfile_dump_' + str(i) + '.log'
    issfaultreglogarr.append(issfaultreglog)
    rtlfaultreglogarr.append(rtlfaultreglog)
    
  fault_propagation(injectNum, propagation_log_file_name)
  #gen_new_fault_list(SW, issfaultreglogarr, rtlfaultreglogarr, fault_location)  


