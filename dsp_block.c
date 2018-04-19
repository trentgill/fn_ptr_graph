#include "dsp_block.h"
#include <stdlib.h>
#include <string.h>

#include "wrMath.h"


// dsp environment config
DSP_env_t _dsp;

filter_lp1_t filt;
osc_sine_t   sineo[3];

void module_init( void )
{
    // initialize the DSP_env_t
    _dsp.m_count = 0;
    _dsp.p_count = 0;

    // old inits for some test modules
    for(uint8_t p=0;p<3;p++){
        osc_sine_init( &sineo[p] ); _dsp.m_count++;
        float tt = ((float)(p)*1.5 + 1.0) * 0.02;
        osc_sine_time( &sineo[p], tt );
    }
    lp1_init( &filt ); _dsp.m_count++;
    lp1_set_coeff( &filt, 0.0001 );
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
    //zero_frame( out, b_size );
    //block_size = b_size;
    float  tmp[b_size];
    float  tmpx[b_size];
    float  tmpy[b_size];
    float* out2 = out;
    float* tmp2 = tmp;
    float* tmpx2 = tmpx;
    float* tmpy2 = tmpy;
    uint16_t i;

// zero out an empty graph
    if( !_dsp.m_count || !_dsp.p_count ){
        zero_frame( out, b_size );
        return;
    }

    for( i=0; i<b_size; i++ ){
        *tmpx2++ = 1.0;
        *tmpy2++ = 0.0;
        *tmp2++ = 0.0;
        *out2++ = 0.0;
    }
    for( uint16_t p=0; p<3; p++ ){
        out2 = out;
        tmp2 = tmp;
        osc_sine_process_v( &sineo[p]
            , b_size
            , tmpx
            , tmpy
            , tmp );
        for( i=0; i<b_size; i++ ){
            *out2++ += *tmp2++;
        }
    }
    mul_vf_f(out, 0.0, out, b_size);
//    lp1_step_v( &filt, tmp, out, b_size );
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
