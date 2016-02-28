//
//  RegiftTests.swift
//  RegiftTests
//
//  Created by Matthew Palmer on 27/12/2014.
//  Copyright (c) 2014 Matthew Palmer. All rights reserved.
//

#if os(iOS)
import UIKit
import Regift
#elseif os(OSX)
import AppKit
import RegiftOSX
#endif
import XCTest

import ImageIO

class RegiftTests: XCTestCase {
    var URL: NSURL!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let testBundle = NSBundle(forClass: self.dynamicType)
        URL = testBundle.URLForResource("regift-test-file", withExtension: "mov")
        XCTAssertNotNil(URL)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGIFIsCreated() {

        let regift = Regift(sourceFileURL: URL, frameCount: 16, delayTime: 0.2)
        let result = regift.createGif()
        XCTAssertNotNil(result, "The GIF URL should not be nil")
        XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(result!.path!))
        
        let source = CGImageSourceCreateWithURL(result!, nil)
        let count = CGImageSourceGetCount(source!)
        let type = CGImageSourceGetType(source!)
        let properties = CGImageSourceCopyProperties(source!, nil)! as NSDictionary
        let fileProperties = properties.objectForKey(kCGImagePropertyGIFDictionary as String) as! NSDictionary
        let loopCount = fileProperties.valueForKey(kCGImagePropertyGIFLoopCount as String) as! Int
        
        XCTAssertEqual(count, 16)
        XCTAssertEqual(type! as NSString, "com.compuserve.gif")
        XCTAssertEqual(loopCount, 0)
        
        (0..<count).forEach { (index) -> () in
            let frameProperties = CGImageSourceCopyPropertiesAtIndex(source!, index, nil)! as NSDictionary
            let gifFrameProperties = frameProperties.objectForKey(kCGImagePropertyGIFDictionary as String)
            let delayTime = gifFrameProperties?.valueForKey(kCGImagePropertyGIFDelayTime as String) as! Float
            XCTAssertEqual(delayTime, 0.2)
        }
    }
    
    func testGIFIsNotCreated() {
        let regift = Regift(sourceFileURL: NSURL(), frameCount: 10, delayTime: 0.5)
        let result = regift.createGif()
        XCTAssertNil(result)
    }
}
