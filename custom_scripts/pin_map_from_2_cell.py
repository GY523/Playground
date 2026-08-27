'''
THIs program read the .lef files to get the pins for a cell.
THen map the pins between two cells. Use when exchanging a cell with a new one.
'''

from pathlib import Path
import re
import argparse
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("old_cell_name", help="First cell name")
parser.add_argument("new_cell_name", help="2nd cell name")

args = parser.parse_args()

class LefParser:
	def __init__(self, lines):
		self.lines = lines
		self.pos = 0

	def get_pins(self, cell_name: str, exclude = ['VDD', 'VSS']):
		pins = []
		

		# find the cell
		for i, line in enumerate(self.lines):
			if line.strip().startswith(f"MACRO {cell_name}"):
				self.pos = i+1
				break
		else:
			return pins 	# None
		
		# parse until hit END for this cell
		while self.pos < len(self.lines):
			line = self.lines[self.pos].strip()
			
			# Stop at cell end
			if line.startswith(f"END {cell_name}"):
				break

			# FOund a pin
			if line.startswith('PIN'):
				pin_name = line.split()[1]
				if pin_name not in exclude:
					pins.append(pin_name)
				
				self.pos += 1
				while self.pos < len(self.lines):
					pin_line = self.lines[self.pos].strip()
					if pin_line.startswith(f"END {pin_name}"):
						break
					self.pos+= 1

			self.pos += 1

		return pins

filepath = Path("/home") /'vchip9'/ 'work_lab' / 'lab1' / 'tech' /'libs' / 'std'/'lef'/'TISCL7CNMV0.lef'
with open(filepath, 'r') as f:
	lines = f.readlines()
# document to find pin
lef_parser = LefParser(lines)

# read arguments given
old_cell_name = args.old_cell_name
new_cell_name = args.new_cell_name

# get pin lists for both cell
pins_old = lef_parser.get_pins(old_cell_name)
pins_new = lef_parser.get_pins(new_cell_name)

# print(f"Pins: {pins}")

# print out(return) the result in old1 new1 old2 new2
for a, b in zip(pins_old, pins_new):
	print(a,b, end=" ")