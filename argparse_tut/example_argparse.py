import argparse

parser = argparse.ArgumentParser()
parser.add_argument("square", type=int, help = "display a square of a given number")
parser.add_argument("-v", "--verbose", action = "store_true",
                    help = "increase output verbosity")
args = parser.parse_args()
ans=args.square**2
if args.verbose:
    print(f"the square of {args.square} equals {ans}")
else:
    print(ans)
