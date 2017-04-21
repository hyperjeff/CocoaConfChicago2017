#include <metal_stdlib>
#include <metal_atomic>
#include <metal_integer>
using namespace metal;

enum CharacterCode {
	newline = 10,
	space = 32,
	dash = 45
};

kernel void wordCount(const device int        & textCount    [[ buffer(0) ]],
					  const device char       * text         [[ buffer(1) ]],
				            device atomic_int * globalResult [[ buffer(2) ]],
					  
					  threadgroup atomic_int*  localResult  [[ threadgroup(0) ]],
				 
					  uint globalThreadId  [[ thread_position_in_grid        ]],
					  uint localThreadId   [[ thread_position_in_threadgroup ]],
					  uint threadgroupId   [[ threadgroup_position_in_grid   ]]) {
	
	if (textCount < int(globalThreadId)) return;
	
	atomic_store_explicit(localResult, 0, memory_order_relaxed);
	
	threadgroup_barrier(mem_flags::mem_threadgroup);
	
	int thisCharacter = text[globalThreadId], nextCharacter = text[globalThreadId+1];
	
	bool thisCharacterIsMarker = (thisCharacter == space ||
								  thisCharacter == dash ||
								  thisCharacter == newline);
	
	bool nextCharacterIsMarker = (nextCharacter == space ||
								  nextCharacter == dash ||
								  nextCharacter == newline);
	
	if (thisCharacterIsMarker && !nextCharacterIsMarker) {
		atomic_fetch_add_explicit(localResult, 1, memory_order_relaxed);
	}
	
	threadgroup_barrier(mem_flags::mem_threadgroup);
	
	if (localThreadId == 0) {
		int value = atomic_load_explicit(localResult, memory_order_relaxed);
		atomic_store_explicit(globalResult + threadgroupId, value, memory_order_relaxed);
	}
}
