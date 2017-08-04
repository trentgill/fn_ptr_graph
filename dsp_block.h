#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// #define SINGLE_SAMPLE

void module_init( void );

void module_process_frame(float* in, float* out, uint16_t b_size);
