//
//  TextureNode.swift
//  Metal2D
//
//  Created by Pim Coumans on 25/11/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import QuartzCore
import Metal
import MetalKit
import GLKit

fileprivate let VertextCount = 6

class TextureNode: Node {
	
	struct Vertex {
		var x, y, z, w, u, v: Float
	}
	
	struct Uniforms {
		var modelViewProjectionMatrix: GLKMatrix4
	}
	
    let image: CGImage
    let size: CGSize
    
    var boundingRect: CGRect {
        var rect = CGRect()
        rect.origin = globalPosition
		let scale = globalScale
		let scaledSize = CGSize(width: size.width * scale.width, height: size.height * scale.height)
        rect.origin.x -= scaledSize.width * anchorPoint.x
        rect.origin.y -= scaledSize.height * anchorPoint.y
        rect.size = scaledSize
        return rect
    }
	
	#if os(iOS)
	convenience init?(renderView:RenderView, image:UIImage?, size:CGSize) {
		if let cgImage = image?.cgImage {
			self.init(renderView:renderView, image:cgImage, size:size)
			return
		}
		return nil
	}
	#elseif os(OSX)
	convenience init?(renderView:RenderView, image:NSImage?, size:CGSize) {
		if let data = image?.tiffRepresentation, let imageSource = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(imageSource) > 0 {
			if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
				self.init(renderView:renderView, image:cgImage, size:size)
				return
			}
		}
		return nil
	}
	#endif
	
	init?(renderView:RenderView, image:CGImage, size:CGSize) {
		
		guard let device = renderView.device else {
			return nil
		}
		
		self.image = image
		self.size = size
		self.device = device
		
		let vertexSize = MemoryLayout<Vertex>.size
		
		self.vertexBuffer = device.makeBuffer(length:vertexSize * VertextCount * MaxBuffers, options: [])
		
		let textureLoader = MTKTextureLoader(device:device)
		self.texture = try! textureLoader.newTexture(with: image, options: nil)
		
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .linear
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.sAddressMode = .repeat
		samplerDescriptor.tAddressMode = .repeat
		self.colorSamplerState = self.device.makeSamplerState(descriptor:samplerDescriptor)
		
		let vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].format = .float4
		vertexDescriptor.attributes[0].bufferIndex = 0
		
		vertexDescriptor.attributes[1].offset = 0
		vertexDescriptor.attributes[1].format = .float2
		vertexDescriptor.attributes[1].bufferIndex = 0
		
		vertexDescriptor.layouts[0].stepFunction = .perVertex
		vertexDescriptor.layouts[0].stride = vertexSize
		
		let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
		
		renderPipelineDescriptor.vertexFunction = renderView.library.makeFunction(name: "image_vertex")!
		renderPipelineDescriptor.fragmentFunction = renderView.library.makeFunction(name: "image_fragment")!
		
		renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
		renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
		
		self.renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
		
		super.init()
	}
	
	let texture:MTLTexture
	
	private let device:MTLDevice
	
	var vertices:[Vertex] {
		let rect = boundingRect
		let l = Float(rect.minX)
		let r = Float(rect.maxX)
		let t = Float(rect.minY)
		let b = Float(rect.maxY)
		return [
			Vertex(x: l, y: t, z: 0, w: 1, u: 0, v: 1),
			Vertex(x: l, y: b, z: 0, w: 1, u: 0, v: 0),
			Vertex(x: r, y: b, z: 0, w: 1, u: 1, v: 0),
			Vertex(x: l, y: t, z: 0, w: 1, u: 0, v: 1),
			Vertex(x: r, y: b, z: 0, w: 1, u: 1, v: 0),
			Vertex(x: r, y: t, z: 0, w: 1, u: 1, v: 1),
		]
	}
	
	let vertexBuffer:MTLBuffer
	let colorSamplerState: MTLSamplerState
	let renderPipelineState: MTLRenderPipelineState
	
	override func render(with context:RenderContext) {
		
		let encoder = context.commandEncoder
		var uniforms = Uniforms(modelViewProjectionMatrix: context.transform)
		let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size, options: MTLResourceOptions())
		
		let vertexArray = UnsafeMutablePointer<Vertex>(OpaquePointer(vertexBuffer.contents()))
		let vertices = self.vertices
		let vertexOffset = context.bufferIndex * VertextCount
		for index in vertexOffset ..< vertexOffset + VertextCount {
			vertexArray[index] = vertices[index - vertexOffset]
		}
		
		encoder.setRenderPipelineState(renderPipelineState)
		
		encoder.setFrontFacing(.counterClockwise)
		encoder.setVertexBuffer(vertexBuffer, offset: MemoryLayout<Vertex>.size * vertexOffset, at: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 1)
		
		encoder.setFragmentTexture(texture, at: 0)
		encoder.setFragmentSamplerState(colorSamplerState, at: 0)
		
		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: VertextCount)
    }
}
