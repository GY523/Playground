import re
import subprocess
from pathlib import Path

# get list of cells that needs to be modified
cells_involved = subprocess.check_output("python3 get_uniq_set_cells.py", shell=True,
					executable = "/bin/bash", stderr=subprocess.STDOUT)
cells_involved = cells_involved.decode()

def transfrom_eco_lines(lines, cells_involved):
	'''Transform ecoChangeCell lines with new format'''
	new_lines = []
	for line in lines:
		if line.startswith('ecoChangeCell') and '-inst' in line and '-cell' in line:
			inst_match = re.search(r"-inst\s+(\S+)", line)
			cell_match = re.search(r'-cell\s+(\S+)', line)
			if inst_match and cell_match and cell_match.group(1) in cells_involved:
				inst_name = inst_match.group(1)
				cell_name = cell_match.group(1)
				print(f"{inst_name=} and {cell_name=}")
				
				# check is the cell in interest.
				arg_line = f'set arg "[dbGet [dbGetInstByName {inst_name}].cell.name] {cell_name}"\n'
				eco_line = f'ecoChangeCell -inst {inst_name} -cell {cell_name} -pinMap {{ [ exec python3 ../../STA_dig33_top/custom_scripts/pin_map_from_2_cell.py $arg] }}\n'

				new_lines.append(arg_line)
				new_lines.append(eco_line)
			else:
				# Keep the ori line if it's not ecochangecell line
				new_lines.append(line)
		else:
			new_lines.append(line)

	return ''.join(new_lines)
				
# read tempus file
tempus_file = Path("/home") /'vchip9'/ 'work_lab' / 'lab1' / 'lab1' /'STA_dig33_top' /'tempus_from_pt.tcl'
with open(tempus_file, 'r') as f:
	lines = f.readlines()

transformed_lines = transfrom_eco_lines(lines, cells_involved)

# write new tempus 
new_tempus_file = Path("/home") /'vchip9'/ 'work_lab' / 'lab1' / 'lab1' /'STA_dig33_top' /'tempus_from_pt_modified.tcl'
with open(new_tempus_file, 'w') as f:
	f.write(transformed_lines)

