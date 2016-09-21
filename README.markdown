# Regift
Easily convert a video to a GIF on iOS and OSX.

[![Travis](https://travis-ci.org/matthewpalmer/Regift.svg?branch=master)](https://travis-ci.org/matthewpalmer/Regift)
[![Version](https://img.shields.io/cocoapods/v/Regift.svg?style=flat)](http://cocoadocs.org/docsets/Regift)
[![License](https://img.shields.io/cocoapods/l/Regift.svg?style=flat)](http://cocoadocs.org/docsets/Regift)
[![Platform](https://img.shields.io/cocoapods/p/Regift.svg?style=flat)](http://cocoadocs.org/docsets/Regift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

<br />
<br />
<br />

<p align="center">
  🚀
  <br/>
  <br/>

  I also make <a href="http://matthewpalmer.net/rocket" alt="Download Rocket for free" title="Rocket home page">Rocket</a>, an app that gives you Slack-style emoji everywhere on your Mac.

  <br />

  <img alt="Demo image of Rocket" title="Rocket provides better emoji on Macs" src="http://matthewpalmer.net/rocket/screenshot.gif" />
</p>

<br/>
<br />
<br />
<br />

## Installation
### Cocoapods

Regift is available through [CocoaPods](http://cocoapods.org), and requires Swift 2. To install
it, simply add the following line to your Podfile:

    pod "Regift"

### Carthage

Regift is available through [Carthage](https://github.com/Carthage/Carthage).

    github 'matthewpalmer/Regift'

## Quick Start

```swift
import Regift
```

Synchronous GIF creation:

```swift
let videoURL   = ...
let frameCount = 16
let delayTime  = Float(0.2)
let loopCount  = 0    // 0 means loop forever

let regift = Regift(sourceFileURL: videoURL, frameCount: frameCount, delayTime: delayTime, loopCount: loopCount)
print("Gif saved to \(regift.createGif())")

let startTime = Float(30)
let duration  = Float(15)
let frameRate = 15

let trimmedRegift = Regift(sourceFileURL: URL, startTime: startTime, duration: duration, frameRate: frameRate, loopCount: loopCount)
print("Gif saved to \(trimmedRegift.createGif())")
```

Asynchronous GIF creation:

```swift
let videoURL   = ...
let frameCount = 16
let delayTime  = Float(0.2)
let loopCount  = 0    // 0 means loop forever

Regift.createGIFFromSource(videoURL, frameCount: frameCount, delayTime: delayTime) { (result) in
    print("Gif saved to \(result)")
}

let startTime = Float(30)
let duration  = Float(15)
let frameRate = 15

Regift.createGIFFromSource(videoURL, startTime: startTime, duration: duration, frameRate: frameRate) { (result) in
    print("Gif saved to \(result)")
}
```

## Acknowledgements
Thanks to [Rob Mayoff's Gist](https://gist.github.com/mayoff/4969104), without which this library wouldn't exist.

My personal thanks to all of Regift’s contributors:

* caughtinflux
* samuelbeek
* sebyddd
* nakajijapan
* dbburgess
