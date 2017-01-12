//
//  LineNode.swift
//  Symmetry
//
//  Created by Pim Coumans on 11/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import Foundation
import CoreGraphics
import Metal
import GLKit

class LineNode : Node {
	
	struct Vertex {
		var x, y, z, w: Float
		init(point: CGPoint) {
			x = Float(point.x)
			y = Float(point.y)
			z = 0
			w = 1
		}
	}
	
	struct Uniforms {
		var modelViewProjectionMatrix: GLKMatrix4
	}
	
	var points = [CGPoint(x: -1, y: 2), CGPoint(x: 1, y: -2)]
	var lineWidth: CGFloat = 0.5
	
	var corners:[CGPoint] {
		var corners = [CGPoint]()
		for pointIndex in 0..<points.count {
			let point = points[pointIndex]
			let otherPoint = points[pointIndex + (pointIndex > 0 ? -1 : 1)]
			
			let difference = otherPoint - point
			let length = sqrt((difference.x * difference.x) + (difference.y * difference.y))
			let offset = difference * (lineWidth / length)
			let lineExtension = CGPoint(x: -offset.y, y: offset.x) / 2
			
			
			corners.append(point - lineExtension)
			corners.append(point + lineExtension)
		}
		return corners
	}
	
	override var bounds: CGRect {
		var bounds = CGRect.null
		for corner in corners {
			bounds = bounds.union(CGRect(origin: corner, size: .zero))
		}
		return bounds
	}
	
	var vertices:[Vertex] {
		let scale = globalScale
		let position = globalPosition
		let vertices = [0, 3, 2, 0, 2, 1].map { index -> Vertex in
			var point = corners[index]
			point.x *= scale.width
			point.y *= scale.height
			let globalPoint = position + point
			return Vertex(point: globalPoint)
		}
		
		return vertices
	}
	
	
	var vertexBuffer:MTLBuffer!
	var uniformsBuffer:MTLBuffer!
	var renderPipelineState: MTLRenderPipelineState!
	
	private var initializedPipeline = false
	
	override func willMoveToScene(_ scene: Scene?) {
		guard let renderView = scene?.renderView, let device = renderView.device, initializedPipeline == false else { return }
		
		let vertexSize = max(MemoryLayout<Vertex>.size, 256)
		vertexBuffer = device.makeBuffer(length:vertexSize * 6 * MaxBuffers)
		vertexBuffer.label = "vertices"
		
		let uniformsSize = max(MemoryLayout<Uniforms>.size, 256)
		uniformsBuffer = device.makeBuffer(length: uniformsSize * MaxBuffers)
		uniformsBuffer.label = "uniforms"
		
		let vertexDescriptor = MTLVertexDescriptor()
		vertexDescriptor.attributes[0].offset = 0
		vertexDescriptor.attributes[0].format = .float4
		vertexDescriptor.attributes[0].bufferIndex = 0
		
		vertexDescriptor.layouts[0].stepFunction = .perVertex
		vertexDescriptor.layouts[0].stride = vertexSize
		
		let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
		
		renderPipelineDescriptor.vertexFunction = renderView.library.makeFunction(name: "line_vertex")!
		renderPipelineDescriptor.fragmentFunction = renderView.library.makeFunction(name: "line_fragment")!
		
		renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
		renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
		renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
		renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
		renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
		
		self.renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
		initializedPipeline = true
	}
	
	override func render(with context:RenderContext) {
		
		guard initializedPipeline else {
			return
		}
		
		let encoder = context.commandEncoder
		
		let vertexArray = (vertexBuffer.contents() + 256 * context.bufferIndex).bindMemory(to:Vertex.self, capacity: 256 / MemoryLayout<Vertex>.stride)
		for index in 0 ..< vertices.count {
			vertexArray[index] = vertices[index]
		}
		
		let uniforms = Uniforms(modelViewProjectionMatrix: context.transform)
		
		let uniformsArray = (uniformsBuffer.contents() + 256 * context.bufferIndex).bindMemory(to:Uniforms.self, capacity: 256 / MemoryLayout<Uniforms>.stride)
		uniformsArray[0] = uniforms
		
		encoder.setRenderPipelineState(renderPipelineState)
		
		encoder.setVertexBuffer(vertexBuffer, offset: 256 * context.bufferIndex, at: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 256 * context.bufferIndex, at: 1)
		
		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
	}
	
}
