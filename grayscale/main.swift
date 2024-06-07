//
//  main.swift
//  grayscale
//
//  Created by sithum sandeepa on 2024-06-06.
//

import Metal

let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.makeCommandQueue()!

let library = device.makeDefaultLibrary()!
let kernel = library.makeFunction(name: "process")!

let commandBuffer = commandQueue.makeCommandBuffer()!
let commandEncoder = commandBuffer.makeComputeCommandEncoder()!

commandEncoder.setComputePipelineState(try device.makeComputePipelineState(function: kernel))

let input:Matrix = Matrix<Float>(w:2, h:10, d:1)

let z = input.d - 1
for y in 0..<input.h {
    for x in 0..<input.w {
        input.set(x:x, y:y, z:z, v:Float(y))
    }
}

var params:Params = Params(w_in: Int32(input.w), h_in: Int32(input.h), d_in: Int32(input.d), w_out: Int32(input.w), h_out: Int32(input.h), d_out: Int32(input.d))
commandEncoder.setBytes(&params, length: MemoryLayout<Params>.stride, index: 0)

commandEncoder.setBuffer(device.makeBuffer(bytes: input.data! as [Float], length: MemoryLayout<Float>.stride * input.data!.count, options: [.storageModeShared]), offset: 0, index: 1)

let outputBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride, options: [.storageModeShared])!
commandEncoder.setBuffer(outputBuffer, offset: 0, index: 2)

commandEncoder.dispatchThreadgroups(MTLSize(width: input.w, height: input.h, depth: input.d), threadsPerThreadgroup: MTLSize(width: input.w, height: input.h, depth: input.d))

commandEncoder.endEncoding()
commandBuffer.commit()
commandBuffer.waitUntilCompleted()

let outputPointer = outputBuffer.contents().bindMemory(to: Float.self, capacity: input.data!.count)
let outputArray = Array(UnsafeBufferPointer(start: outputPointer, count: input.data!.count))

let output:Matrix = Matrix<Float>(w:input.w, h:input.h, d:input.d)
output.data = outputArray

for y in 0..<output.h {
    print("Summed: \(output.get(x: 0, y: y, z: 0))")
}
