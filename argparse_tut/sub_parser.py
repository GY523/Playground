import argparse

parser= argparse.ArgumentParser()
subparser = parser.add_subparsers(title="add", description="add expense")
subparser.add_argument("")
args = parser.parse_args()

