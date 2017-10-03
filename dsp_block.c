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
    float  tmp[b_size];
    float  tmpx[b_size];
    float  tmpy[b_size];
    float* out2 = out;
    float* tmp2 = tmp;
    float* tmpx2 = tmpx;
    float* tmpy2 = tmpy;
    uint16_t i;
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

int hs_resolve( int* io )
{
    return *io;
}

const module_descriptor_t* hs_dspInit( void )
{
    return &(modules[0]);
}

module_t* hs_dspCreateMod( func_t fn )
{
    return fn();
}
