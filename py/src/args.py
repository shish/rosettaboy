import argparse


def parse_args(args):
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
    parser.add_argument(
        "-p",
        "--profile",
        type=int,
        help="Exit after N frames",
        default=0,
        metavar="N",
    )
    return parser.parse_args(args)
