#include "dsp_block.h"
#include <stdlib.h>

#include "wrMath.h"
#include "wrFilter.h"
#include "wrOscSine.h"

filter_lp1_t filt;
osc_sine_t   sineo[3];

void module_init( void )
{
    for(uint8_t p=0;p<3;p++){
        osc_sine_init( &sineo[p] );
        float tt = ((float)(p)*1.5 + 1.0) * 0.02;
        osc_sine_time( &sineo[p], tt );
    }
    lp1_init( &filt );
    lp1_set_coeff( &filt, 0.0001 );
}

#ifdef SINGLE_SAMPLE
void module_process_frame(float* in, float* out, uint16_t b_size)
{
    *out++ = 0.0;
}
#else
void module_process_frame(float* in, float* out, uint16_t b_size)
{
    float  tmp[b_size];
    float  tmpx[b_size];
    float* out2 = out;
    float* tmp2 = tmp;
    float* tmpx2 = tmpx;
    uint16_t i;
    for( i=0; i<b_size; i++ ){
        *tmpx2++ = 0.0;
        *tmp2++ = 0.0;
        *out2++ = 0.0;
    }
    for( uint16_t p=0; p<3; p++ ){
        out2 = out;
        tmp2 = tmp;
        osc_sine_process_v( &sineo[p]
            , b_size
            , tmpx
            , tmp );
        for( i=0; i<b_size; i++ ){
            *out2++ += *tmp2++;
        }
    }
    mul_vf_f(out, 0.33, tmp, b_size);
    lp1_step_v( &filt, tmp, out, b_size );
}
#endif

