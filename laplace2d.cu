#include <stdio.h>
#include "constants.h"
#include "helper_cuda.h"
#include "laplace2d_initializer.h"
#include "laplace2d_error_checker.h"
#include "laplace2d_utils.h"
#include "laplace2d_timer.cu"
#include "laplace2d_kernel.cu"
#include "cooperative_groups.h"
using namespace cooperative_groups;

#define CU checkCudaErrors 
#define start_timer cudaEventRecord

int main(int argc, const char **argv){
    int    i, j, ind,
           ibyte = NX*NY * sizeof(float);
    float  *h_u1, *h_u2,
           *d_u1, *d_u2,
           milli;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    h_u1 = (float *)malloc(ibyte);
    h_u2 = (float *)malloc(ibyte);
    CU(cudaMalloc((void **)&d_u1, ibyte));
    CU(cudaMalloc((void **)&d_u2, ibyte));

    initialize_host_region(h_u1);

    start_timer(start);
    CU(cudaMemcpy(d_u1, h_u1, ibyte, cudaMemcpyHostToDevice));
    stop_timer(&start, &stop, &milli, "\ncudaMemcpyHostToDevice: %.1f (ms) \n");

    readSolution(h_u1);

    int device = 0;
    cudaDeviceProp deviceProp;
    cudaGetDeviceProperties(&deviceProp, device);

    dim3 dimBlock(BLOCK_X,BLOCK_Y);
    dim3 dimGrid(deviceProp.multiProcessorCount, 1);
    
    void *args[] = {
        &d_u1,
        &d_u2
    };

    start_timer(start);
    cudaLaunchCooperativeKernel((void*)gpu_laplace2d, dimGrid, dimBlock, args);
    getLastCudaError("gpu_laplace2d execution failed\n");
    stop_timer(&start, &stop, &milli, "\ngpu_laplace2d (coop_smem_opt): %.1f (ms) \n");
    
    start_timer(start);
    CU(cudaMemcpy(h_u2, d_u1, ibyte, cudaMemcpyDeviceToHost));
    stop_timer(&start, &stop, &milli, "\ncudaMemcpyDeviceToHost: %.1f (ms) \n");

    check_domain_errors(h_u1, h_u2, NX, NY);

    // print out corner of array
    for (j=0; j<8; j++) {
      for (i=0; i<8; i++) {
        ind = i + j*NX;
        printf(" %5.2f ", h_u2[ind]);
      }
      printf("\n");
    }

   printf("\n");

    // print out corner of array
    for (j=0; j<8; j++) {
      for (i=0; i<8; i++) {
        ind = i + j*NX;
        printf(" %5.2f ", h_u1[ind]);
      }
      printf("\n");
    }

    saveResult(h_u2);

    CU(cudaFree(d_u1));
    CU(cudaFree(d_u2));
    free(h_u1);
    free(h_u2);

    cudaDeviceReset();
}
