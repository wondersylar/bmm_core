#!/usr/bin/env python3



# run this in "xx/tests/isa_csr_00_init/" dir
import sys,os,re

all_lines = []
instr_lines = []
data_lines = []

def find_data_line(lst):
    data_i = 0
    for i,val in enumerate(lst):
        if val == "@00001000\n" :
            data_i = i 
            #print("---data_i",data_i)
    return data_i

for root, dirs, files in os.walk("xxx/tests/isa_csr_00_init/", topdown=False):
    for fl in files :
        filename = os.path.splitext(fl)[0]
        all_lines = []
        instr_lines = []
        data_lines = []
        with open(fl, 'r') as f:
            for line in f:
                all_lines.append(line)

            for i in range(0, find_data_line(all_lines)):
                instr_lines.append(all_lines[i])
            for j in range(find_data_line(all_lines),len(all_lines)):
                if all_lines[j] == "@00001000\n":
                    data_lines.append("@00000000\n")
                elif all_lines[j] == "@00002000\n":
                    data_lines.append("@00001000\n")
                else:
                    data_lines.append(all_lines[j])
            
        instr_fl = open(filename+'_instr.verilog','w')
        for i in instr_lines:
            instr_fl.write(i)
        instr_fl.close()
        
        data_fl  = open(filename+'_data.verilog' ,'w')
        for j in data_lines:
            data_fl.write(j)
        data_fl.close()

        print("write done ----->", filename)
                


  



