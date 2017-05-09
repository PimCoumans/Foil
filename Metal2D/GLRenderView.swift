//
//  GLRenderView.swift
//  Metal2D
//
//  Created by Pim Coumans on 14/02/2017.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import GLKit
import MetalKit

class GLRenderView: GLKView, RenderView {
	internal var library: MTLLibrary!
	internal var device: MTLDevice?

	var renderBlock: ((RenderContext) -> ())?

	var scene: Scene? {
		willSet {
			if let scene = scene, scene.renderView === self {
				scene.renderView = nil
			}
		}
		didSet { scene?.renderView = self }
	}

	var screen: Screen!

	override init(frame: CGRect, context: EAGLContext) {
		super.init(frame: frame, context: context)
		initializeOpenGL()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initializeOpenGL()
	}
	
	func initializeOpenGL() {
		screen = Screen(renderView: self)
		renderBlock = { [weak self] context in
			Animator.shared.update(with: context)
			if let scene = self?.scene {
				scene.update(withContext: context)
				scene.glRenderRecursively(with: context)
			}
		}
	}
}
