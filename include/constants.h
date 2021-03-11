#ifndef BLOCK_X
#define BLOCK_X 32
#endif
#ifndef BLOCK_Y
#define BLOCK_Y 2
#endif
#ifndef BLOCK_Z
#define BLOCK_Z 2
#endif

#ifndef NGPUS
#define NGPUS 1
#endif

#ifndef ITERATIONS
#define ITERATIONS 64
#endif

#ifndef DIMENSIONS
#define DIMENSIONS 3
#endif

#ifndef DIM
#define DIM 256
#endif

#ifndef STENCIL_DEPTH
#define STENCIL_DEPTH 1
#endif

#define NX DIM
#define NY DIM
#if DIMENSIONS==3
#define NZ DIM
#else
#define NZ 1
#endif
#define SIZE             (NX*NY*NZ)
#define OFFSET           (SIZE/NGPUS)
#define BYTES            (SIZE*sizeof(float))
#define BYTES_PER_GPU    (BYTES/NGPUS)

#define HALO_DEPTH       (STENCIL_DEPTH)
#if DIMENSIONS==3
#define BORDER_SIZE      (NX*NY)
#else
#define BORDER_SIZE      (NX)
#endif
#define GHOST_ZONE       (HALO_DEPTH*BORDER_SIZE)
#define GHOST_ZONE_BYTES (GHOST_ZONE*sizeof(float))
#define HALO_BYTES       (2*GHOST_ZONE_BYTES)

#define INTERNAL_START   (HALO_DEPTH)
#if DIMENSIONS==3
#define INTERNAL_END     (INTERNAL_START+NZ/NGPUS)
#else
#define INTERNAL_END     (INTERNAL_START+NY/NGPUS)
#endif

#ifndef DEBUG
#define DEBUG false
#endif

#ifndef SMEM
#define SMEM false
#endif

#ifndef COOP
#define COOP false
#endif

#define CU checkCudaErrors 
