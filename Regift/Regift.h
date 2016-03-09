//
//  Regift.h
//  Regift
//
//  Created by Matthew Palmer on 27/12/2014.
//  Copyright (c) 2014 Matthew Palmer. All rights reserved.
//
#import <Foundation/Foundation.h>

#if TARGET_OS_WATCH
#elif TARGET_OS_TV
#elif TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

//! Project version number for Regift.
FOUNDATION_EXPORT double RegiftVersionNumber;

//! Project version string for Regift.
FOUNDATION_EXPORT const unsigned char RegiftVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Regift/PublicHeader.h>


