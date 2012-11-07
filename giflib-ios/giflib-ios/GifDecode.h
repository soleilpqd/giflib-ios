/**
 Create by SoleilPQD@gmail.com on 24 Oct 2012
 Copyright © 2012 GMO RunSystem
 
 License: LGPL
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 3 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

/*
 This file contains functions which render GIF file to UIImage objects.
 */

#import <Foundation/Foundation.h>

#define INT_2_BYTES(a, b)  (( a & 0xff ) | ( b << 8 ))

// Key to get Gif info value from Gif Info NSMutableDictionary

// Number of GIF animation looping (NSNumber of int)
static const NSString *kGifInfoLoopCount        = @"kGifInfoLoopCount";
// Total duration to play all frames (NSNumber of double),
// you should divide this value to 100 to get the duration in seconds
static const NSString *kGifInfoAnimationDuration = @"kGifInfoAnimationDuration";
// Return a NSMutableArray which contains a set of NSNumber of int objects,
// each of object is the delay time of equivalent frame,
// and you should divide to 100 to get value in seconds, too.
static const NSString *kGifInfoFramesDelay      = @"kGifInfoFramesDelay";

// Key for dic return for delegate

// Return a NSNumber of int which is current frame delay
static const NSString *kGifRenderFrameDelay     = @"kGifRenderFrameDelay";
// The path of GIF file
static const NSString *kGifRenderPath           = @"kGifRenderPath";
// The UIImage to display
static const NSString *kGifRenderImage          = @"kGifRenderImage";
// Current frame index (NSNumber of int)
static const NSString *kGifRenderFrame          = @"kGifRenderFrame";
// Current frame bounds (NSValue of CGRect), available with separateFrameOnly = TRUE
// This is also the key to get NSArray of all frames bounds from gifInfo in function 1
static const NSString *kGifRenderBounds         = @"kGifRenderBounds";

@protocol GifRenderDelegate;

@interface GifDecode : NSObject

// Function 1:
// Render Gif frames directly to UIImage objects
+ ( int )decodeGifFramesFromFile:( NSString* )path                  // Path of GIF file,
                   storeFramesIn:( NSMutableArray* )gifFrames       // if nil, will create an autorelease array.
                       storeInfo:( NSMutableDictionary* )gifInfo    // If != nil, this will store info about Gif file (use keys kGifInfo* above).
               separateFrameOnly:( BOOL )separate;                  // If TRUE, draw each frame separately (if you want edit GIF frame),
                                                                    // otherwise, render frame with full pixel allowing UIImageView can play animation.

// Function 2:
// Get GIF frame while decoding is still running,
// should run this in background, don't forget NSAutoreleasePool.
+ ( int )decodeGifFramesFromFile:( NSString* )path
                  renderDelegate:( id<GifRenderDelegate> )delegate
               separateFrameOnly:( BOOL )separate;

@end

@protocol GifRenderDelegate <NSObject>
@required
// The imageDic contains image to display, current frame index, current frame delay time, source file path.
- ( void )setGifFrame:( NSDictionary* )frameInfo;
@optional
// Call when get image size.
- ( void )setImageSize:( NSValue* )imageSize;
// call when find loop count > 0.
- ( void )setLoopCount:( NSNumber* )loopCount;

@end