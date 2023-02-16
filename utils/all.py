#!/usr/bin/env python3

"""
Usage: ./utils/bench.py zig rs cpp

Will find any rosettaboy-* variants in the named directories
(eg rosettaboy-release, rosettaboy-pypy, rosettaboy-debug, etc)
and run them with a standard set of args.
"""
from glob import glob
import subprocess
import os
import re
import sys
import argparse
from multiprocessing.pool import ThreadPool

TEST_ROM_URL = "https://github.com/sjl/cl-gameboy/blob/master/roms/opus5.gb?raw=true"
TEST_ROM = "opus5.gb"
TEST_DIR = "gb-autotest-roms"

RED = "\033[0;31m"
GREEN = "\033[0;32m"
END = "\033[0m"

if not os.path.exists(TEST_ROM):
    subprocess.run(
        ["wget", TEST_ROM_URL, "-O", TEST_ROM],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=True,
    )

if not os.path.exists(TEST_DIR):
    subprocess.run(
        ["git", "clone", "https://github.com/shish/gb-autotest-roms", TEST_DIR]
    )


def build(lang: str, builder: str, sub: str) -> bool:
    log = f"{lang}/{builder.replace('.sh', '.log')}"
    with open(log, "w") as fp:
        proc = subprocess.run(
            [f"./{builder}"],
            cwd=lang,
            stdout=fp,
            stderr=subprocess.STDOUT,
            text=True,
        )
    if proc.returncode != 0:
        print(f"{lang:>5s} / {sub:7s}: {RED}Failed - see {log}{END}")
        return False
    else:
        print(f"{lang:>5s} / {sub:7s}: {GREEN}Built{END}")
        return True


def bench(lang: str, runner: str, sub: str, frames: int, profile: int) -> bool:
    proc = subprocess.run(
        [
            f"./{runner}",
            "--frames",
            str(frames),
            "--profile",
            str(profile),
            "--silent",
            "--headless",
            "--turbo",
            f"../{TEST_ROM}",
        ],
        cwd=lang,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if proc.returncode != 0:
        print(f"{lang:>5s} / {sub:7s}: {RED}Failed{END}\n{proc.stdout}")
        return False
    else:
        frames = ""
        for line in proc.stdout.split("\n"):
            if "frames" in line:
                frames = line
        print(f"{lang:>5s} / {sub:7s}: {frames}")
        return True


def blargg(lang: str, rom: str) -> bool:
    p = subprocess.run(
        [
            "./rosettaboy-release",
            "--turbo",
            "--silent",
            "--headless",
            "--frames",
            "2000",
            f"../{rom}",
        ],
        cwd=lang,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )
    rom_name = rom.replace(f"{TEST_DIR}/", "")
    if p.returncode == 0 and "Unit test passed" in p.stdout:
        print(f"{lang} {rom_name} = {GREEN}Passed{END}")
    elif p.returncode == 2:
        print(f"{lang} {rom_name} = {RED}Failed{END}")
    else:
        print(f"{lang} {rom_name} = {RED}Crashed{END}\n{p.stdout}")
    return p.returncode == 0 and "Unit test passed" in p.stdout


def format(lang: str) -> bool:
    proc = subprocess.run(
        [f"./format.sh"],
        cwd=lang,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if proc.returncode != 0:
        print(f"{lang:>5s}: {RED}Failed{END}\n{proc.stdout}")
        return False
    else:
        print(f"{lang:>5s}: {GREEN}Formatted{END}")
        return True

def trace(lang: str) -> bool:
    proc = subprocess.run(
        [f"./rosettaboy-release", "--frames", "100", "--silent", "--headless", "--turbo", "--debug-cpu", "--debug-ram", TEST_ROM],
        cwd=lang,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    with open(f"{lang}.cpu", "w") as fp:
        fp.write(proc.stdout)
    if proc.returncode != 0:
        print(f"{lang:>5s}: {RED}Failed, check {lang}.cpu{END}")
        return False
    else:
        print(f"{lang:>5s}: {GREEN}Wrote {lang}.cpu{END}")
        return True

def parse_args():
    p_all = argparse.ArgumentParser()
    p_all.add_argument(
        "--default",
        default=False,
        action="store_true",
        help="Only run the default build, not variants",
    )
    p_all.add_argument(
        "--threads",
        type=int,
        default=1,
        help="How many tests to run in parallel",
    )
    p_all.add_argument("langs", default=[], nargs="*", help="Which languages to test")

    subs = p_all.add_subparsers(dest="command")

    p_bench = subs.add_parser("bench")
    p_bench.add_argument(
        "--frames", type=int, default=0, help="Run for this many frames"
    )
    p_bench.add_argument(
        "--profile", type=int, default=0, help="Run for this many seconds"
    )
    p_bench.add_argument(
        "--no-build", default=False, action="store_true", help="Use existing rosettaboy-* binaries"
    )

    p_blargg = subs.add_parser("blargg")

    p_build = subs.add_parser("build")
    p_build.add_argument(
        "--no-rebuild", default=False, action="store_true", help="Don't build if rosettaboy-* exists"
    )

    p_format = subs.add_parser("format")

    p_trace = subs.add_parser("trace")

    return p_all.parse_args()

def main() -> int:
    args = parse_args()

    if args.command == "build":
        for lang_builder in glob("*/build*.sh"):
            lang = os.path.dirname(lang_builder)
            builder = os.path.basename(lang_builder)
            sub = "release"
            if match := re.match("build_(.*).sh", builder):
                sub = match.group(1)

            if args.no_rebuild and os.path.exists(f"{lang}/rosettaboy-{sub}"):
                continue
            if args.langs and lang not in args.langs:
                continue
            if args.default and sub != "release":
                continue
            if lang == "utils":
                continue
            build(lang, builder, sub)

    if args.command == "bench":
        if args.frames == 0 and args.profile == 0:
            args.profile = 10

        tests_to_run = []
        for lang_runner in glob("*/rosettaboy*"):
            lang = os.path.dirname(lang_runner)
            runner = os.path.basename(lang_runner)
            sub = "release"
            if match := re.match("rosettaboy-(.*)", runner):
                sub = match.group(1)

            if not os.access(lang_runner, os.X_OK):
                continue
            if args.langs and lang not in args.langs:
                continue
            if args.default and sub != "release":
                continue
            tests_to_run.append((lang, runner, sub, args.frames, args.profile))

        p = ThreadPool(args.threads)
        results = p.starmap(bench, tests_to_run)
        return 0 if all(results) else 1

    if args.command == "blargg":
        dirs = args.langs or [n.replace("/build.sh", "") for n in glob("*/build.sh")]
        roms = glob("gb-autotest-roms/*/*.gb")
        tests_to_run = itertools.product(dirs, roms)

        p = ThreadPool(args.threads)
        results = p.starmap(build, [(d, ) for d in dirs])
        if all(results):
            results = p.starmap(test, tests_to_run)
            if all(results):
                sys.exit(0)
            else:
                sys.exit(1)
        else:
            sys.exit(2)

    if args.command == "format":
        for lang_formatter in glob("*/format.sh"):
            lang = os.path.dirname(lang_runner)
            format(lang)

    if args.command == "trace":
        for lang_runner in glob("*/rosettaboy-release"):
            lang = os.path.dirname(lang_runner)
            trace(lang)


if __name__ == "__main__":
    sys.exit(main())
