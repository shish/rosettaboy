from src.main import main
import sys, cProfile

exec_args = ("exit_code = main(sys.argv)", globals(), None)

if False:  # Flip this to True to profile.
    cProfile.runctx(*exec_args, sort="tottime")
else:
    exec(*exec_args)


sys.exit(exit_code)
