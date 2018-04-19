#pragma once

// Command Line Interface
#define CLI_ENABLED

#include <stdint.h>

#define block_size ((uint16_t)64)

typedef struct m_in {
    float*  src;
    char    name[16];
} m_in_t;

typedef struct m_out {
    float*  dst;
    char    name[16];
} m_out_t;

typedef struct m_param {
    float   (*get_param)( void* box );
    void    (*set_param)( void* box
                        , float val
                        );
    char    name[16];
} m_param_t;

typedef struct module {
    int            id;
    void*          self;  // pointer to lib's struct
    void (*process_fnptr)( struct module* box );
    int            in_count;
    m_in_t*        ins;
    int            out_count;
    m_out_t*       outs;
    int            par_count;
    m_param_t*     pars;
} module_t;

typedef struct patch {
    module_t* src_module;
    m_out_t*  src;
    module_t* dst_module;
    m_in_t*   dst;
} patch_t;

//
// then dsp graph traversal just uses
// patch_t dsp_patches[];
//
// also note: in order to allow simple usage, modules w
// integration should wrap the basic "init" function into
// a function that also allocates & fills out a module_t
//
// furthermore, this should be considered an extension on
// the raw dsp (so it can be ignored entirely for embedded)
// thus the whole thing should be in a separate cfile with
// all dependencies held internally, or in a *_ex.h





// steps to usefulness:
// create a module
// patch module to output
// discover module params
// set module params




/*
// accessors for command line interface

// <m_type>
// module type is the class of all modules that can be created
// has subcats (generator, modifier, endpoint)

// get environment context

// pull a list of available <m_type>s and their subcat
// this will be written by hand as part of this lib \
// and must be updated to make new libs available
//
// also need to have access to the datastructure & \
// associated parameter names

// add/remove modules

// create a module of type <module_type>
// alt. additional args for settings initial params
// return a unique module-id
// alt. return a list of parameter name-value pairs
// also - a list of ins & outs!
m_id m_create( m_type );

// destroy a labeled module
// return a success flag
success m_destroy( m_id );

// higher-order fns
// replace an existing module with another (compatible type)
// eg. replace a filter with another filter
success m_replace( m_type, m_id );

// connect modules

// tells the graph to connect an out to an in
// depending on destination this may force exclusivity
// returns a <connection_id> for use by graph compiler
// this is to allow multiple connections at ins/outs
// without it, would require dsp to store lists of i/o
// also, allows connections to be moved, or modules replaced easily
// nb: all connections could easily have attenuators builtin
c_id m_connect( m_id, m_input
              , m_id, m_output
              );
// disconnect the connection referred to by c_id
// simply returns a success flag so cli manager \
// knows whether to update it's local graph
success m_disconnect( c_id );

// parameters
//
*/
