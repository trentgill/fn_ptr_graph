#include "dsp_block.h"
#include <stdlib.h>
#include <string.h>

#include "wrMath.h"


// dsp environment config
DSP_env_t _dsp;

void module_init( void )
{
    // initialize the DSP_env_t
    _dsp.m_count = 0;
    _dsp.p_count = 0;

    // init standard modules here?
}

#ifdef SINGLE_SAMPLE
void module_process_frame(float* in, float* out, uint16_t b_size)
{
    //block_size = b_size;
    *out++ = 0.0;
}
#else
void zero_frame( float* out, uint16_t b_size )
{
    for( uint16_t i=0; i<b_size; i++ ){
        *out++ = 0.0;
    }
}
void module_process_frame(float* in, float* out, uint16_t b_size)
{
// zero out an empty graph
    if( !_dsp.p_count ){
        zero_frame( out, b_size );
        return;
    }
// clear the output buffer
    float* outP = out;
    for( uint16_t i=0; i<b_size; i++ ){
        *outP++ = 0.0;
    }
// process the graph
    // set IO destination to dsp output
    _dsp.modules[0]->outs[0].dst = out;
    //_dsp.modules[1]->outs[0].dst = _dsp.modules[0]->ins
// this list is the compiled order!
// probably needs a 'compiled' copy that is listed in order
// or could have a list of **s.
    for( uint16_t m=0; m<_dsp.m_count; m++ ){
        _dsp.modules[m]->process_fnptr( _dsp.modules[m] );
    }
// volume down
    mul_vf_f(out, 0.1, out, b_size);
}
#endif

// CLI
//DSP_env_t* hs_list( void )
int* hs_list( void )
{
    return &(_dsp.m_count);
}

// cheat out of haskell IO from any raw ptr access
int hs_resolve( int* io )
{
    return *io;
}

const module_descriptor_t* hs_dspInit( void )
{
    //return &_dsp;

    // old
    return &(modules[0]);
}

module_t* hs_dspCreateMod( func_t initfn )
{
    if(_dsp.m_count++ >= MODULE_LIMIT){
        printf("too many modules!");
        // will segfault the calling fn if it tries to dereference...
        return NULL;
    }
    module_t* p = initfn();
    _dsp.modules[_dsp.m_count] = p;
    return p;
}

int hs_dspPatch( module_t*  srcMod
               , int        srcOutIx
               , module_t*  dstMod
               , int        dstInIx
               )
{
    if( _dsp.p_count >= PATCH_LIMIT ){ return 1; } // failed, too many patches

    _dsp.patches[_dsp.p_count] = malloc( sizeof( DSP_env_t ) );
    patch_t* new = _dsp.patches[_dsp.p_count];

    new->src_module = srcMod;
    new->src        = &(srcMod->outs[srcOutIx]);
    new->dst_module = dstMod;
    new->dst        = &(dstMod->ins[dstInIx]);
    return 0; // success
}


int* hs_dspGetIns( module_t* box )
{
    return ((int*)&(box->in_count));
}
int* hs_dspGetParams( module_t* box )
{
    return ((int*)&(box->par_count));
}
