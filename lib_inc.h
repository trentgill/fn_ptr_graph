#pragma once

typedef struct inc_{
	// struct contains it's own function pointer
	float (*func_ptr)( struct inc_* self, float in );
	
	// <data>
} inc_t

void inc_init( inc_t* self );
void inc_set_fn( inc_t* self, uint8_t fn );
float inc_now( inc_t* self, float in );
float inc_two( inc_t* self, float in );



