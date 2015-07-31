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
import Dispatch

public typealias TimePoint = CMTime

public class Regift: NSObject {
    struct Constants {
        static let FileName = "regift.gif"
        static let TimeInterval: Int32 = 600
        static let Tolerance = 0.01
    }
    
    /**
    Convert the video at the given URL to a GIF, and return the GIF's URL if it was created.
    
    :param: URL The URL at which the video to be converted to GIF exists
    :param: frameCount Number of frames to extract from the video for use in the GIF. The frames are evenly spaced out and all have the same duration
    :param: delayTime The amount of time for each frame in the GIF.
    :param: loopCount The number of times the GIF will repeat. Defaults to 0, which means repeat infinitely.
    */
    public class func createGIFFromURL(URL: NSURL, withFrameCount frameCount: Int, delayTime: Float, loopCount: Int = 0) -> NSURL? {
        var gifURL: NSURL? = nil
        
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        createGIFAsynchronouslyFromURL(URL, withFrameCount: frameCount, delayTime: delayTime, loopCount: loopCount, progressHandler: nil, completionHandler: {finalURL in
            gifURL = finalURL
            dispatch_group_leave(group);
        })
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        return gifURL
    }
    
    /**
    Ascynchronusly convert the video at the given URL to a GIF, and return the GIF's URL if it was created.
    
    :param: URL The URL at which the video to be converted to GIF exists
    :param: frameCount Number of frames to extract from the video for use in the GIF. The frames are evenly spaced out and all have the same duration
    :param: delayTime The amount of time for each frame in the GIF.
    :param: loopCount The number of times the GIF will repeat. Defaults to 0, which means repeat infinitely.
    :param: progressHandler The closure to be called with the progress of the conversion. It is called with an argument from 0.0 -> 1.0
    :param: completionHandler The closure to be called on completion of the process. If the conversion was successful, an NSURL to the location of the GIF on disk is passed in.
    */
    public class func createGIFAsynchronouslyFromURL(URL: NSURL, withFrameCount frameCount: Int, delayTime: Float, loopCount: Int = 0, progressHandler: (Double -> Void)?, completionHandler: (NSURL? -> Void)?) {
        let fileProperties = [
            kCGImagePropertyGIFDictionary as String :
                [kCGImagePropertyGIFLoopCount as String: loopCount]
        ]
        
        let frameProperties = [
            kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: delayTime]
        ]
        
        let asset = AVURLAsset(URL: URL, options: [NSObject: AnyObject]())
        
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
        Regift.createGIFAsynchronouslyForTimePoints(timePoints, fromURL: URL, fileProperties: fileProperties, frameProperties: frameProperties, frameCount: frameCount, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    public class func createGIFForTimePoints(timePoints: [TimePoint], fromURL URL: NSURL, fileProperties: [String: AnyObject], frameProperties: [String: AnyObject], frameCount: Int) -> NSURL? {
        
        var fileURL: NSURL? = nil
        
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        
        createGIFAsynchronouslyForTimePoints(timePoints, fromURL: URL, fileProperties: fileProperties, frameProperties: frameProperties, frameCount: frameCount, progressHandler: nil, completionHandler: {URL in
            fileURL = URL
            dispatch_group_leave(group)
        })

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        return fileURL
    }
    
    public class func createGIFAsynchronouslyForTimePoints(timePoints: [TimePoint], fromURL URL: NSURL, fileProperties: [String: AnyObject], frameProperties: [String: AnyObject], frameCount: Int, progressHandler: (Double -> Void)?, completionHandler: (NSURL? -> Void)?) -> Void {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let temporaryFile = NSTemporaryDirectory().stringByAppendingPathComponent(Constants.FileName)
            let fileURL = NSURL.fileURLWithPath(temporaryFile, isDirectory: false)

            if fileURL == nil {
                completionHandler?(nil)
                return
            }
            
            let destination = CGImageDestinationCreateWithURL(fileURL!, kUTTypeGIF, frameCount, NSDictionary())
            
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionaryRef)
            let asset = AVURLAsset(URL: URL, options: [NSObject: AnyObject]())
            let generator = AVAssetImageGenerator(asset: asset)
            
            generator.appliesPreferredTrackTransform = true
            let tolerance = CMTimeMakeWithSeconds(Constants.Tolerance, Constants.TimeInterval)
            generator.requestedTimeToleranceBefore = tolerance
            generator.requestedTimeToleranceAfter = tolerance
            
            var error: NSError?
            var generatedImageCount = 0.0
            let generationHandler: AVAssetImageGeneratorCompletionHandler = {[weak generator] (requestedTime: CMTime, image: CGImage!, receivedTime: CMTime, result: AVAssetImageGeneratorResult, err: NSError!) -> Void in
                if let error = err {
                    generator?.cancelAllCGImageGeneration()
                    println("Cancelling CGImage generation due to error: \(error)")
                    completionHandler?(nil)
                }
                else if result == .Succeeded {
                    CGImageDestinationAddImage(destination, image, frameProperties as CFDictionaryRef)
                    
                    generatedImageCount += 1.0
                    let progress =  generatedImageCount / Double(timePoints.count)
                    progressHandler?(progress)
                    
                    if (CMTimeCompare(requestedTime, timePoints.last!) == 0) {
                        if CGImageDestinationFinalize(destination) {
                            completionHandler?(fileURL)
                        }
                        else {
                            println("\(self): Unable to finalize CGImageDestination!")
                            completionHandler?(nil)
                        }
                    }
                }
            }
            
            generator.generateCGImagesAsynchronouslyForTimePoints(timePoints, completionHandler: generationHandler)
        }
    }
}
