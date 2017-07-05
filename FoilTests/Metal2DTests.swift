//
//  Metal2DTests.swift
//  Metal2DTests
//
//  Created by Pim Coumans on 25/11/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import XCTest
@testable import Metal2DiOS

class Metal2DTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNodeBehavior() {
        let scene = Scene()
        let rootNode = Node()
        let firstChild = Node()
        let secondChild = Node()
        
        rootNode.addChild(firstChild)
        scene.addChild(rootNode)
        rootNode.addChild(secondChild)
        XCTAssert(rootNode.children.count == 2)
        for node in rootNode.children {
            XCTAssert(node.scene == scene)
            XCTAssert(node.parent == rootNode)
        }
        
        rootNode.removeFromParent()
        for node in rootNode.children {
            XCTAssert(node.scene == nil)
            XCTAssert(node.parent == rootNode)
        }
        
        firstChild.removeFromParent()
        XCTAssert(rootNode.children.count == 1)
        XCTAssert(firstChild.parent == nil)
        
        secondChild.removeFromParent()
        XCTAssert(rootNode.children.count == 0)
        XCTAssert(secondChild.parent == nil)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
