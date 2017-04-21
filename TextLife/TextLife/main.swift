import Metal

// Set-up time:________________________________________________

var device: MTLDevice!
var commandQueue: MTLCommandQueue!
var library: MTLLibrary!
var computePipelineState: MTLComputePipelineState!
var threadgroupSize, threadsPerThreadgroup: MTLSize!

var cellCurrentBuffer, cellNextBuffer: MTLBuffer!

var side = 10
var area = side * side
var same: Int32 = 1

let computeFunctionName = "gameOfLife"

var cells = [Bool](repeating: false, count: area)

func setupMetal() {
	device = MTLCreateSystemDefaultDevice()
	commandQueue = device.makeCommandQueue()
	library = device.newDefaultLibrary()
}

func setupPipeline() {
	if let computeFunction = library.makeFunction(name: computeFunctionName) {
		do {
			computePipelineState = try device.makeComputePipelineState(function: computeFunction)
		}
		catch let error as NSError {
			fatalError("💔 Error: \(error.localizedDescription)")
		}
	}
	else {
		fatalError("💔 Kernel functions not found at runtime")
	}
}

func setupThreads() {
	let threadgroupWidth = 8
	let μ = side / threadgroupWidth + (side == threadgroupWidth ? 0 : 1)
	
	threadgroupSize = MTLSize(width: μ, height: μ, depth: 1)
	threadsPerThreadgroup = MTLSize(width: threadgroupWidth, height: threadgroupWidth, depth: 1)
}

func setupBuffers() {
	let length = area * MemoryLayout<Bool>.stride
	
	cellNextBuffer = device.makeBuffer(bytes: cells, length: length, options: .storageModeShared)
	
	for i in 0 ..< area {
		cells[i] = (0.5 < Float(arc4random()) / Float(UInt32.max))
	}
	
	cellCurrentBuffer = device.makeBuffer(bytes: cells, length: length, options: .storageModeShared)
}

// Runtime:____________________________________________________

func compute() {
	
	let commandBuffer = commandQueue.makeCommandBuffer()
	
		let computeEncoder = commandBuffer.makeComputeCommandEncoder()
		
		computeEncoder.setComputePipelineState(computePipelineState)
		
		computeEncoder.setBytes(&side, length: MemoryLayout<Int>.stride, at: 0)
		
		computeEncoder.setBuffer(cellCurrentBuffer, offset: 0, at: 1)
		computeEncoder.setBuffer(   cellNextBuffer, offset: 0, at: 2)
		
		computeEncoder.dispatchThreadgroups(threadgroupSize,
				threadsPerThreadgroup: threadsPerThreadgroup)
		
		computeEncoder.endEncoding()
	
	commandBuffer.commit()
	commandBuffer.waitUntilCompleted()

}

func updateCells() {
	same = memcmp(cellCurrentBuffer.contents(), cellNextBuffer.contents(), area * MemoryLayout<Bool>.stride)
	memcpy(cellCurrentBuffer.contents(), cellNextBuffer.contents(), area * MemoryLayout<Bool>.stride)
}

func display() {
	print()
	let data = cellCurrentBuffer.contents().bindMemory(to: Bool.self, capacity: area)
	for i in 0 ..< side {
		print("\t", terminator: "")
		for j in 0 ..< side {
			print(data[i * side + j] ? "O" : "-", terminator: " ")
		}
		print()
	}
	print()
	
	if same == 0 {
		print("Cells have reached a static state")
		exit(0)
	}
}

// Set-up time:________________________________________________

setupMetal()
setupBuffers()
setupPipeline()
setupThreads()

// Runtime:____________________________________________________

while true {
	compute()
	updateCells()
	display()
	
	sleep(1)
}
