
# NOTE: Modify the paths below in the INCLUDE variable to point to the
# include files needed to build this project.

PROGRAM=environment
INCLUDE=-I/source/git/naken_asm/include/msp430 -I/source/git/naken_asm/include/sensors

default: $(PROGRAM).hex

%.hex: %.asm
	naken_asm -l -o $*.hex $(INCLUDE) $*.asm

clean:
	@rm -f *.hex *.lst *.ndbg
	@echo "Clean!"

