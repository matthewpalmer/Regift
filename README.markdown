# Regift
Easily convert a video to a GIF on iOS.

## Installation
Install the framework ([reference c/o Alamofire](https://github.com/Alamofire/Alamofire))

1. `git submodule add https://github.com/matthewpalmer/Regift.git`
2. Open the newly created folder, 'Regift', in Finder
3. Drag Regift.xcodeproj to the file navigator (left sidebar) of your project
4. Click on your app's target, then click on Build Phases
5. Follow the gif ![Regift convert video to gift in Swift](http://i.imgur.com/cwB8tAI.gif)
6. `import Regift` wherever you need it

## Quick Start
```swift
import Regift
```

```swift
let videoURL   = ...
let frameCount = 16
let delayTime  = 0.2
let loopCount  = 0    // 0 means loop forever

if let gifURL = Regift.createGIFFromURL(videoURL, withFrameCount: frameCount, delayTime: delayTime, loopCount: loopCount) {
    println("Gif saved to \(gifURL)")
}
```

## Acknowledgements
Thanks to [Rob Mayoff's Gist](https://gist.github.com/mayoff/4969104), without which this library wouldn't exist.