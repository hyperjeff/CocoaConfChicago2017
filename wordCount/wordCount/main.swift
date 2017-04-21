import Metal

let debugging = false

public func time(_ ƒ: (Void) -> Void) {
	let t0 = CFAbsoluteTimeGetCurrent()
	ƒ()
	let t1 = CFAbsoluteTimeGetCurrent()
	print("⏱ time to execute: \(t1-t0) seconds")
}

let fileToRead = "kafka"
let kernelname = "wordCount"

var device = MTLCreateSystemDefaultDevice()!
var commandQueue: MTLCommandQueue!
var computePipelineState: MTLComputePipelineState!
var randomBuffer, objectsBuffer: MTLBuffer!

let sizeInt32 = MemoryLayout<Int32>.stride
let sizeCChar = MemoryLayout<CChar>.stride

var counter: Int = 0
var textString = ""
do {
	guard let url = Bundle.main.url(forResource: fileToRead, withExtension: "txt") else {
		print("Bundle resource not found!"); abort()
	}
	textString = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String
}
catch {
	print("Can't open file!"); abort()
}

var text = textString.cString(using: .utf8)!
var textCount: Int32 = Int32(text.count)

var threads = 64
let bytesPerChunk = threads * sizeCChar
var threadgroupChunks = Int((text.count + bytesPerChunk - 1) / bytesPerChunk)

if debugging {
	threadgroupChunks = 3
}

guard
	let library = device.newDefaultLibrary(),
	let shader = library.makeFunction(name: kernelname) else {
		print("💔 Kernel file not found."); abort()
}

commandQueue = device.makeCommandQueue()
do {
	computePipelineState = try device.makeComputePipelineState(function: shader)
}
catch {
	print("💔 Unable to create render pipeline state."); abort()
}

var results = [Int32](repeating:0, count: threadgroupChunks)

let textBuffer = device.makeBuffer(bytes: &text,
                                   length: text.count * sizeCChar,
                                   options: .storageModeShared)

let resultBuffer = device.makeBuffer(bytes: &results,
                                     length: threadgroupChunks * sizeInt32,
                                     options: .storageModeShared)

if debugging {
	let test = textBuffer.contents().bindMemory(to: CChar.self, capacity: 20)
	for i in 0 ..< 20 {
		print("test[\(i)] = \(test[i])")
	}
}

print()

let threadgroupsPerGrid = MTLSize(width: threadgroupChunks, height: 1, depth: 1)
let threadsPerThreadgroup = MTLSize(width: threads, height: 1, depth: 1)

time {
	let commandBuffer = commandQueue.makeCommandBuffer()
	let computeEncoder = commandBuffer.makeComputeCommandEncoder()
	
	computeEncoder.setThreadgroupMemoryLength(4 * sizeInt32, at: 0)
	
	computeEncoder.setBytes(&textCount, length: sizeInt32, at: 0)
	
	computeEncoder.setBuffer(  textBuffer, offset: 0, at: 1)
	computeEncoder.setBuffer(resultBuffer, offset: 0, at: 2)
	
	computeEncoder.setComputePipelineState(computePipelineState)
	computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
	
	computeEncoder.endEncoding()
	
	commandBuffer.commit()
	commandBuffer.waitUntilCompleted()
}

let data = resultBuffer.contents().bindMemory(to: Int32.self, capacity: 1)

var words = -1
for i in 0 ..< threadgroupChunks {
	if debugging {
		print("words in threadgroup \(i+1): \(data[i])")
	}
	words += Int(data[i])
}

print("\nWords: \(words)\n")
