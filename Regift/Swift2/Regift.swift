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

/// Easily convert a video to a GIF. It can convert the whole thing, or you can choose a section to trim out.
///
/// Synchronous Usage:
///
///      let regift = Regift(sourceFileURL: movieFileURL, frameCount: 24, delayTime: 0.5, loopCount: 7)
///      print(regift.createGif())
///
///      // OR
///
///      let trimmedRegift = Regift(sourceFileURL: movieFileURL, startTime: 30, duration: 15, frameRate: 15)
///      print(trimmedRegift.createGif())
///
/// Asynchronous Usage:
///
///      let regift = Regift.createGIFFromSource(movieFileURL, frameCount: 24, delayTime: 0.5, loopCount: 7) { (result) in
///          print(result)
///      }
///
///      // OR
///
///      let trimmedRegift = Regift.createGIFFromSource(movieFileURL, startTime: 30, duration: 15, frameRate: 15) { (result) in
///          print(result)
///      }
///
public struct Regift {

    // Static conversion methods, for convenient and easy-to-use API:

    /**
        Create a GIF from a movie stored at the given URL. This converts the whole video to a GIF meeting the requested output parameters.

        - parameters:
            - sourceFileURL: The source file to create the GIF from.
            - destinationFileURL: An optional destination file to write the GIF to. If you don't include this, a default path will be provided.
            - frameCount: The number of frames to include in the gif; each frame has the same duration and is spaced evenly over the video.
            - delayTime: The amount of time each frame exists for in the GIF.
            - loopCount: The number of times the GIF will repeat. This defaults to `0`, which means that the GIF will repeat infinitely.
            - completion: A block that will be called when the GIF creation is completed. The `result` parameter provides the path to the file, or will be `nil` if there was an error.
    */
    public static func createGIFFromSource(
        sourceFileURL: NSURL,
        destinationFileURL: NSURL? = nil,
        frameCount: Int,
        delayTime: Float,
        loopCount: Int = 0,
        completion: (result: NSURL?) -> Void) {
            let gift = Regift(
                sourceFileURL: sourceFileURL,
                destinationFileURL: destinationFileURL,
                frameCount: frameCount,
                delayTime: delayTime,
                loopCount: loopCount
            )

            completion(result: gift.createGif())
    }

    /**
        Create a GIF from a movie stored at the given URL. This allows you to choose a start time and duration in the source material that will be used to create the GIF which meets the output parameters.

        - parameters:
            - sourceFileURL: The source file to create the GIF from.
            - destinationFileURL: An optional destination file to write the GIF to. If you don't include this, a default path will be provided.
            - startTime: The time in seconds in the source material at which you want the GIF to start.
            - duration: The duration in seconds that you want to pull from the source material.
            - frameRate: The desired frame rate of the outputted GIF.
            - loopCount: The number of times the GIF will repeat. This defaults to `0`, which means that the GIF will repeat infinitely.
            - completion: A block that will be called when the GIF creation is completed. The `result` parameter provides the path to the file, or will be `nil` if there was an error.
    */
    public static func createGIFFromSource(
        sourceFileURL: NSURL,
        destinationFileURL: NSURL? = nil,
        startTime: Float,
        duration: Float,
        frameRate: Int,
        loopCount: Int = 0,
        completion: (result: NSURL?) -> Void) {
            let gift = Regift(
                sourceFileURL: sourceFileURL,
                destinationFileURL: destinationFileURL,
                startTime: startTime,
                duration: duration,
                frameRate: frameRate,
                loopCount: loopCount
            )

            completion(result: gift.createGif())
    }

    private struct Constants {
        static let FileName = "regift.gif"
        static let TimeInterval: Int32 = 600
        static let Tolerance = 0.01
    }

    /// A reference to the asset we are converting.
    private var asset: AVAsset

    /// The url for the source file.
    private let sourceFileURL: NSURL

    /// The point in time in the source which we will start from.
    private var startTime: Float = 0

    /// The desired duration of the gif.
    private var duration: Float

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
    
    /**
        Create a GIF from a movie stored at the given URL. This converts the whole video to a GIF meeting the requested output parameters.

        - parameters:
            - sourceFileURL: The source file to create the GIF from.
            - destinationFileURL: An optional destination file to write the GIF to. If you don't include this, a default path will be provided.
            - frameCount: The number of frames to include in the gif; each frame has the same duration and is spaced evenly over the video.
            - delayTime: The amount of time each frame exists for in the GIF.
            - loopCount: The number of times the GIF will repeat. This defaults to `0`, which means that the GIF will repeat infinitely.
     */
    public init(sourceFileURL: NSURL, destinationFileURL: NSURL? = nil, frameCount: Int, delayTime: Float, loopCount: Int = 0) {
        self.sourceFileURL = sourceFileURL
        self.asset = AVURLAsset(URL: sourceFileURL, options: nil)
        self.movieLength = Float(asset.duration.value) / Float(asset.duration.timescale)
        self.duration = movieLength
        self.delayTime = delayTime
        self.loopCount = loopCount
        self.destinationFileURL = destinationFileURL
        self.frameCount = frameCount
    }

    /**
        Create a GIF from a movie stored at the given URL. This allows you to choose a start time and duration in the source material that will be used to create the GIF which meets the output parameters.

        - parameters:
            - sourceFileURL: The source file to create the GIF from.
            - destinationFileURL: An optional destination file to write the GIF to. If you don't include this, a default path will be provided.
            - startTime: The time in seconds in the source material at which you want the GIF to start.
            - duration: The duration in seconds that you want to pull from the source material.
            - frameRate: The desired frame rate of the outputted GIF.
            - loopCount: The number of times the GIF will repeat. This defaults to `0`, which means that the GIF will repeat infinitely.
     */
    public init(sourceFileURL: NSURL, destinationFileURL: NSURL? = nil, startTime: Float, duration: Float, frameRate: Int, loopCount: Int = 0) {
        self.sourceFileURL = sourceFileURL
        self.asset = AVURLAsset(URL: sourceFileURL, options: nil)
        self.destinationFileURL = destinationFileURL
        self.startTime = startTime
        self.duration = duration

        // The delay time is based on the desired framerate of the gif.
        self.delayTime = (1.0 / Float(frameRate))

        // The frame count is based on the desired length and framerate of the gif.
        self.frameCount = Int(duration * Float(frameRate))

        // The total length of the file, in seconds.
        self.movieLength = Float(asset.duration.value) / Float(asset.duration.timescale)

        self.loopCount = loopCount
    }

    /**
        Get the URL of the GIF created with the attributes provided in the initializer.

        - returns: The path to the created GIF, or `nil` if there was an error creating it.
    */
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
        let increment = Float(duration) / Float(frameCount)
        
        // Add each of the frames to the buffer
        var timePoints: [TimePoint] = []
        
        for frameNumber in 0 ..< frameCount {
            let seconds: Float64 = Float64(startTime) + (Float64(increment) * Float64(frameNumber))
            let time = CMTimeMakeWithSeconds(seconds, Constants.TimeInterval)
            
            timePoints.append(time)
        }
        
        do {
            return try createGIFForTimePoints(timePoints, fileProperties: fileProperties, frameProperties: frameProperties, frameCount: frameCount)
            
        } catch {
            return nil
        }
    }

    /**
        Create a GIF using the given time points in a movie file stored in this Regift's `asset`.
    
        - parameters:
            - timePoints: timePoints An array of `TimePoint`s (which are typealiased `CMTime`s) to use as the frames in the GIF.
            - fileProperties: The desired attributes of the resulting GIF.
            - frameProperties: The desired attributes of each frame in the resulting GIF.
            - frameCount: The desired number of frames for the GIF. *NOTE: This seems redundant to me, as `timePoints.count` should really be what we are after, but I'm hesitant to change the API here.*

        - returns: The path to the created GIF, or `nil` if there was an error creating it.
    */
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
