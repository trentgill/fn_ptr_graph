#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// #define SINGLE_SAMPLE

void module_init( void );

void module_process_frame(float* in, float* out, uint16_t b_size);

// Command Line Interface
#define CLI_ENABLED
/*
type? cmd[] =
    { { ".s"            , *fpg_print_all()       }
      { ":q"            , *fpg_exiting()         }
      { "get"           , * }
    } */
char* module_cli( char* cli_input, char* cli_return );
