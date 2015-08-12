//
//  Regift.swift
//  Regift
//
//  Created by Matthew Palmer on 27/12/2014.
//  Copyright (c) 2014 Matthew Palmer. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices
import AVFoundation

public typealias TimePoint = CMTime

public class Regift: NSObject {
    struct Constants {
        static let FileName = "regift.gif"
        static let TimeInterval: Int32 = 600
        static let Tolerance = 0.01
    }
    // Convert the video at the given URL to a GIF, and return the GIF's URL if it was created.
    // The frames are spaced evenly over the video, and each has the same duration.
    // loopCount is the number of times the GIF will repeat. Defaults to 0, which means repeat infinitely.
    // delayTime is the amount of time for each frame in the GIF.
    public class func createGIFFromURL(URL: NSURL, withFrameCount frameCount: Int, delayTime: Float, loopCount: Int = 0, completion: (result: NSURL?) -> Void) {
        
        let fileProperties = [kCGImagePropertyGIFDictionary as String:
            [
            kCGImagePropertyGIFLoopCount as String: loopCount
            ]]
        
        let frameProperties = [kCGImagePropertyGIFDictionary as String:
            [
            kCGImagePropertyGIFDelayTime as String: delayTime
            ]]
        
        let asset = AVURLAsset(URL: URL, options: nil)
        
        // The total length of the movie, in seconds.
        let movieLength = Float(asset.duration.value) / Float(asset.duration.timescale)
        
        // How far along the video track we want to move, in seconds.
        let increment = Float(movieLength) / Float(frameCount)
        
        // Add each of the frames to the buffer
        var timePoints: [TimePoint] = []
        
        for frameNumber in 0 ..< frameCount {
            let seconds: Float64 = Float64(increment) * Float64(frameNumber)
            let time = CMTimeMakeWithSeconds(seconds, Constants.TimeInterval)
            
            timePoints.append(time)
        }
        
        var gifGenerate: dispatch_group_t = dispatch_group_create()
        dispatch_group_enter(gifGenerate)
        
        var gifURL:NSURL!
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            gifURL = Regift.createGIFForTimePoints(timePoints, fromURL: URL, fileProperties: fileProperties, frameProperties: frameProperties, frameCount: frameCount)
            dispatch_group_leave(gifGenerate)

        })
        
        dispatch_group_notify(gifGenerate, dispatch_get_main_queue()) { () -> Void in
            completion(result: gifURL)
        }
        
    }
    
    public class func createGIFForTimePoints(timePoints: [TimePoint], fromURL URL: NSURL, fileProperties: [String: AnyObject], frameProperties: [String: AnyObject], frameCount: Int) -> NSURL? {
        let temporaryFile = NSTemporaryDirectory().stringByAppendingPathComponent(Constants.FileName)
        let fileURL = NSURL(fileURLWithPath: temporaryFile)
        let destination = CGImageDestinationCreateWithURL(fileURL, kUTTypeGIF, frameCount, nil)
        
        if fileURL == nil {
            return nil
        }
        
        let asset = AVURLAsset(URL: URL, options: [NSObject: AnyObject]())
        let generator = AVAssetImageGenerator(asset: asset)
        
        generator.appliesPreferredTrackTransform = true
        let tolerance = CMTimeMakeWithSeconds(Constants.Tolerance, Constants.TimeInterval)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance
     
        var error: NSError?
        for time in timePoints {
            var imageRef:CGImage
            do {
            imageRef = try generator.copyCGImageAtTime(time, actualTime: nil)
            CGImageDestinationAddImage(destination!, imageRef, frameProperties as CFDictionaryRef)
            } catch{
                print("Something bad happened. \(error)")
            }
        }
        
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionaryRef)
        // Finalize the gif
        if !CGImageDestinationFinalize(destination!) {
            print("Failed to finalize image destination")
            return nil
        }
        
        return fileURL
    }
}
