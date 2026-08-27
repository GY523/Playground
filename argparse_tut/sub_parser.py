import argparse

parser = argparse.ArgumentParser()
subparser = parser.add_subparsers(dest='cmd' ,title="CRUD operation")

parser_add = subparser.add_parser('add', help="add an expense example: PROG add {description} {amount}")
parser_add.add_argument('desc', help="description on expense")
parser_add.add_argument('amt', help="amount", type=int)

args = parser.parse_args()


if args:
    print(str(args))
    print(args.desc)
    print(f"{args.amt=}")



