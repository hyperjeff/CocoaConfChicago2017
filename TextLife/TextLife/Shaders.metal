#include <metal_stdlib>
using namespace metal;

void kernel gameOfLife(
	constant  int & side         [[ buffer(0) ]],
	constant bool * cellsCurrent [[ buffer(1) ]],
	  device bool * cellsNext    [[ buffer(2) ]],
	
	uint2 S [[ threads_per_threadgroup ]],
	uint2 W [[ threadgroups_per_grid ]],
	uint2 z [[ thread_position_in_grid ]]) {
	
	uint i = z.x + z.y * S.y * W.x;
	
	if (side * side < int(i)) return;
	
	uint x = i % side, y = i / side;
	bool leftEdge = (x == 0);
	bool topEdge  = (y == 0);
	bool rightEdge  = (x == uint(side) - 1);
	bool bottomEdge = (y == uint(side) - 1);
	
	if (leftEdge || rightEdge || topEdge || bottomEdge) {
		cellsNext[i] = false;
	}
	else {
		int aliveNeighbors =
			(cellsCurrent[i - side - 1] ? 1 : 0) +
			(cellsCurrent[i - side    ] ? 1 : 0) +
			(cellsCurrent[i - side + 1] ? 1 : 0) +
		
			(cellsCurrent[i - 1] ? 1 : 0) +
			(cellsCurrent[i + 1] ? 1 : 0) +
		
			(cellsCurrent[i + side - 1] ? 1 : 0) +
			(cellsCurrent[i + side    ] ? 1 : 0) +
			(cellsCurrent[i + side + 1] ? 1 : 0);
		
		bool isAlive = cellsCurrent[i];
		
		bool nextCell =
			(isAlive && (2 == aliveNeighbors || 3 == aliveNeighbors)) ||
			(!isAlive && (3 == aliveNeighbors));
		
		cellsNext[i] = nextCell;
	}
}
