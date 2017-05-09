//
//  GLRenderViewController.swift
//  Metal2D
//
//  Created by Pim Coumans on 14/02/2017.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import GLKit

class GLRenderViewController: GLKViewController {
	
	override func loadView() {
		self.view = GLRenderView(frame: UIScreen.main.bounds, context: EAGLContext(api: .openGLES2))
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.delegate = self
		(self.view as? GLRenderView)?.scene = ExampleScene()
//		let renderView = GLRenderView(frame: view.bounds, context: (view as! GLKView).context)
//		self.view = renderView
//		renderView.delegate = self
//		
//		preferredFramesPerSecond = 60
//		isPaused = false
	}
	
	override func glkView(_ view: GLKView, drawIn rect: CGRect) {
		super.glkView(view, drawIn: rect)
		let context = RenderContext(commandEncoder: nil, transform: GLKMatrix4MakeOrtho(-1, 1, -1, 1, -1, 1), bufferIndex: 0, delta: 0)
		(self.view as? GLRenderView)?.renderBlock?(context)
		// draw tham stuff
//		glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
//		glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
//		print("DRAW!!!")
	}
}

extension GLRenderViewController: GLKViewControllerDelegate {
	func glkViewControllerUpdate(_ controller: GLKViewController) {
	}
	
	func glkViewController(_ controller: GLKViewController, willPause pause: Bool) {
		print("pause?: \(pause)")
	}
}

//extension GLRenderViewController: GLKViewDelegate {
//}
