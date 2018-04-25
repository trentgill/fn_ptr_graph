#include "dsp_block.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

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
void module_process_frame(float* in, float* out, int b_size)
{
    *out++ = 0.0;
}
#else
void zero_frame( float* out, uint16_t b_size )
{
    for( uint16_t i=0; i<b_size; i++ ){
        *out++ = 0.0;
    }
}
void module_process_frame(float* in, float* out, int b_size)
{
    if( !_dsp.p_count ){ // zero out an empty graph
        zero_frame( out, b_size );
        return;
    }
    _dsp.modules[1]->ins[0].src = _dsp.modules[2]->outs[0].dst; // manual patch

    for( int m=(_dsp.m_count); m>=1; m-- ){ // dsp processing
        (*_dsp.modules[m]->process_fnptr)( _dsp.modules[m], b_size );
    }
    for( int s=0; s<b_size; s++ ){ // output
        out[s] = _dsp.modules[1]->outs[0].dst[s];
    }
}
#endif

// IO helper fns
module_t* graph_io_init( int b_size )
{
    module_t* box = cli_module_init( 0, NULL, g_io_process );
    cli_register_input( box, NULL, "IN"   );
    cli_register_output( box, "OUT", b_size );
    return box;
}
void g_io_process( module_t* box, int b_size )
{
    float* src = box->ins[0].src;
    float* dst = box->outs[0].dst;
    for( int i=0; i<b_size; i++ ){
        *dst++ = *src++;
    }
}


// CLI
//DSP_env_t* hs_list( void )
int* hs_list( void )
{
    return &(_dsp.m_count);
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
    int max_block_size = 96000; // magic number :/
    module_t* p = initfn( max_block_size );
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


    _dsp.patches[_dsp.p_count] = malloc( sizeof( patch_t ) );
    patch_t* new = _dsp.patches[_dsp.p_count];

    new->src_module = srcMod;
    new->src        = &(srcMod->outs[srcOutIx]);
    new->dst_module = dstMod;
    new->dst        = &(dstMod->ins[dstInIx]);

    new->dst->src = new->src->dst; // TERRIBLE NAMES
    //_dsp.modules[1]->ins[0].src = _dsp.modules[2]->outs[0].dst; // manual patch

    return 0; // success
}

int hs_dspGetOutCount( module_t* box )
{
    return (box->out_count);
}
m_out_t* hs_dspGetOut( module_t* box, int ix )
{
    return &(box->outs[ix]);
}

int hs_dspGetInCount( module_t* box )
{
    return (box->in_count);
}
m_in_t* hs_dspGetIn( module_t* box, int ix )
{
    return &(box->ins[ix]);
}

int hs_dspGetParamCount( module_t* box )
{
    return (box->par_count);
}
m_param_t* hs_dspGetParam( module_t* box, int ix )
{
    return &(box->pars[ix]);
}

int* hs_dspGetIns( module_t* box )
{
    return ((int*)&(box->in_count));
}
int* hs_dspGetParams( module_t* box )
{
    return ((int*)&(box->par_count));
}
void hs_patchCount( int count )
{
    _dsp.p_count = count;
}
