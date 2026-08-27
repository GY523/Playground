'''
This script read the current dir and print list of db by corners.
The value can then be copied and pasted into INNOVUS/scr/user_scr/setup.tcl

'''
import os
from pathlib import Path

cur_dir = os.listdir()
cwd = Path.cwd()
ff_list = []
tt_list = []
ss_list = []
for i, value in enumerate(cur_dir):
	if "FF" in value.upper():
		ff_list.append(cwd / value)
	elif "TT" in value.upper():
		tt_list.append(cwd / value)
	elif "SS" in value.upper():
		ss_list.append(cwd / value)

def print_addr(lst: list):
	for path in lst:
		print(str(path) + '\\') 

print("FF")
print_addr(ff_list)
print("TT")
print_addr(tt_list)
print('SS')
print_addr(ss_list)
		
