#!/bin/bash

function test {
	./run.sh --silent --headless --profile $2 ../test_roms/cpu_instrs/individual/$1*.gb 2>&1 \
		| grep -q Passed && echo $1 $n ok || echo $1 $n fail &
}

for n in $* ; do
	cd $n
	test 01 200
	test 02 100
	test 03 200
	test 04 200
	test 05 300
	test 06 100
	test 07 100
	test 08 100
	test 09 600
	test 10 900
	test 11 1100
	cd ..
done

wait
