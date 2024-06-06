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

var params:Params = Params(w_in: 2, h_in: 10, d_in: 1, w_out: 2, h_out: 10, d_out: 1)
commandEncoder.setBytes(&params, length: MemoryLayout<Params>.stride, index: 0)

let input: [Float] = [0.0, 0.0, 1.0, 1.0, 2.0, 2.0]
commandEncoder.setBuffer(device.makeBuffer(bytes: input as [Float], length: MemoryLayout<Float>.stride * input.count, options: []), offset: 0, index: 1)

let outputBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride, options: [])!
commandEncoder.setBuffer(outputBuffer, offset: 0, index: 2)

commandEncoder.dispatchThreadgroups(MTLSize(width: 2, height: 10, depth: 1), threadsPerThreadgroup: MTLSize(width: 2, height: 10, depth: 1))

commandEncoder.endEncoding()
commandBuffer.commit()
commandBuffer.waitUntilCompleted()

let outputPointer = outputBuffer.contents().bindMemory(to: Float.self, capacity: input.count)
let outputArray = Array(UnsafeBufferPointer(start: outputPointer, count: input.count))

print("Output Buffer Content: \(outputArray)")
