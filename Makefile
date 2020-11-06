INC	:= -I$(CUDA_HOME)/include -I.
LIB	:= -L$(CUDA_HOME)/lib64
LIBS 	:= -lcudart -lcudadevrt
ifeq ($(BUILD), debug)
    DEBUG := -g -G
endif

NVCCFLAGS	:= -lineinfo -arch=sm_75 -rdc=true --ptxas-options=-v --use_fast_math

all: 		laplace3d_$(ID)

laplace3d_$(ID): laplace3d.cu laplace3d_gold.cpp laplace3d_kernel.h Makefile
		 nvcc laplace3d.cu laplace3d_gold.cpp -o bin/laplace3d_$(ID) \
		      $(DEBUG) $(INC) $(LIB) $(NVCCFLAGS) $(LIBS)            \
		 			    -D BLOCK_X=$(BLOCK_X)            \
		 			    -D BLOCK_Y=$(BLOCK_Y)            \
		 			    -D BLOCK_Z=$(BLOCK_Z)
		
clean:
		rm -f bin/laplace3d_*
