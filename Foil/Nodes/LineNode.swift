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
	
	var points:[CGPoint] = [.zero, .zero] {
		didSet { clearCache(name: "globalFrame"); clearCache(name: "vertices") }
	}
	var colors:[Color] = [.white, .white]
	
	var lineWidth: CGFloat = 0.5 {
		didSet { clearCache(name: "globalFrame"); clearCache(name: "vertices") }
	}
	var length: CGFloat {
		return points[0].distance(fromPoint: points[1])
	}
	
	var corners: [CGPoint] {
		guard length > 0 else {
			return []
		}
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
		return cached(#function) {
			let scale = globalScale
			let position = globalPosition
			guard corners.count >= 4 else {
				return []
			}
			let vertices = [0, 3, 2, 0, 2, 1].map { index -> Vertex in
				var point = corners[index]
				point.x *= scale.width
				point.y *= scale.height
				let globalPoint = position + point
				return Vertex(point: globalPoint.applying(globalTransform))
			}
			
			return vertices
		}
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
		
		let colorSize = max(MemoryLayout<Color>.size * 6, 256)
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
		
		let colorArray = (vertexColorBuffer.contents() + 256 * context.bufferIndex)
			.bindMemory(to: packed_float4.self, capacity: 256 / MemoryLayout<packed_float4>.stride)
		for index in 0 ..< vertices.count {
			let colorIndex = [0, 3, 5].contains(index) ? 0 : 1
			colorArray[index] = colors[colorIndex].float4
		}
		
		let uniforms = Uniforms(modelViewProjectionMatrix: context.transform)
		
		let uniformsArray = (uniformsBuffer.contents() + 256 * context.bufferIndex).bindMemory(to:Uniforms.self, capacity: 256 / MemoryLayout<Uniforms>.stride)
		uniformsArray[0] = uniforms
		
		encoder.setRenderPipelineState(renderPipelineState)
		
        encoder.setVertexBuffer(vertexBuffer, offset: 256 * context.bufferIndex, index: 0)
        encoder.setVertexBuffer(vertexColorBuffer, offset: 256 * context.bufferIndex, index: 1)
        encoder.setVertexBuffer(uniformsBuffer, offset: 256 * context.bufferIndex, index: 2)
		
		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
	}
	
	override func get<T : Lerpable>(_ property: Property) -> T? {
		switch property {
		case Property.position(at: property.index):
			return points[property.index] as? T
		case Property.color(at: property.index):
			return colors[property.index] as? T
		default:
			return super.get(property)
		}
	}
	
	override func set<T : Lerpable>(_ property: Property, value: T) {
		switch property {
		case Property.position(at: property.index):
			if let point = value as? CGPoint {
				points[property.index] = point
			}
		case Property.color(at: property.index):
			if let color = value as? Color {
				colors[property.index] = color
			}
		default:
			super.set(property, value: value)
		}
	}
}


extension Property {
	static let indexedPosition = Property(rawValue: "indexedPosition")
	static func position(at index: Int) -> Property {
		return Property(indexedPosition.rawValue, at: index)
	}
	static let indexedColor = Property(rawValue: "indexedColor")
	static func color(at index: Int) -> Property {
		return Property(indexedColor.rawValue, at: index)
	}
}
