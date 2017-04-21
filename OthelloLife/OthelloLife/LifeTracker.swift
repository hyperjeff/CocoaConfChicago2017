import MetalKit

class LifeTracker {

	var metalKitView: MTKView!

	var device: MTLDevice!
	var commandQueue: MTLCommandQueue!
	var library: MTLLibrary!
	var computePipelineState: MTLComputePipelineState!
	var threadgroupSize, threadsPerThreadgroup: MTLSize!

	var cellCurrentBuffer, cellNextBuffer: MTLBuffer!

	var side = 0, area = 0

	let computeName = "gameOfLife"

	var cells: [Bool]!
	
	init(side sideIn: Int) {
		side = sideIn
		area = side * side
		
		setupMetal()
		setupBuffers()
		setupPipeline()
		setupThreads()
	}
	
	func setupMetal() {
		device = MTLCreateSystemDefaultDevice()
		commandQueue = device.makeCommandQueue()
		library = device.newDefaultLibrary()
	}

	func setupPipeline() {
		if let computeKernel = library.makeFunction(name: computeName) {
			do {
				computePipelineState = try device.makeComputePipelineState(function: computeKernel)
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
		cells = [Bool](repeating: false, count: area)
		let length = area * MemoryLayout<Bool>.stride
		
		cellNextBuffer = device.makeBuffer(bytes: cells, length: length, options: .storageModeShared)
		
		for i in 0 ..< area {
			cells[i] = (0.5 < Float(arc4random()) / Float(UInt32.max))
		}
		
		cellCurrentBuffer = device.makeBuffer(bytes: cells, length: length, options: .storageModeShared)
	}

	func compute() {
		let commandBuffer = commandQueue.makeCommandBuffer()
		let computeEncoder = commandBuffer.makeComputeCommandEncoder()
		
		computeEncoder.setComputePipelineState(computePipelineState)
		
		computeEncoder.setBytes(&side, length: MemoryLayout<Int>.stride, at: 0)
		
		computeEncoder.setBuffer(cellCurrentBuffer, offset: 0, at: 1)
		computeEncoder.setBuffer(   cellNextBuffer, offset: 0, at: 2)
		
		computeEncoder.dispatchThreadgroups(threadgroupSize, threadsPerThreadgroup: threadsPerThreadgroup)
		
		computeEncoder.endEncoding()
		
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
	}

	func updateCells() {
		memcpy(cellCurrentBuffer.contents(), cellNextBuffer.contents(), area * MemoryLayout<Bool>.stride)
	}

	func update() {
		compute()
		updateCells()
	}
}
