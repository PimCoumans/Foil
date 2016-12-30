//
//  Screen.swift
//  Metal2D
//
//  Created by Pim Coumans on 03/12/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import QuartzCore
#if os(iOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif

class Screen {
	
	let renderView:RenderView
	
	init(renderView:RenderView) {
		self.renderView = renderView
	}
	
    /**
        The bounds of the current screen in clipspace
        - returns: CGRect of screen bounds in clipspace
     */
    var bounds:CGRect {
        var rect = CGRect(origin: .zero, size: screenRatio)
		rect.size.width *= zoomScale * 2
		rect.size.height *= zoomScale * 2
		rect.origin.x = -(rect.width / 2) + offset.x
		rect.origin.y = -(rect.height / 2) + offset.y
		return rect
    }
	
	/**
		The zoom scale of what is displayed of the screen
		1 means the smallest side of the screen shows 1
		unit in both directions of the scene.
	*/
	var zoomScale:CGFloat = 1
	
	/**
		Offset of the screen. Can be used to pan or shake
		the camera
	*/
	var offset:CGPoint = .zero
	
	/**
		Ratio of the screen size with the smallest side being 1
	*/
	fileprivate var screenRatio:CGSize {
		#if os(iOS)
		var nativeScreenSize = UIScreen.main.nativeBounds.size
		if UIApplication.shared.statusBarOrientation.isLandscape {
			nativeScreenSize = CGSize(width: nativeScreenSize.height, height: nativeScreenSize.width)
		}
		#elseif os(OSX)
		let nativeScreenSize = renderView.bounds.size
		#endif			
		let minSide = min(nativeScreenSize.width, nativeScreenSize.height)
		return CGSize(width: nativeScreenSize.width / minSide, height: nativeScreenSize.height / minSide)
	}
}
