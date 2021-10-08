#!/bin/bash

if [ ! -d gb-test-roms ] ; then
	git clone https://github.com/retrio/gb-test-roms
fi

function test {
	./run.sh --turbo --silent --headless --profile $2 "../gb-test-roms/cpu_instrs/individual/$1*.gb" 2>&1 \
		| grep -q Passed && echo $1 $n ok || echo $1 $n fail &
}

for n in $* ; do
	cd $n
	test 01 140
	test 02  30
	test 03 140
	test 04 160
	test 05 220
	test 06  30
	test 07  40
	test 08  30
	test 09 550
	test 10 850
	test 11 1050
	cd ..
done

wait
