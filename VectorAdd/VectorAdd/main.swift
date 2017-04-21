import Metal

// Set-up time:________________________________________________

var device: MTLDevice!
var commandQueue: MTLCommandQueue!
var library: MTLLibrary!
var computePipelineState: MTLComputePipelineState!
var threadgroupSize, threadsPerThreadgroup: MTLSize!

var vectorABuffer, vectorBBuffer, outputVectorBuffer: MTLBuffer!

var vectorLength = 10

let computeFunctionName = "vectorAdd"

var vectorA = [Float](repeating: 0, count: vectorLength)
var vectorB = [Float](repeating: 0, count: vectorLength)
var outputVector = [Float](repeating: 0, count: vectorLength)

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
	let groups = (vectorLength + threadgroupWidth - 1) / threadgroupWidth
	
	threadgroupSize = MTLSize(width: groups, height: 1, depth: 1)
	threadsPerThreadgroup = MTLSize(width: threadgroupWidth, height: 1, depth: 1)
}

func setupBuffers() {
	
	for i in 0 ..< vectorLength {
		vectorA[i] = Float(i) / 10
		vectorB[i] = 10 * Float(i)
	}
	
	let numberOfBytes = vectorLength * MemoryLayout<Float>.stride
	
	vectorABuffer = device.makeBuffer(bytes: vectorA,
	                                  length: numberOfBytes,
	                                  options: .storageModeShared)
	
	vectorBBuffer = device.makeBuffer(bytes: vectorB,
	                                  length: numberOfBytes,
	                                  options: .storageModeShared)
	
	outputVectorBuffer = device.makeBuffer(bytes: outputVector,
	                                       length: numberOfBytes,
	                                       options: .storageModeShared)
}

// Runtime:____________________________________________________

func compute() {
	
	let commandBuffer = commandQueue.makeCommandBuffer()
	
		let computeEncoder = commandBuffer.makeComputeCommandEncoder()
		
		computeEncoder.setComputePipelineState(computePipelineState)
	
		computeEncoder.setBytes(&vectorLength, length: MemoryLayout<Int32>.stride, at: 0)
	
		computeEncoder.setBuffer(vectorABuffer, offset: 0, at: 1)
		computeEncoder.setBuffer(vectorBBuffer, offset: 0, at: 2)
		computeEncoder.setBuffer(outputVectorBuffer, offset: 0, at: 3)
		
		computeEncoder.dispatchThreadgroups(threadgroupSize,
			threadsPerThreadgroup: threadsPerThreadgroup)
		
		computeEncoder.endEncoding()
	
	commandBuffer.commit()
	commandBuffer.waitUntilCompleted()
	
}

func display() {
	print()
	
	let output = outputVectorBuffer.contents().bindMemory(to: Float.self, capacity: vectorLength)
	
	print("[ ", terminator: "")
	for i in 0 ..< vectorLength-1 {
		print(output[i], terminator: ", ")
	}
	print("\(output[vectorLength-1]) ]\n")
}

// Set-up time:________________________________________________

setupMetal()
setupBuffers()
setupPipeline()
setupThreads()

// Runtime:____________________________________________________

compute()
display()

print()
