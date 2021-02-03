#ifndef laplace3d_CPU
#define laplace3d_CPU

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "constants.h"
#include "laplace3d_initializer.h"
#include "laplace3d_cpu_kernel.h"
#include "laplace3d_utils.h"

inline double seconds()
{
    struct timeval tp;
    struct timezone tzp;
    gettimeofday(&tp, &tzp);
    return ((double)tp.tv_sec + (double)tp.tv_usec * 1.e-6);
}

void laplace3d_cpu()
{
    unsigned int    i;
    float  *h_u1, *h_u3, *h_swap;
    double start, elapsed;

    h_u1 = (float *)malloc(BYTES);
    h_u3 = (float *)malloc(BYTES);

    initialize_host_region(h_u1);

    start = seconds();
    for (i = 1; i <= ITERATIONS; ++i) {
        cpu_laplace3d(h_u1, h_u3);
        h_swap = h_u1; h_u1 = h_u3; h_u3 = h_swap;   // swap h_u1 and h_u3
    }
    elapsed = seconds() - start;
    printf("\ncpu_laplace3d: %.3f (ms) \n", elapsed);

    saveSolution(h_u1);

    free(h_u1);
    free(h_u3);
}

#endif