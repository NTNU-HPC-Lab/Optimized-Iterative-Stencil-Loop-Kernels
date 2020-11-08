//
// Notes: one thread per node in the 3D block
//

// device code
//
#ifndef BLOCK_X
#define BLOCK_X 128
#endif

#ifndef BLOCK_Y
#define BLOCK_Y 1
#endif

#ifndef BLOCK_Z
#define BLOCK_Z 1
#endif


#ifndef NX
#define NX 256
#endif

#ifndef NY
#define NY 256
#endif

#ifndef NZ
#define NZ 256
#endif

#include "cooperative_groups.h"

using namespace cooperative_groups;

__global__ void GPU_laplace3d(const float* __restrict__ d_u1,
			      float* __restrict__ d_u2)
{
  int   i, j, k, idx, sdx, ioff, joff, koff;
  const int npad=1, npad2=2;
  float u2, sixth=1.0f/6.0f;

  thread_block tb = this_thread_block();

  //
  // define global indices and array offsets
  //

  i    = threadIdx.x + blockIdx.x*BLOCK_X;
  j    = threadIdx.y + blockIdx.y*BLOCK_Y;
  k    = threadIdx.z + blockIdx.z*BLOCK_Z;

  ioff = 1;
  joff = NX;
  koff = NX*NY;

  idx = i + j*joff + k*koff;
  sdx = threadIdx.x + 1;

  __shared__ float xval[BLOCK_X+2];
  if (threadIdx.x == 0) {
    if (blockIdx.x != 0) {
        xval[threadIdx.x] = d_u1[idx-1];
    } else if (blockIdx.x != gridDim.x-1) {
        xval[sdx+BLOCK_X] = d_u1[idx+BLOCK_X];
    }
  }
  xval[sdx] = d_u1[idx];
  __syncthreads();

  if (idx < NX*NY*NZ) {
      if (i==0 || i==NX-1 || j==0 || j==NY-1 || k==0 || k==NZ-1) {
        // Dirichlet b.c.'s
        u2 = d_u1[idx];
      }
      else {
        float tmp = 0.0f;
        if (threadIdx.x == 0 && blockIdx.x == 0) {
          tmp += d_u1[idx-ioff];
        } else {
          tmp += xval[sdx-ioff];
        }
        if (threadIdx.x == BLOCK_X-1 && blockIdx.x == gridDim.x-1) {
          tmp += d_u1[idx+ioff];
        } else {
          tmp += xval[sdx+ioff];
        }
        float jval[] ={
          d_u1[idx-joff],
          d_u1[idx+joff]
        };
        float kval[] ={
          d_u1[idx-koff],
          d_u1[idx+koff]
        };
        for (int d=0; d<2; d++) tmp += jval[d] + kval[d];
        u2 = tmp * sixth;
      }
      d_u2[idx] = u2;
  }
}
