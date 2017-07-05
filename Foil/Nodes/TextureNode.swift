//
//  TextureNode.swift
//  Foil
//
//  Created by Pim Coumans on 25/11/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import CoreGraphics
import Metal
import MetalKit
import GLKit

#if os(iOS)
	import UIKit
	typealias Image = UIImage
#elseif os(OSX)
	import Cocoa
	typealias Image = NSImage
#endif

fileprivate let VertextCount = 6
#if os(iOS)
fileprivate let BufferMinLength = 256
#elseif os(OSX)
fileprivate let BufferMinLength = 4
#endif
// TODO: only cap buffer length on iOS

class TextureNode: Node {
	
	struct Vertex {
		var x, y, z, w, u, v: Float
	}
	
	struct Uniforms {
		var modelViewProjectionMatrix: GLKMatrix4
	}
	
	override var frame: CGRect {
		var frame = CGRect(origin: position, size: size)
		frame.size.width *= scale.width
		frame.size.height *= -scale.height
		frame.origin.x -= frame.width * anchorPoint.x
		frame.origin.y += frame.height * anchorPoint.y
		return frame.applying(transform)
	}
	
	override var bounds: CGRect {
		var frame = CGRect(origin: .zero, size: size)
		frame.origin.x -= frame.width * anchorPoint.x
		frame.origin.y += frame.height * anchorPoint.y
		return frame
	}
	
	var imageName: String {
		didSet {
			guard let device = scene?.renderView?.device else { return }
			self.texture = try! TextureNode.loadTexture(imageName: imageName, device: device)
		}
	}
	let size: CGSize
	var color: Color = Color.white
	
	fileprivate class func convert(image:Image) -> CGImage? {
		#if os(OSX)
			if let data = image.tiffRepresentation, let imageSource = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(imageSource) > 0 {
				if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
					return cgImage
				}
			}
		#elseif os(iOS)
			if let cgImage = image.cgImage {
				if let context = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
					context.scaleBy(x: 1, y: -1)
					context.translateBy(x: 0, y: CGFloat(cgImage.height))
					context.draw(cgImage, in: context.boundingBoxOfClipPath)
					if let newImage = context.makeImage() {
						return newImage
					}
				}
			}
		#endif
		return nil
	}
	
	init?(name imageName: String, size: CGSize) {
		self.imageName = imageName
		self.size = size
		
		super.init()
	}
	
	private var initializedPipeline = false
	
	@discardableResult func initializePipeline() -> Bool {
		
		if initializedPipeline {
			return true
		}
		
		guard let renderView = scene?.renderView, let device = renderView.device else {
			return false
		}
		
		let vertexSize = MemoryLayout<Vertex>.size
		vertexBuffer = device.makeBuffer(length:vertexSize * VertextCount * MaxBuffers)
		vertexBuffer.label = "vertices"
		
		let uniformsSize = max(MemoryLayout<Uniforms>.size, 256)
		uniformsBuffer = device.makeBuffer(length: uniformsSize * MaxBuffers)
		uniformsBuffer.label = "uniforms"
		
		let colorSize = max(MemoryLayout<Color>.size, 256)
		colorBuffer = device.makeBuffer(length: colorSize * MaxBuffers)
		colorBuffer.label = "colors"
		
		if texture == nil {
			do {
				texture = try TextureNode.loadTexture(imageName: imageName, device: device)
			}
			catch {
				print(error)
				return false
			}
		}
		
		let samplerDescriptor = MTLSamplerDescriptor()
		samplerDescriptor.minFilter = .linear
		samplerDescriptor.magFilter = .linear
		samplerDescriptor.sAddressMode = .repeat
		samplerDescriptor.tAddressMode = .repeat
		self.colorSamplerState = device.makeSamplerState(descriptor:samplerDescriptor)
		
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
		
		if let renderBufferAttachment = renderPipelineDescriptor.colorAttachments[0] {
			renderBufferAttachment.pixelFormat = .bgra8Unorm
			renderBufferAttachment.isBlendingEnabled = true
			renderBufferAttachment.rgbBlendOperation = .add
			renderBufferAttachment.alphaBlendOperation = .add
			renderBufferAttachment.sourceRGBBlendFactor = .destinationAlpha
			renderBufferAttachment.sourceAlphaBlendFactor = .destinationAlpha
			renderBufferAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
			renderBufferAttachment.destinationAlphaBlendFactor = .oneMinusBlendAlpha
		}
		
		self.renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
		initializedPipeline = true
		return true
	}
	
	override func willMoveToScene(_ scene: Scene?) {
		initializePipeline()
	}
	
	static var textureLoader:MTKTextureLoader? = nil
	var texture:MTLTexture!
	
	fileprivate var device:MTLDevice!
	
	var vertices:[Vertex] {
		let rect = globalFrame
		let l = rect.minX
		let r = rect.maxX
		let t = rect.maxY
		let b = rect.minY
		
		let points:[CGPoint] = [
			CGPoint(x: l, y: t),
			CGPoint(x: l, y: b),
			CGPoint(x: r, y: b),
			CGPoint(x: l, y: t),
			CGPoint(x: r, y: b),
			CGPoint(x: r, y: t)
		]
		let uvs:[[Float]] = [
			[0, 1],
			[0, 0],
			[1, 0],
			[0, 1],
			[1, 0],
			[1, 1]
		]
		
		let transform = globalTransform
		
		var vertices = [Vertex]()
		for index in 0..<points.count {
			let point = points[index].applying(transform)
			let uv = uvs[index]
			vertices.append(Vertex(x: Float(point.x), y: Float(point.y), z: 0, w: 1, u: uv[0], v: uv[1]))
		}
		
		return vertices
	}
	
	var vertexBuffer:MTLBuffer!
	var uniformsBuffer:MTLBuffer!
	var colorBuffer:MTLBuffer!
	var colorSamplerState: MTLSamplerState!
	var renderPipelineState: MTLRenderPipelineState!
	
	override func render(with context:RenderContext) {
		
		guard initializePipeline() else {
			return
		}
		
		let encoder = context.commandEncoder
		
		let vertexArray = UnsafeMutablePointer<Vertex>(OpaquePointer(vertexBuffer.contents()))
		let vertices = self.vertices
		let vertexOffset = context.bufferIndex * VertextCount
		for index in vertexOffset ..< vertexOffset + VertextCount {
			vertexArray[index] = vertices[index - vertexOffset]
		}
		
		let uniforms = Uniforms(modelViewProjectionMatrix: context.transform)
		
		let uniformsArray = (uniformsBuffer.contents() + 256 * context.bufferIndex).bindMemory(to:Uniforms.self, capacity: 256 / MemoryLayout<Uniforms>.stride)
		uniformsArray[0] = uniforms
		
		let componentArray = (colorBuffer.contents() + 256 * context.bufferIndex).bindMemory(to:Color.self, capacity: 256 / (MemoryLayout<Color>.stride))
		componentArray[0] = color
		
		encoder.setRenderPipelineState(renderPipelineState)
		
		encoder.setVertexBuffer(vertexBuffer, offset: MemoryLayout<Vertex>.size * vertexOffset, at: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 256 * context.bufferIndex, at: 1)
		encoder.setFragmentBuffer(colorBuffer, offset: 256 * context.bufferIndex, at: 2)
		
		encoder.setFragmentTexture(texture, at: 0)
		encoder.setFragmentSamplerState(colorSamplerState, at: 0)
		
		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: VertextCount)
	}
}

// MARK: Texture Cache
extension TextureNode {
	static var textureCache = [String: MTLTexture]()
	class func loadTexture(imageName: String, device: MTLDevice) throws -> MTLTexture? {
		
		if let texture = textureCache[imageName] {
			return texture
		}
		
		guard let image = Image(named: imageName) else { return nil }
		guard let cgImage = TextureNode.convert(image: image) else { return nil }
		
		if TextureNode.textureLoader == nil {
			TextureNode.textureLoader = MTKTextureLoader(device: device)
		}
		
		if let textureLoader = TextureNode.textureLoader {
			let texture = try textureLoader.newTexture(with: cgImage, options: nil)
			textureCache[imageName] = texture
			return texture
		}
		
		return nil
	}
}
