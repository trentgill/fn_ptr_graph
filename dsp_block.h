#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "wrFilterCli.h"
#include "wrOscSine.h"
#include "wrLpGate.h"

// #define SINGLE_SAMPLE

void module_init( void );

void module_process_frame( float*   in
                         , float*   out
                         , uint16_t b_size
                         );

typedef struct DSP_env {
    int     m_count;

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
    { { "LPF1\0          ", graph_lp1_init }
    //, { "LPG\0           ", lpgate_init    }
//    , { "SINE\0          ", osc_sine_init  }
//    , { "*              ", NULL           }
//    , { "+              ", NULL           }
    , { "\0              ", NULL           }
    };

//const char* hs_dspInit( void );
const module_descriptor_t* hs_dspInit( void );

typedef module_t* (func_t)( void );
module_t* hs_dspCreateMod( func_t fn );

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
//

// need some list (enum?) of available module types
// how does NEW scan a list? best to have a formatted list
// and send to haskell as a ptr & do the work there.
// when an entry is found, need to return a ptr to C
// which will execute the associated init function
// which will finally return the 'id' (aka address) of the mod
