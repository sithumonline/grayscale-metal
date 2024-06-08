//
//  main.swift
//  grayscale
//
//  Created by sithum sandeepa on 2024-06-06.
//

import Metal
import AppKit

let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.makeCommandQueue()!

let library = device.makeDefaultLibrary()!
let kernel = library.makeFunction(name: "process")!

let commandBuffer = commandQueue.makeCommandBuffer()!
let commandEncoder = commandBuffer.makeComputeCommandEncoder()!

let  pipelineState: MTLComputePipelineState = try device.makeComputePipelineState(function: kernel)
commandEncoder.setComputePipelineState(pipelineState)

let input:Matrix = getImageMatrix(from: URL(string: "https://www.prensalibre.com/wp-content/uploads/2020/04/puppy-1221791_1920.jpg")!)!

var params:Params = Params(w_in: Int32(input.w), h_in: Int32(input.h), d_in: Int32(input.d), w_out: Int32(input.w), h_out: Int32(input.h), d_out: Int32(input.d))
commandEncoder.setBytes(&params, length: MemoryLayout<Params>.stride, index: 0)

let inputBuffer = device.makeBuffer(bytes: input.data!, length: MemoryLayout<UInt8>.stride * input.data!.count, options: [.storageModeShared])!
commandEncoder.setBuffer(inputBuffer, offset: 0, index: 1)

let outputBufferSize = MemoryLayout<UInt8>.stride * input.data!.count
let outputBuffer = device.makeBuffer(length: outputBufferSize, options: [.storageModeShared])!
commandEncoder.setBuffer(outputBuffer, offset: 0, index: 2)

let w = pipelineState.threadExecutionWidth
let h = pipelineState.maxTotalThreadsPerThreadgroup / w
commandEncoder.dispatchThreadgroups(MTLSize(width: (input.w + w - 1) / w, height: (input.h + h - 1) / h, depth: input.d), threadsPerThreadgroup: MTLSize(width: w, height: h, depth: 1))

commandEncoder.endEncoding()
commandBuffer.commit()
commandBuffer.waitUntilCompleted()

let outputPointer = outputBuffer.contents().bindMemory(to: UInt8.self, capacity: input.data!.count)
let outputArray = Array(UnsafeBufferPointer(start: outputPointer, count: input.data!.count))

let output:Matrix = Matrix<UInt8>(w:input.w, h:input.h, d:input.d)
output.data = outputArray

saveMatrixAsImage(matrix: output, to: URL(fileURLWithPath: "foo.jpg"))
