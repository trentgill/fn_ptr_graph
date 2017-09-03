#include "dsp_block.h"
#include <stdlib.h>
#include <string.h>

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
//    mul_vf_f(out, 0.33, tmp, b_size);
//    lp1_step_v( &filt, tmp, out, b_size );
}
#endif

// CLI
char* module_cli( char* cli_input, char* cli_return )
{
    // temporary direct comparisons
    const char* dotess = ".s\n"; // must be last instr
    const char* get = "get "; // must have an argument
    const char* set = "set "; // must have an arg
    const char* quit = ":q\n";

    char param[64];

    if( 0 == memcmp( dotess, cli_input, 3 ) ){
        // print everything
        cli_return = "print it all";
    } else if( 0 == memcmp( get, cli_input, 4 ) ){
        // get named parameter

        memcpy( param, cli_input+4, strlen(cli_input+4)+1 );
            // this just returns the rest
            // need to match string against param options


        sprintf( cli_return, "getting %s", param );
    } else if( 0 == memcmp( set, cli_input, 4 ) ){
        // set named parameter
        cli_return = "set next";
    } else if (0 == memcmp( quit, cli_input, 5 ) ){
        cli_return = "leaving..";
    } else {
        cli_return = "not found";
    }

    return cli_return;
}
