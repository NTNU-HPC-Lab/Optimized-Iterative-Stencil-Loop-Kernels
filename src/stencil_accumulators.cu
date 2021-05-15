#ifndef STENCIL_ACCUMULATORS_CU
#define STENCIL_ACCUMULATORS_CU

#include "../include/constants.h"

__device__ __host__ __inline__ void accumulate_prev(float *u, float *d_u1, unsigned int idx, int offset)
{
#pragma unroll
    for (unsigned int d=STENCIL_DEPTH; d>=1; d--) *u += d_u1[idx-d*offset];
}

__device__ __host__ __inline__ void accumulate_next(float *u, float *d_u1, unsigned int idx, int offset)
{
#pragma unroll
    for (unsigned int d=1; d<=STENCIL_DEPTH; d++) *u += d_u1[idx+d*offset];
}

__device__ __inline__ void accumulate_hybrid_prev(float *u, float *smem, float *d_u1, unsigned int sidx,
                                            unsigned int idx, unsigned int t,
                                            int soffset, int offset)
{
#pragma unroll
    for (unsigned int d=STENCIL_DEPTH; d>=1; d--) *u += (t >= d) ? smem[sidx-d*soffset] : d_u1[idx-d*offset];
}

__device__ __inline__ void accumulate_hybrid_next(float *u, float *smem, float *d_u1, unsigned int sidx,
                                            unsigned int idx, unsigned int t, unsigned int l,
                                            int soffset, int offset)
{
#pragma unroll
    for (unsigned int d=1; d<=STENCIL_DEPTH; d++) *u += (t+d < l) ? smem[sidx+d*soffset] : d_u1[idx+d*offset];
}

__device__ __inline__ void accumulate_register_prev(float *u, float *yval)
{
#pragma unroll
    for (unsigned int d=0; d<STENCIL_DEPTH; d++) *u += yval[d];
}

__device__ __inline__ void accumulate_register_next(float *u, float *yval)
{
#pragma unroll
    for (unsigned int d=STENCIL_DEPTH+1; d < 2*STENCIL_DEPTH+1; d++) *u += yval[d];
}

__device__ __host__ __inline__ void accumulate_global_i_prev(float* u, float* d_u1, unsigned int idx)
{
    accumulate_prev(u, d_u1, idx, 1);
}

__device__ __host__ __inline__ void accumulate_global_i_next(float* u, float* d_u1, unsigned int idx)
{
    accumulate_next(u, d_u1, idx, 1);
}

__device__ __host__ __inline__ void accumulate_global_j_prev(float* u, float* d_u1, unsigned int idx)
{
    accumulate_prev(u, d_u1, idx, NX);
}

__device__ __host__ __inline__ void accumulate_global_j_next(float* u, float* d_u1, unsigned int idx)
{
    accumulate_next(u, d_u1, idx, NY);
}

__device__ __host__ __inline__ void accumulate_global_k_prev(float* u, float* d_u1, unsigned int idx)
{
    accumulate_prev(u, d_u1, idx, NX*NY);
}

__device__ __host__ __inline__ void accumulate_global_k_next(float* u, float* d_u1, unsigned int idx)
{
    accumulate_next(u, d_u1, idx, NX*NY);
}

__device__ __inline__ void accumulate_smem_i_prev(float* u, float* smem, unsigned int sidx)
{
    accumulate_prev(u, smem, sidx, 1);
}

__device__ __inline__ void accumulate_smem_i_next(float* u, float* smem, unsigned int sidx)
{
    accumulate_next(u, smem, sidx, 1);
}

__device__ __inline__ void accumulate_smem_j_prev(float* u, float* smem, unsigned int sidx)
{
    accumulate_prev(u, smem, sidx, SMEM_P_X);
}

__device__ __inline__ void accumulate_smem_j_next(float* u, float* smem, unsigned int sidx)
{
    accumulate_next(u, smem, sidx, SMEM_P_X);
}

__device__ __inline__ void accumulate_smem_k_prev(float* u, float* smem, unsigned int sidx)
{
    accumulate_prev(u, smem, sidx, SMEM_P_X*SMEM_P_Y);
}

__device__ __inline__ void accumulate_smem_k_next(float* u, float* smem, unsigned int sidx)
{
    accumulate_next(u, smem, sidx, SMEM_P_X*SMEM_P_Y);
}

__device__ __inline__ void accumulate_hybrid_i_prev(float* u, float* smem, float* d_u1, unsigned int sidx, unsigned int idx)
{
    accumulate_hybrid_prev(u, smem, d_u1, sidx, idx, threadIdx.x, 1, 1);
}

__device__ __inline__ void accumulate_hybrid_i_next(float* u, float* smem, float* d_u1, unsigned int sidx, unsigned int idx)
{
    accumulate_hybrid_next(u, smem, d_u1, sidx, idx, threadIdx.x, BLOCK_X, 1, 1);
}

__device__ __inline__ void accumulate_hybrid_j_prev(float* u, float* smem, float* d_u1, unsigned int sidx, unsigned int idx)
{
    accumulate_hybrid_prev(u, smem, d_u1, sidx, idx, threadIdx.y, SMEM_X, NX);
}

__device__ __inline__ void accumulate_hybrid_j_next(float* u, float* smem, float* d_u1, unsigned int sidx, unsigned int idx)
{
    accumulate_hybrid_next(u, smem, d_u1, sidx, idx, threadIdx.y, BLOCK_Y, SMEM_X, NX);
}

__device__ __inline__ void accumulate_hybrid_k_prev(float* u, float* smem, float* d_u1, unsigned int sidx, unsigned int idx)
{
    accumulate_hybrid_prev(u, smem, d_u1, sidx, idx, threadIdx.z, SMEM_X*BLOCK_Y, NX*NY);
}

__device__ __inline__ void accumulate_hybrid_k_next(float* u, float* smem, float* d_u1, unsigned int sidx, unsigned int idx)
{
    accumulate_hybrid_next(u, smem, d_u1, sidx, idx, threadIdx.z, BLOCK_Z, SMEM_X*BLOCK_Y, NX*NY);
}

#endif // STENCIL_ACCUMULATORS_CU