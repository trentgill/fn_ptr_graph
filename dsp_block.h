#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "wrCliHelpers.h"
#include "wrFilterCli.h"
#include "wrOscSineCli.h"
#include "wrLpGateCli.h"

// #define SINGLE_SAMPLE

void module_init( void );

void module_process_frame( float* in
                         , float* out
                         , int    b_size
                         );

module_t* graph_io_init( int b_size );
void g_io_process( module_t* box, int b_size );

#define MODULE_LIMIT 100
#define PATCH_LIMIT  100

typedef struct {
    char  name[15];   // 16bytes null-terminated
    void* fn_init; // pointer to fn to init the named module
        // could be pointer to custom struct w sizeof struct & init()
} module_descriptor_t;

// List of all the DSP objects that are available to the graph
// nb: these _init fns actually need to be custom accessor fns
static const module_descriptor_t modules[] =
    { { "IO"              , graph_io_init       }
    , { "LPF1"            , graph_lp1_init      }
    , { "SINE"            , graph_osc_sine_init }
    , { "LPG"             , graph_lpgate_init   }
    , { ""                , NULL                }
    };

typedef struct {
    // possibilities
    const module_descriptor_t* possible_mods;

    // runtime
    int       m_count;
    module_t* modules[MODULE_LIMIT];
    int       p_count;
    patch_t*  patches[PATCH_LIMIT];
} DSP_env_t;

int hs_addone( int in );
int* hs_list( void );

//const char* hs_dspInit( void );
const module_descriptor_t* hs_dspInit( void );
//DSP_env_t* hs_dspInit( void );

typedef module_t* (func_t)( int b_size );
module_t* hs_dspCreateMod( func_t fn );
int hs_dspPatch( module_t*  srcMod
               , int        srcOutIx
               , module_t*  dstMod
               , int        dstInIx
               );
int hs_dspGetOutCount( module_t* box );
m_out_t* hs_dspGetOut( module_t* box, int ix );

int hs_dspGetInCount( module_t* box );
m_in_t* hs_dspGetIn( module_t* box, int ix );

int hs_dspGetParamCount( module_t* box );
m_param_t* hs_dspGetParam( module_t* box, int ix );

int* hs_dspGetIns( module_t* box );
int* hs_dspGetParams( module_t* box );
// should also pass environment so it's not global
void hs_patchCount( int count );
//DSP_env_t* hs_list( void )

// thinking about haskell FFI access here
// we want to accept these types as queries:
//      module_type (SINE)
//      module_id
//      module.<in/out/param_name>
//      patch_id
//      param_val
// and responses can be of type:
//      module_id (.module_type for reference)
//      [in]
//      [out]
//      [param_name]
//      ([in], [out], [param_name])
//      patch_id
//      success/failure
//      param_val
