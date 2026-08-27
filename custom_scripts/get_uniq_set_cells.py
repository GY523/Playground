from pathlib import Path
import re

filepath = Path("/home") / "vchip9" / "temp3"
# print(filepath)

# read the error log file
with open(filepath, "r") as f:
	content = f.readlines()

cells = set()
# parse the cell name using regex
for line in content:
	pattern = r"(TISCL7CNMV0_[\w_]*)\.\s"
	match = re.search(pattern, line)
	if match:
		# add the cell name to a set 
		cells.add(match.group(1))


# after every cell name being read, print the set in the format of [elem1 elem2 ...]
output = ""
for i in cells:
	output+=i + " "
output += "\b"
print(output)
