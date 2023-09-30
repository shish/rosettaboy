import typing as t
import argparse
import sys


def parse_args(args: t.List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom")
    parser.add_argument(
        "--info", action="store_true", default=False, help="Show ROM metadata"
    )
    parser.add_argument("-c", "--debug-cpu", action="store_true", default=False)
    parser.add_argument("-g", "--debug-gpu", action="store_true", default=False)
    parser.add_argument("-r", "--debug-ram", action="store_true", default=False)
    parser.add_argument("-H", "--headless", action="store_true", default=False)
    parser.add_argument("-S", "--silent", action="store_true", default=False)
    parser.add_argument("-t", "--turbo", action="store_true", default=False)
    parser.add_argument("-v", "--version", action='version', version=sys.version)
    parser.add_argument(
        "-f",
        "--frames",
        type=int,
        help="Exit after N frames",
        default=0,
        metavar="N",
    )
    parser.add_argument(
        "-p",
        "--profile",
        type=int,
        help="Exit after N seconds",
        default=0,
        metavar="N",
    )
    return parser.parse_args(args)
