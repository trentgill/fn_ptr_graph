#pragma once

#include "dsp_block.h"

#define IN_PORTS 1
#define OUT_PORTS 1

extern void module_init( void );

extern void module_process_frame(float* in, float* out, uint16_t b_size);
