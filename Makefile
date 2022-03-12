#===============================================================================
# CC65 Tools Assembler Definitions
#-------------------------------------------------------------------------------

AS          = ca65
LD          = cl65
RM          = rm
AS_FLAGS   += --listing $(@:.obj=.lst) -o $@ -DW65C816SXB -DUSE_FIFO=0
LD_FLAGS    =  -C $(CFG) -vm -m $(MAP)

#===============================================================================
# Rules
#-------------------------------------------------------------------------------

.asm.obj:
		$(AS) $(AS_FLAGS) $<

#===============================================================================
# Targets
#-------------------------------------------------------------------------------

CFG     = sxb-hacker.cfg
MAP     = sxb-hacker.map
SREC	= sxb-hacker.srec
BINS    = sxb-0x0200.bin sxb-0x0300.bin sxb-0x7EE0.bin
OBJS	= w65c816sxb.obj sxb-hacker.obj
LSTS	= w65c816sxb.lst sxb-hacker.lst

all:	$(BINS) $(SREC)

clean:
	$(RM) -f $(MAP) $(SREC)\
		$(OBJS)\
		$(LSTS)\
		$(BINS)

debug:
	$(DEBUG)

#===============================================================================
# Dependencies
#-------------------------------------------------------------------------------

$(BINS): $(OBJS) $(CFG)
	$(LD) $(LD_FLAGS) -o $@ $(OBJS)

prog: $(BINS)
	./sxb.py write 0x0200 sxb-0x0200.bin
	./sxb.py write 0x0300 sxb-0x0300.bin
	./sxb.py write 0x7EE0 sxb-0x7EE0.bin
	./sxb.py exec 0x0300

$(SREC): $(BINS)
	srec_cat  -o $(SREC)\
		-execution_start_address 0x0300 -address-length 2\
		sxb-0x0200.bin -binary -offset 0x0200\
		sxb-0x0300.bin -binary -offset 0x0300\
		sxb-0x7EE0.bin -binary -offset 0x7EE0

w65c816sxb.obj: w65c816.inc w65c816sxb.inc w65c816sxb.asm
sxb-hacker.obj: w65c816.inc sxb-hacker.asm

.SUFFIXES: .asm .obj
