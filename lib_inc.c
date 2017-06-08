// a library to be f_ptr'd to

#include "lib_inc.h"

// how many fn pointers in the array
#define NUM_FNS = 2;

// array of available function pointers
void (*func_ptr[NUM_FNS]) = {inc_now, inc_two};

void inc_init( inc_t* self )
{
	// link to 
	self->incPtr = func_ptr[0];
	// initialize an instance of the object
}

void inc_set_fn( inc_t* self, uint8_t fn )
{
	// all non-valid inputs do default (0)
	fn = fn > 0 ? (fn < NUM_FNS ? fn : 0) : 0;
	self->incPtr = func_ptr[fn];
}

float inc_now( inc_t* self, float in )
{
	return in + 1;
}

float inc_two( inc_t* self, float in )
{
	return in + 2;
}