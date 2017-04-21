#include <metal_stdlib>
using namespace metal;

void kernel vectorAdd(
	constant   int & size   [[ buffer(0) ]],
	constant float * a      [[ buffer(1) ]],
	constant float * b      [[ buffer(2) ]],
	  device float * output [[ buffer(3) ]],
					   
    uint index [[ thread_position_in_grid ]]) {
	
	if (index < uint(size)) {
		output[index] = a[index] + b[index];
	}
}

