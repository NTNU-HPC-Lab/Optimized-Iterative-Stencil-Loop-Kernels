#include <stdio.h>
#include "../include/constants.h"
#include "../include/laplace3d_initializer.h"
#include "../include/laplace3d_error_checker.h"
#include "../include/laplace3d_utils.h"
#include "../include/laplace3d_cpu.h"
#include "laplace3d_dispatch.cu"
#include "omp.h"

int main(int argc, const char **argv) {
    float  *h_ref, *d_ref,
           *d_u1[NGPUS], *d_u2[NGPUS],
           milli;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    if (DEBUG) {
        h_ref = (float *)malloc(BYTES);
        if (fopen(SOLUTION, "r") == NULL) {
            laplace3d_cpu();
        }
        readSolution(h_ref);
    }

    cudaEventRecord(start);

    cudaStream_t streams[NGPUS];
    for (int i = 0; i < NGPUS; i++) {
        cudaSetDevice(i);
        CU(cudaStreamCreate(&streams[i]));
    }

    if (NGPUS>1) ENABLE_P2P(NGPUS);

    if (cudaMallocHost((void**)&d_ref, BYTES) != cudaSuccess) {
        fprintf(stderr, "Error returned from pinned host memory allocation\n");
        exit(1);
    }

    initialize_host_region(d_ref);

    unsigned long size = BYTES_PER_GPU;
    if (NGPUS>1) size += HALO_BYTES;
#pragma omp parallel for num_threads(NGPUS)
    for (int i = 0; i < NGPUS; i++) {
        cudaSetDevice(i);
        CU(cudaMalloc((void **)&d_u1[i], size));
        CU(cudaMalloc((void **)&d_u2[i], size));
    }

    int offset;
    if (NGPUS==1) offset=0;
    else          offset=HALO_DEPTH * NX;
#pragma omp parallel for num_threads(NGPUS)
    for (int i = 0; i < NGPUS; i++) {
        cudaSetDevice(i);
        CU(cudaMemcpyAsync(&d_u1[i][offset], &d_ref[i * OFFSET], BYTES_PER_GPU, cudaMemcpyHostToDevice, streams[i]));
    }

    if(NGPUS==1) {
        if (COOP) dispatch_cooperative_groups_kernels(d_u1[0], d_u2[0]);
        else      dispatch_kernels(d_u1[0], d_u2[0]);
    } else dispatch_multi_gpu_kernels(d_u1, d_u2, streams);
    
#pragma omp parallel for num_threads(NGPUS)
    for (int i = 0; i < NGPUS; i++) {
        cudaSetDevice(i);
        CU(cudaMemcpyAsync(&d_ref[i * OFFSET], &d_u1[i][offset], BYTES_PER_GPU, cudaMemcpyDeviceToHost, streams[i]));
    }
    
    for (int i = 0; i < NGPUS; i++) {
        cudaSetDevice(i);
        cudaDeviceSynchronize();
    }

    cudaSetDevice(0);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&milli, start, stop);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    if (DEBUG) {
        //print_corners(h_ref, d_ref);
        check_domain_errors(h_ref, d_ref);
        saveResult(d_ref);
        free(h_ref);
    }

    print_program_info();
    printf("%.4f\n", milli); // Print execution time in ms

    CU(cudaFreeHost(d_ref));

    for (int i = 0; i < NGPUS; i++) {
        cudaSetDevice(i);
        CU(cudaStreamDestroy(streams[i]));
        CU(cudaFree(d_u1[i]));
        CU(cudaFree(d_u2[i]));
        cudaDeviceReset();
    }
}
