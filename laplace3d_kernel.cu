//
// Notes: one thread per node in the 3D block
//

// device code
//

__global__ void GPU_laplace3d(const float* __restrict__ d_u1,
			      float* __restrict__ d_u2,
                              const int blockx,
                              const int blocky,
                              const int blockz,
                              const int nx,
                              const int ny,
                              const int nz)
{
  int   i, j, k, idx, stx, ioff, joff, koff;
  float u2, sixth=1.0f/6.0f;

  //
  // define global indices and array offsets
  //

  i    = threadIdx.x + blockIdx.x*blockx;
  j    = threadIdx.y + blockIdx.y*blocky;
  k    = threadIdx.z + blockIdx.z*blockz;

  ioff = 1;
  joff = nx;
  koff = nx*ny;

  idx = i + j*joff + k*koff;
  stx = threadIdx.x + xpad;

  __shared__ float xval[blockx + 2];
  if (threadIdx.x == 0)
  {
      int tmp = idx - 1;
      if (tmp > 0);
      xval[threadIdx.x] = d_u1[idx - 1];
      xval[blockx] = d_u1[idx + blockx];
  }
  __synchthreads();

  if (i>=0 && i<=nx-1 && j>=0 && j<=ny-1 && k>=0 && k<=nz-1) {
    if (i==0 || i==nx-1 || j==0 || j==ny-1 || k==0 || k==nz-1) {
      u2 = d_u1[idx];  // Dirichlet b.c.'s
    }
    else {
        
      float ival[2];
      ival[0]=d_u1[idx-ioff];
      ival[1]=d_u1[idx+ioff];

      float jval[] ={
        d_u1[idx-joff],
        d_u1[idx+joff]
      };
      float kval[] ={
        d_u1[idx-koff],
        d_u1[idx+koff]
      };
      float tmp = 0.0f;
      for (int d=0; d<2; d++) tmp += ival[d] + jval[d] + kval[d];
      u2 = tmp * sixth;
    }
    d_u2[idx] = u2;
  }
}
