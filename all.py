#!/usr/bin/env python3

"""
A tool to easily bulk-run commands like ./build.sh or ./format.sh
"""
import subprocess
import os
import re
import sys
import argparse
from multiprocessing.pool import ThreadPool
import itertools
from pathlib import Path

TEST_ROM_URL = "https://github.com/sjl/cl-gameboy/blob/master/roms/opus5.gb?raw=true"
TEST_DIR = "gb-autotest-roms"

RED = "\033[0;31m"
GREEN = "\033[0;32m"
END = "\033[0m"

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


def bench(lang: str, runner: str, sub: str, frames: int, profile: int, rom: Path) -> bool:
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
            f"{rom}",
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


def blargg(lang: str, rom: Path) -> bool:
    p = subprocess.run(
        [
            "./rosettaboy-release",
            "--turbo",
            "--silent",
            "--headless",
            "--frames",
            "2000",
            f"{rom}",
        ],
        cwd=lang,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )
    if p.returncode == 0 and "Unit test passed" in p.stdout:
        print(f"{lang} {rom.name} = {GREEN}Passed{END}")
    elif p.returncode == 2:
        print(f"{lang} {rom.name} = {RED}Failed{END}")
    else:
        print(f"{lang} {rom.name} = {RED}Crashed{END}\n{p.stdout}")
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

def trace(lang: str, rom: Path) -> bool:
    with open(f"{lang}.cpu", "w") as fp:
        proc = subprocess.run(
            [
                f"./rosettaboy-release",
                "--frames", "10",
                "--silent",
                "--headless",
                "--turbo",
                "--debug-cpu",
                "--debug-ram",
                f"{rom}",
            ],
            cwd=lang,
            stdout=fp,
            stderr=subprocess.STDOUT,
            text=True,
        )
    if proc.returncode != 0:
        print(f"{lang:>5s}: {RED}Failed, check {lang}.cpu{END}")
        return False
    else:
        print(f"{lang:>5s}: {GREEN}Wrote {lang}.cpu{END}")
        return True


def version(lang: str, runner: str, sub: str) -> bool:
    proc = subprocess.run(
        [
            f"./{runner}",
            "--version",
        ],
        cwd=lang,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if proc.returncode != 0:
        print(f"{lang:>5s} / {sub:7s}: {RED}{proc.stdout.strip()} / {proc.stderr.strip()}{END}")
        return False
    else:
        print(f"{lang:>5s} / {sub:7s}: {GREEN}{proc.stdout.strip()}{END}")
        return True


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--default",
        default=False,
        action="store_true",
        help="Only run the default build, not variants",
    )
    parser.add_argument(
        "--threads",
        type=int,
        default=1,
        help="How many tests to run in parallel",
    )
    langs = [os.path.dirname(n) for n in Path(".").glob("*/build.sh")]
    parser.add_argument("command", help="build, bench, blargg, format, or trace")
    parser.add_argument("langs", default=langs, nargs="*", help="Which languages to test")
    parser.add_argument(
        "--frames", type=int, default=0, help="[bench] Run for this many frames"
    )
    parser.add_argument(
        "--profile", type=int, default=0, help="[bench] Run for this many seconds"
    )
    parser.add_argument(
        "--no-rebuild", default=False, action="store_true", help="[build] Don't build if rosettaboy-* exists"
    )
    parser.add_argument(
        "--test-rom",
        type=Path,
        default=Path(os.environ.get("GB_DEFAULT_BENCH_ROM", "opus5.gb")),
        help="Which test rom to run",
        metavar="ROM"
    )
    parser.add_argument(
        "--test-rom-dir",
        type=Path,
        default=os.environ.get("GB_DEFAULT_AUTOTEST_ROM_DIR", "gb-autotest-roms"),
        help="The directory with the test ROMS",
        metavar="DIR"
    )

    args = parser.parse_args()

    if not args.test_rom.exists():
        subprocess.run(
            ["wget", TEST_ROM_URL, "-O", args.test_rom],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True,
        )
    if not args.test_rom.is_absolute():
        args.test_rom = args.test_rom.absolute()
    if not args.test_rom_dir.is_absolute():
        args.test_rom_dir = args.test_rom_dir.absolute()

    return args

def main() -> int:
    args = parse_args()

    p = ThreadPool(args.threads)

    if args.command == "build":
        args.threads = 1  # FIXME: nim explodes when doing parallel builds :(
        builds_to_run = []
        for lang in args.langs:
            for lang_builder in Path(lang).glob("build*.sh"):
                builder = os.path.basename(lang_builder)
                sub = "release"
                if match := re.match("build_(.*).sh", builder):
                    sub = match.group(1)
                if args.no_rebuild and os.path.exists(f"{lang}/rosettaboy-{sub}"):
                    continue
                if args.default and sub != "release":
                    continue
                builds_to_run.append((lang, builder, sub))
        results = p.starmap(build, builds_to_run)

    if args.command == "bench":
        if args.frames == 0 and args.profile == 0:
            args.profile = 10
        tests_to_run = []
        for lang in args.langs:
            for lang_runner in Path(lang).glob("rosettaboy*"):
                runner = os.path.basename(lang_runner)
                sub = "release"
                if match := re.match("rosettaboy-(.*)", runner):
                    sub = match.group(1)
                if not os.access(lang_runner, os.X_OK):
                    continue
                if args.default and sub != "release":
                    continue
                tests_to_run.append((lang, runner, sub, args.frames, args.profile, args.test_rom))
        results = p.starmap(bench, tests_to_run)

    if args.command == "blargg":
        results = p.starmap(blargg, itertools.product(
            args.langs,
            args.test_rom_dir.glob("*/*.gb"),
        ))

    if args.command == "format":
        results = p.starmap(format, [(l, ) for l in args.langs])

    if args.command == "trace":
        results = p.starmap(trace, [(l, args.test_rom) for l in args.langs])

    if args.command == "version":
        tests_to_run = []
        for lang in args.langs:
            for lang_runner in Path(lang).glob("rosettaboy*"):
                runner = os.path.basename(lang_runner)
                sub = "release"
                if match := re.match("rosettaboy-(.*)", runner):
                    sub = match.group(1)
                if not os.access(lang_runner, os.X_OK):
                    continue
                if args.default and sub != "release":
                    continue
                tests_to_run.append((lang, runner, sub))
        results = p.starmap(version, tests_to_run)

    if all(results):
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
