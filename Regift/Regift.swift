//
//  Regift.swift
//  Regift
//
//  Created by Matthew Palmer on 27/12/2014.
//  Copyright (c) 2014 Matthew Palmer. All rights reserved.
//

#if os(iOS)
import UIKit
import MobileCoreServices
#elseif os(OSX)
import AppKit
#endif

import ImageIO
import AVFoundation

public typealias TimePoint = CMTime

/// Errors thrown by Regift
public enum RegiftError: String, ErrorType {
    case DestinationNotFound = "The temp file destination could not be created or found"
    case SourceFormatInvalid = "The source file does not appear to be a valid format"
    case AddFrameToDestination = "An error occurred when adding a frame to the destination"
    case DestinationFinalize = "An error occurred when finalizing the destination"
}

// Convenience struct for managing dispatch groups.
private struct Group {
    let group = dispatch_group_create()
    func enter() { dispatch_group_enter(group) }
    func leave() { dispatch_group_leave(group) }
    func wait() { dispatch_group_wait(group, DISPATCH_TIME_FOREVER) }
}

/// Easily convert a video to a GIF.
///
/// Usage:
///
///      let regift = Regift(sourceFileURL: movieFileURL, frameCount: 24, delayTime: 0.5, loopCount: 7)
///      print(regift.createGif())
///
public struct Regift {
    private struct Constants {
        static let FileName = "regift.gif"
        static let TimeInterval: Int32 = 600
        static let Tolerance = 0.01
    }

    /// A reference to the asset we are converting.
    private var asset: AVAsset

    /// The url for the source file.
    private let sourceFileURL: NSURL

    /// The total length of the movie, in seconds.
    private var movieLength: Float

    /// The number of frames we are going to use to create the gif.
    private let frameCount: Int

    /// The amount of time each frame will remain on screen in the gif.
    private let delayTime: Float

    /// The number of times the gif will loop (0 is infinite).
    private let loopCount: Int

    /// The destination path for the generated file.
    private var destinationFileURL: NSURL?
    
    /// Create a GIF from a movie stored at the given URL.
    ///
    /// :param: frameCount The number of frames to include in the gif; each frame has the same duration and is spaced evenly over the video.
    /// :param: delayTime The amount of time each frame exists for in the GIF.
    /// :param: loopCount The number of times the GIF will repeat. This defaults to 0, which means that the GIF will repeat infinitely.
    public init(sourceFileURL: NSURL, destinationFileURL: NSURL?, frameCount: Int, delayTime: Float, loopCount: Int = 0) {
        self.sourceFileURL = sourceFileURL
        self.asset = AVURLAsset(URL: sourceFileURL, options: nil)
        self.movieLength = Float(asset.duration.value) / Float(asset.duration.timescale)
        self.delayTime = delayTime
        self.loopCount = loopCount
        self.destinationFileURL = destinationFileURL
        self.frameCount = frameCount
    }
    
    public init(sourceFileURL: NSURL, frameCount: Int, delayTime: Float, loopCount: Int = 0) {
        self.init(sourceFileURL:sourceFileURL, destinationFileURL:nil, frameCount:frameCount, delayTime:delayTime, loopCount:loopCount)
    }
    
    /// Get the URL of the GIF created with the attributes provided in the initializer.
    public func createGif() -> NSURL? {

        let fileProperties = [kCGImagePropertyGIFDictionary as String:[
            kCGImagePropertyGIFLoopCount as String: NSNumber(int: Int32(loopCount))],
            kCGImagePropertyGIFHasGlobalColorMap as String: NSValue(nonretainedObject: true)
        ]
        
        let frameProperties = [
            kCGImagePropertyGIFDictionary as String:[
                kCGImagePropertyGIFDelayTime as String:delayTime
            ]
        ]

        // How far along the video track we want to move, in seconds.
        let increment = Float(movieLength) / Float(frameCount)
        
        // Add each of the frames to the buffer
        var timePoints: [TimePoint] = []
        
        for frameNumber in 0 ..< frameCount {
            let seconds: Float64 = Float64(increment) * Float64(frameNumber)
            let time = CMTimeMakeWithSeconds(seconds, Constants.TimeInterval)
            
            timePoints.append(time)
        }
        
        do {
            return try createGIFForTimePoints(timePoints, fileProperties: fileProperties, frameProperties: frameProperties, frameCount: frameCount)
            
        } catch {
            return nil
        }
    }
    
    /// Create a GIF using the given time points in a movie file stored at the URL provided.
    ///
    /// :param: timePoints An array of `TimePoint`s (which are typealiased `CMTime`s) to use as the frames in the GIF.
    /// :param: URL The URL of the video file to convert
    /// :param: fileProperties The desired attributes of the resulting GIF.
    /// :param: frameProperties The desired attributes of each frame in the resulting GIF.
    public func createGIFForTimePoints(timePoints: [TimePoint], fileProperties: [String: AnyObject], frameProperties: [String: AnyObject], frameCount: Int) throws -> NSURL {
        // Ensure the source media is a valid file.
        guard asset.tracksWithMediaCharacteristic(AVMediaCharacteristicVisual).count > 0 else {
            throw RegiftError.SourceFormatInvalid
        }

        var fileURL:NSURL?
        if self.destinationFileURL != nil {
            fileURL = self.destinationFileURL
        } else {
            let temporaryFile = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(Constants.FileName)
            fileURL = NSURL(fileURLWithPath: temporaryFile)
        }
        
        guard let destination = CGImageDestinationCreateWithURL(fileURL!, kUTTypeGIF, frameCount, nil) else {
            throw RegiftError.DestinationNotFound
        }
        
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionaryRef)
        
        let generator = AVAssetImageGenerator(asset: asset)
        
        generator.appliesPreferredTrackTransform = true
        
        let tolerance = CMTimeMakeWithSeconds(Constants.Tolerance, Constants.TimeInterval)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance

        // Transform timePoints to times for the async asset generator method.
        var times = [NSValue]()
        for time in timePoints {
            times.append(NSValue(CMTime: time))
        }

        // Create a dispatch group to force synchronous behavior on an asynchronous method.
        let gifGroup = Group()
        var dispatchError: Bool = false
        gifGroup.enter()

        generator.generateCGImagesAsynchronouslyForTimes(times, completionHandler: { (requestedTime, image, actualTime, result, error) in
            guard let imageRef = image where error == nil else {
                print("An error occurred: \(error), image is \(image)")
                dispatchError = true
                gifGroup.leave()
                return
            }

            CGImageDestinationAddImage(destination, imageRef, frameProperties as CFDictionaryRef)

            if requestedTime == times.last?.CMTimeValue {
                gifGroup.leave()
            }
        })

        // Wait for the asynchronous generator to finish.
        gifGroup.wait()

        // If there was an error in the generator, throw the error.
        if dispatchError {
            throw RegiftError.AddFrameToDestination
        }
        
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionaryRef)
        
        // Finalize the gif
        if !CGImageDestinationFinalize(destination) {
            throw RegiftError.DestinationFinalize
        }
        
        return fileURL!
    }
}
