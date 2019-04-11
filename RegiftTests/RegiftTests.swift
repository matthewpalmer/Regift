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
    var URL: Foundation.URL!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let testBundle = Bundle(for: type(of: self))
        URL = testBundle.url(forResource: "regift-test-file", withExtension: "mov")
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
        XCTAssertTrue(FileManager.default.fileExists(atPath: result!.path))
        
        let source = CGImageSourceCreateWithURL(result! as CFURL, nil)
        let count = CGImageSourceGetCount(source!)
        let type = CGImageSourceGetType(source!)
        let properties = CGImageSourceCopyProperties(source!, nil)! as NSDictionary
        let fileProperties = properties.object(forKey: kCGImagePropertyGIFDictionary as String) as! NSDictionary
        let loopCount = fileProperties.value(forKey: kCGImagePropertyGIFLoopCount as String) as! Int
        
        XCTAssertEqual(count, 16)
        XCTAssertEqual(type! as NSString, "com.compuserve.gif")
        XCTAssertEqual(loopCount, 0)
        
        (0..<count).forEach { (index) -> () in
            let frameProperties = CGImageSourceCopyPropertiesAtIndex(source!, index, nil)! as NSDictionary
            let gifFrameProperties = frameProperties.object(forKey: kCGImagePropertyGIFDictionary as String)
            print(gifFrameProperties ?? "")
            let delayTime = (gifFrameProperties as! NSDictionary)[kCGImagePropertyGIFDelayTime as String] as! Float
            XCTAssertEqual(delayTime, 0.2)
        }
    }
    
    func testGIFIsSaved() {
        let savedURL = Foundation.URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent("test.gif"))
        let regift = Regift(sourceFileURL: URL, destinationFileURL: savedURL, frameCount: 16, delayTime: 0.2, progress: { (progress) in
            print(progress)
        })
        let result = regift.createGif()
        XCTAssertNotNil(result, "The GIF URL should not be nil")
        
        XCTAssertTrue(savedURL.absoluteString == result?.absoluteString)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result!.path))
        
    }
    
    func testTrimmedGIFIsSaved() {
        
        let savedURL = Foundation.URL(fileURLWithPath: (NSTemporaryDirectory() as NSString).appendingPathComponent("test_trim.gif"))
        let regift = Regift(sourceFileURL: URL, destinationFileURL: savedURL, startTime: 1, duration: 2, frameRate: 15)
        let result = regift.createGif()
        XCTAssertNotNil(result, "The GIF URL should not be nil")
        
        XCTAssertTrue(savedURL.absoluteString == result?.absoluteString)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result!.path))
        
    }
    
    func testGIFIsNotCreated() {
        let regift = Regift(sourceFileURL: Foundation.URL(fileURLWithPath: ""), frameCount: 10, delayTime: 0.5)
        let result = regift.createGif()
        XCTAssertNil(result)
    }
}
