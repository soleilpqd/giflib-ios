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
 Wrap GifLib API (ver 5.0.2) for iOS SDK
 This file contains common functions of lib.
 */

#import <Foundation/Foundation.h>
#import "gif_lib.h"

typedef struct {
    Byte red;
    Byte green;
    Byte blue;
    Byte alpha;
} PixelRGBA;

// Additional error code. For Gif Lib error, see gif_lib.h
#define GIF_ERROR_OUT_MEMORY    901 // can not alloc memory
#define GIF_ERROR_MAP_COLOR     902 // GIF file has not color map to render
#define GIF_ERROR_FRAME_BOUNDS  903 // Invalid frame bounds
#define GIF_ERROR_FILE_ACCESS   904 // Invalid frame bounds

@interface giflib_ios : NSObject

// Based on GifLib error description, with additional error and Localized support
+ ( NSString* )getErrorDescription:( int )errorCode;

@end