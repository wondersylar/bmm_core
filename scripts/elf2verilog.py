#!/usr/bin/env python3

import sys,os,re

for root, dirs, files in os.walk("xxx/tests/isa_csr_00/elf/", topdown=False):
    for name in files:
        print('filename --->',name )
        os.system("riscv64-unknown-elf-objcopy -O verilog " +os.path.join(root, name) + " xxx/tests/isa_csr_00_init/" + name + ".verilog")
        print('transform OK --->',name )
