
CFLAGS = -Wall -O2 -g -I ../../../SPOOLES.2.2 -DARCH="Linux" -DSPOOLES -DARPACK -DMATRIXSTORAGE -DNETWORKOUT
FFLAGS = -Wall -O2 -g -cpp

CC=cc
FC=gfortran

.c.o :
	$(CC) $(CFLAGS) -c $<
.f.o :
	$(FC) $(FFLAGS) -c $<

include Makefile.inc

SCCXMAIN = ccx_2.23.c

OCCXF = $(SCCXF:.f=.o)
OCCXC = $(SCCXC:.c=.o)
OCCXMAIN = $(SCCXMAIN:.c=.o)

DIR=../../../SPOOLES.2.2

LIBS = \
       $(DIR)/spooles.a \
	../../../ARPACK/libarpack_INTEL.a \
       -lpthread -lm -lc

ccx_2.23: $(OCCXMAIN) ccx_2.23.a  $(LIBS)
	./date.pl; $(CC) $(CFLAGS) -c ccx_2.23.c; $(FC)  -g -Wall -O2 -o $@ $(OCCXMAIN) ccx_2.23.a $(LIBS) -fopenmp

ccx_2.23.a: $(OCCXF) $(OCCXC)
	ar vr $@ $?

e_c3d_ub21.o: ub21_module.o
resultsmech_ub21.o: ub21_module.o
getub21stx.o: ub21_module.o

