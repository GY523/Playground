import argparse
parser = argparse.ArgumentParser()

# positional arguments, options, flags
# argument with -- is an option, without is a positional arg
parser.add_argument('--verbosity', help="increase output verbosity",
                    action='count', default = 0)
# if using count as action and the verbosity value is being compare >= down, 
# default should be added to avoid error when no flag is given, where args.verbosity is Nonetype.
# if its an option then a value is required, so no problem

# action store_true turns the option into a flag
parser.add_argument('-v', '--verbose', help="increase verbose", action="store_true")

parser.add_argument('square', help='square a given value', type=int)

args = parser.parse_args()

answer = args.square**2

if args.verbosity >=2:
    print(f"the square of {args.square} equals {answer}")
elif args.verbosity ==1:
    print(f"{args.square**2=}")
else:
    print(answer)
