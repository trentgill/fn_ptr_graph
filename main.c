// dynamic 

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "lib_inc.h"

int main (void)
{
	inc_t inked[2]; // malloc this inside the init function
	inc_init(&inked[0]);
	inc_init(&inked[1]);

	inc_set_fn(&inked[1], 1);

	// link a node to the graph
	// each created node needs a global index
	uint32_t node_ix = 0;
	// add_inc( node_ix++, <source_link> );
	// add_inc( node_ix++, 0 ); // hard link to first add
		// rather than the above, use a standard linked list
		// just create the linked structure

	// compile the graph to arrays
		// check if the node exists
			// if not, init() one of those nodes
			// save *node to the LL & make a reference to it
		// 

	// compute the arrays
	float result = (inked[0].func_ptr)(&inked[0], 3); // result should be 4.0

	// output
	printf("result: %f\n\r", result);

	return 0;
}