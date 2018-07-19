import ezb

import argparse
import sys


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file",
            help="post file to convert to html")
    return parser.parse_args(sys.argv[1:])


def main():
    args = parse_args()
    ezb.to_html(args.file)


if __name__ == "__main__":
    main()

