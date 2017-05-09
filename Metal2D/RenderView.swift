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

struct RenderContext {
	fileprivate(set) var commandEncoder: MTLRenderCommandEncoder?
	fileprivate(set) var transform: GLKMatrix4
	fileprivate(set) var bufferIndex: Int
	fileprivate(set) var delta: Double
}

protocol RenderView: class {
	
	var screen: Screen! { get set }
	var scene: Scene? { get set } 
	
	var renderBlock:((_ context:RenderContext)->())? { get set }

	var device: MTLDevice? { get set } // Metal only
	var library:MTLLibrary! { get set } // Metal only
}

extension RenderView {
	
	var device: MTLDevice? {
		return nil
	}
	
	var library: MTLLibrary! {
		return nil
	}
}
