//
//  MetalViewController.swift
//  Metal2D
//
//  Created by Pim Coumans on 29/12/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import MetalKit
import GLKit

let MaxBuffers = 3
let ConstantBufferSize = 1024*1024

struct RenderContext {
	fileprivate(set) var commandEncoder:MTLRenderCommandEncoder
	fileprivate(set) var transform:GLKMatrix4
	fileprivate(set) var bufferIndex:Int
}

class RenderView: MTKView, MTKViewDelegate {
	
	var screen:Screen!
	var scene: Scene? {
		willSet {
			if let scene = scene, scene.renderView == self {
				scene.renderView = nil
			}
		}
		didSet { scene?.renderView = self }
	}
	
	var renderBlock:((_ context:RenderContext)->())?
	let library:MTLLibrary!
	
	let inflightSemaphore = DispatchSemaphore(value: MaxBuffers)
	var bufferIndex = 0
	let commandQueue: MTLCommandQueue!
	
	init(frame frameRect:CGRect) {
		let device = MTLCreateSystemDefaultDevice()
		library = device?.newDefaultLibrary()
		commandQueue = device?.makeCommandQueue()
		super.init(frame: frameRect, device: device)
		initializeMetal()
	}
	
	required init(coder: NSCoder) {
		let device = MTLCreateSystemDefaultDevice()
		library = device?.newDefaultLibrary()
		commandQueue = device?.makeCommandQueue()
		super.init(coder: coder)
		self.device = device
		initializeMetal()
	}
	
	func initializeMetal() {
		#if os(OSX)
			window?.acceptsMouseMovedEvents = true
		#endif
		screen = Screen(renderView: self)
		renderBlock = { [weak self] context in
			if let scene = self?.scene {
				scene.update()
				scene.renderRecursively(with: context)
			}
		}
		delegate = self
	}
	
	func draw(in view: MTKView) {
		// TODO: use timing signatures for rendering ahead
		let _ = inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
		
		let commandBuffer = commandQueue.makeCommandBuffer()
		commandBuffer.label = "Frame command buffer"
		commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
			if let strongSelf = self {
				strongSelf.inflightSemaphore.signal()
			}
			return
		}
		
		if let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {
			
			renderPassDescriptor.colorAttachments[0].texture = drawable.texture
			renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.25, 0.25, 0.25, 1)
			renderPassDescriptor.colorAttachments[0].loadAction = .clear
			renderPassDescriptor.colorAttachments[0].storeAction = .store
			
			let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
			
			let screenBounds = screen.bounds
			let transform = GLKMatrix4MakeOrtho(Float(screenBounds.minX), Float(screenBounds.maxX), Float(screenBounds.maxY), Float(screenBounds.minY), -1, 1)
			
			let renderContext = RenderContext(commandEncoder: renderEncoder, transform:transform, bufferIndex:bufferIndex)
			
			renderBlock?(renderContext)
			
			renderEncoder.endEncoding()
			commandBuffer.present(drawable)
		}
		
		// bufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
		bufferIndex = (bufferIndex + 1) % MaxBuffers
		
		commandBuffer.commit()
	}
	
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		// DO STUFF
	}
	
	
	
	#if os(macOS)
	override var isFlipped: Bool {
		return false
	}
	#endif
	
}
