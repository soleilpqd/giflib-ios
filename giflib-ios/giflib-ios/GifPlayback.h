/*
 Create by SoleilPQD@gmail.com on 01 Nov 2012
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

#import <Foundation/Foundation.h>
#import "GifDecode.h"

@protocol GifPlaybackDelegate;

@interface GifPlayback : NSObject <GifRenderDelegate>

@property ( nonatomic, retain ) id<GifPlaybackDelegate> monitor;
@property ( nonatomic, assign ) CGFloat defaultFrameDelay;
@property ( nonatomic, assign ) NSInteger defaultLoopCount;
@property ( nonatomic, readonly ) BOOL isRunning;
@property ( nonatomic, readonly ) NSString *gifFile;

- ( id )initWithGifFile:( NSString* )gifFile delegate:( id<GifPlaybackDelegate> )monitor;
- ( void )resume;
- ( void )pause;

@end


@protocol GifPlaybackDelegate <NSObject>
@optional

- ( void )setImage:( UIImage* )image;
- ( void )gifPlayback:( GifPlayback* )sender setImage:( UIImage* )image;

- ( void )gifPlayback:( GifPlayback* )sender setImageSize:( CGSize )imageSize;
- ( void )gifPlaybackloadLoadGifFileDone:( GifPlayback* )sender framesCount:( NSInteger )frCount totalAnimationDuration:( CGFloat )animDuration;
- ( void )gifPlaybackError:( GifPlayback* )sender error:( NSInteger )code;

@end