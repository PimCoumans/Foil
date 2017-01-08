//
//  TextureNode.swift
//  Metal2D
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
	typealias Color = UIColor
#elseif os(OSX)
	import Cocoa
	typealias Image = NSImage
	typealias Color = NSColor
#endif

fileprivate let VertextCount = 6

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
		frame.size.height *= scale.height
		frame.origin.x -= frame.width * anchorPoint.x
		frame.origin.y -= frame.height * anchorPoint.y
		return frame
	}
	
    var image: Image {
		didSet {
			if let cgImage = TextureNode.convert(image: image) {
				self.cgImage = cgImage
			}
		}
	}
	var cgImage: CGImage {
		didSet {
			// Update texture if available
			if let textureLoader = TextureNode.textureLoader {
				self.texture = try! textureLoader.newTexture(with: cgImage, options: nil)
			}
		}
	}
    let size: CGSize
	var color: Color = Color.white
	
	private class func convert(image:Image) -> CGImage? {
		#if os(OSX)
			if let data = image.tiffRepresentation, let imageSource = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(imageSource) > 0 {
				if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
					return cgImage
				}
			}
		#elseif os(iOS)
			if let cgImage = image.cgImage {
				if let context = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
					context.draw(cgImage, in: context.boundingBoxOfClipPath)
					if let newImage = context.makeImage() {
						return newImage
					}
				}
			}
		#endif
		return nil
	}
	
	// Coordinates in global space
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
	
	init?(image:Image, size:CGSize) {
		
		self.image = image
		if let cgImage = TextureNode.convert(image: image) {
			self.cgImage = cgImage
		}
		else {
			return nil
		}
		self.size = size
		
		super.init()
	}
	
	private var initializedPipeline = false
	
	override func willMoveToScene(_ scene: Scene?) {
		guard let renderView = scene?.renderView, let device = renderView.device, initializedPipeline == false else { return }
		
		let vertexSize = MemoryLayout<Vertex>.size
		vertexBuffer = device.makeBuffer(length:vertexSize * VertextCount * MaxBuffers)
		vertexBuffer.label = "vertices"
		
		let uniformsSize = max(MemoryLayout<Uniforms>.size, 256)
		uniformsBuffer = device.makeBuffer(length: uniformsSize * MaxBuffers)
		uniformsBuffer.label = "uniforms"
		
		let colorSize = max(MemoryLayout<Float>.size * 4, 256)
		colorBuffer = device.makeBuffer(length: colorSize * MaxBuffers)
		colorBuffer.label = "colors"
		
		if texture == nil {
			if TextureNode.textureLoader == nil {
				TextureNode.textureLoader = MTKTextureLoader(device: device)
			}
			if let textureLoader = TextureNode.textureLoader {
				texture = try! textureLoader.newTexture(with: cgImage, options: nil)
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
	
	static var textureLoader:MTKTextureLoader? = nil
	var texture:MTLTexture!
	
	fileprivate var device:MTLDevice!
	
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
	
	var vertexBuffer:MTLBuffer!
	var uniformsBuffer:MTLBuffer!
	var colorBuffer:MTLBuffer!
	var colorSamplerState: MTLSamplerState!
	var renderPipelineState: MTLRenderPipelineState!
	
	override func render(with context:RenderContext) {
		
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
		
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0
		
		#if os(OSX)
		if color.numberOfComponents < 4 {
			let white = color.whiteComponent
			red = white
			green = white
			blue = white
			alpha = color.alphaComponent
		}
		else {
			red = color.redComponent
			green = color.greenComponent
			blue = color.blueComponent
			alpha = color.alphaComponent
		}
		#elseif os(iOS)
			if !color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
				color.getWhite(&red, alpha: &alpha)
				green = red
				blue = red
			}
		#endif
		
		let componentArray = (colorBuffer.contents() + 256 * context.bufferIndex).bindMemory(to:Float.self, capacity: 256 / (MemoryLayout<Float>.stride * 4))
		componentArray[0] = Float(red)
		componentArray[1] = Float(green)
		componentArray[2] = Float(blue)
		componentArray[3] = Float(alpha)
		
		encoder.setRenderPipelineState(renderPipelineState)
		
		encoder.setFrontFacing(.counterClockwise)
		encoder.setVertexBuffer(vertexBuffer, offset: MemoryLayout<Vertex>.size * vertexOffset, at: 0)
		encoder.setVertexBuffer(uniformsBuffer, offset: 256 * context.bufferIndex, at: 1)
		encoder.setFragmentBuffer(colorBuffer, offset: 256 * context.bufferIndex, at: 2)
		
		encoder.setFragmentTexture(texture, at: 0)
		encoder.setFragmentSamplerState(colorSamplerState, at: 0)
		
		encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: VertextCount)
    }
}
