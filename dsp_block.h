#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "wrFilterCli.h"
#include "wrOscSineCli.h"
#include "wrLpGateCli.h"

// #define SINGLE_SAMPLE

void module_init( void );

void module_process_frame( float*   in
                         , float*   out
                         , uint16_t b_size
                         );
#define MODULE_LIMIT 100
#define PATCH_LIMIT  100
typedef struct {
    int       m_count;
    module_t* modules[MODULE_LIMIT];
    int       p_count;
    patch_t*  patches[PATCH_LIMIT];
} DSP_env_t;

int hs_addone( int in );
int* hs_list( void );
int hs_resolve( int* io ); // cheat out of IO()

typedef struct {
    char  name[15];   // 16bytes null-terminated
    void* fn_init; // pointer to fn to init the named module
        // could be pointer to custom struct w sizeof struct & init()
} module_descriptor_t;

// List of all the DSP objects that are available to the graph
// nb: these _init fns actually need to be custom accessor fns
static const module_descriptor_t modules[] =
    { { "IO"              , NULL                }
    , { "LPF1"            , graph_lp1_init      }
    , { "SINE"            , graph_osc_sine_init }
    , { "LPG"             , graph_lpgate_init   }
    , { ""                , NULL                }
    };

//const char* hs_dspInit( void );
const module_descriptor_t* hs_dspInit( void );

typedef module_t* (func_t)( void );
module_t* hs_dspCreateMod( func_t fn );
int* hs_dspGetIns( module_t* box );
int* hs_dspGetParams( module_t* box );
// should also pass environment so it's not global
int hs_dspPatch( module_t*  srcMod
               , int        srcOutIx
               , module_t*  dstMod
               , int        dstInIx
               );
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
