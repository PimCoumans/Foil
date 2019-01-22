//
//  MetalViewController.swift
//  Foil
//
//  Created by Pim Coumans on 29/12/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import MetalKit
import GLKit

let MaxBuffers = 3

struct RenderContext {
    fileprivate(set) var commandEncoder: MTLRenderCommandEncoder
    fileprivate(set) var transform: GLKMatrix4
    fileprivate(set) var bufferIndex: Int
    fileprivate(set) var delta: Double
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
    var library:MTLLibrary!
    
    let inflightSemaphore = DispatchSemaphore(value: MaxBuffers)
    var bufferIndex = 0
    var commandQueue: MTLCommandQueue!
    
    init(frame frameRect:CGRect) {
        let device = MTLCreateSystemDefaultDevice()
        super.init(frame: frameRect, device: device)
        initializeMetal()
    }
    
    required init(coder: NSCoder) {
        let device = MTLCreateSystemDefaultDevice()
        super.init(coder: coder)
        self.device = device
        initializeMetal()
    }
    
    func initializeMetal() {
        #if os(OSX)
        window?.acceptsMouseMovedEvents = true
        #else
        if #available(iOS 10.3, *) {
            preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        }
        #endif
        library = device?.makeDefaultLibrary()
        commandQueue = device?.makeCommandQueue()
        screen = Screen(renderView: self)
        renderBlock = { [weak self] context in
            Animator.shared.update(with: context)
            if let scene = self?.scene {
                scene.update(with: context)
                scene.renderRecursively(with: context)
            }
        }
        delegate = self
    }
    
    var lastTime: CFAbsoluteTime = 0
    var currentTime: CFAbsoluteTime = 0
    var delta: Double = 0.035
    
    func draw(in view: MTKView) {
        let _ = inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("Could not create new command buffer")
            return
        }
        commandBuffer.label = "Frame command buffer"
        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                strongSelf.inflightSemaphore.signal()
            }
            return
        }
        
        let minFramesPerSecond = 30
        let maxFramesPerSecond = isInteracting || Animator.shared.isRunningAnimations ? preferredFramesPerSecond : minFramesPerSecond
        let minFrameTime = 1 / Double(maxFramesPerSecond)
        
        if bufferIndex == 0 {
            if currentTime == 0 {
                currentTime = CFAbsoluteTimeGetCurrent()
            }
            lastTime = currentTime
            currentTime = CFAbsoluteTimeGetCurrent()
            let totalDelta = currentTime - lastTime
            let maxFrameTime = 1 / Double(minFramesPerSecond)
            delta = max(min(Double(totalDelta / Double(MaxBuffers)), maxFrameTime), minFrameTime)
        }
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {
            
            if let clearColor = scene?.clearColor {
                self.clearColor = MTLClearColorMake(Double(clearColor.red), Double(clearColor.green), Double(clearColor.blue), 1)
            }
            
            #if arch(i386) || arch(x86_64)
            #else
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            #endif
            renderPassDescriptor.colorAttachments[0].clearColor = clearColor
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                let screenBounds = screen.bounds
                let transform = GLKMatrix4MakeOrtho(Float(screenBounds.minX), Float(screenBounds.maxX), Float(screenBounds.minY), Float(screenBounds.maxY), -1, 1)
                
                let renderContext = RenderContext(commandEncoder: renderEncoder, transform:transform, bufferIndex:bufferIndex, delta:delta)
                
                renderBlock?(renderContext)
                
                renderEncoder.endEncoding()
            }
            
            #if os(OSX)
            commandBuffer.present(drawable)
            #else
            commandBuffer.present(drawable, afterMinimumDuration: minFrameTime)
            #endif
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
        return true
    }
    #endif
    
}
