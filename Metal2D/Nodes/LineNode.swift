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
	
	struct VertexColor {
		var r, g, b, a: Float
		init(color: Color) {
			#if os(OSX)
				if color.numberOfComponents < 4 {
					let white = Float(color.whiteComponent)
					r = white
					g = white
					b = white
					a = Float(color.alphaComponent)
				}
				else {
					r = Float(color.redComponent)
					g = Float(color.greenComponent)
					b = Float(color.blueComponent)
					a = Float(color.alphaComponent)
				}
			#elseif os(iOS)
				var red: CGFloat = 0
				var green: CGFloat = 0
				var blue: CGFloat = 0
				var alpha: CGFloat = 0
				if !color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
					color.getWhite(&red, alpha: &alpha)
					green = red
					blue = red
				}
				r = Float(red)
				g = Float(green)
				b = Float(blue)
				a = Float(alpha)
			#endif
		}
	}
	
	struct Uniforms {
		var modelViewProjectionMatrix: GLKMatrix4
	}
	
	var points:[CGPoint] = [.zero, .zero]
	var colors:[Color] = [.white, .white] // TODO: apply colors to vertices
	
	var lineWidth: CGFloat = 0.5
	var length: CGFloat {
		return points[0].distance(fromPoint: points[1])
	}
	
	var corners: [CGPoint] {
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
			return Vertex(point: globalPoint.applying(globalTransform))
		}
		
		return vertices
	}
	
	
	var vertexBuffer:MTLBuffer!
	var vertexColorBuffer:MTLBuffer!
	var uniformsBuffer:MTLBuffer!
	var renderPipelineState: MTLRenderPipelineState!
	
	private var initializedPipeline = false
	
	override func willMoveToScene(_ scene: Scene?) {
		guard let renderView = scene?.renderView, let device = renderView.device, initializedPipeline == false else { return }
		
		let vertexSize = max(MemoryLayout<Vertex>.size * 6, 256)
		vertexBuffer = device.makeBuffer(length:vertexSize * MaxBuffers)
		vertexBuffer.label = "vertices"
		
		let colorSize = max(MemoryLayout<VertexColor>.size * 6, 256)
		vertexColorBuffer = device.makeBuffer(length: colorSize * MaxBuffers)
		vertexColorBuffer.label = "colors"
		
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
		
		let colorArray = (vertexColorBuffer.contents() + 256 * context.bufferIndex).bindMemory(to:VertexColor.self, capacity: 256 / MemoryLayout<VertexColor>.stride)
		for index in 0 ..< vertices.count {
			let colorIndex = [0, 3, 5].contains(index) ? 0 : 1
			colorArray[index] = VertexColor(color: colors[colorIndex])
		}
		
		let uniforms = Uniforms(modelViewProjectionMatrix: context.transform)
		
		let uniformsArray = (uniformsBuffer.contents() + 256 * context.bufferIndex).bindMemory(to:Uniforms.self, capacity: 256 / MemoryLayout<Uniforms>.stride)
		uniformsArray[0] = uniforms
		
		encoder.setRenderPipelineState(renderPipelineState)
		
		encoder.setVertexBuffer(vertexBuffer, offset: 256 * context.bufferIndex, at: 0)
		encoder.setVertexBuffer(vertexColorBuffer, offset: 256 * context.bufferIndex, at: 1)
		encoder.setVertexBuffer(uniformsBuffer, offset: 256 * context.bufferIndex, at: 2)
		
		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
	}
	
}
