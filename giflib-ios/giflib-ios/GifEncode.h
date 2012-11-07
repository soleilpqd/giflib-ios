/**
 Create by SoleilPQD@gmail.com on 05 Nov 2012
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
 This file contains class object to encode UIImage into GIF file.
 Some notes:
    No Global Color Table, each frame has own one.
    Background color will be unvisible color
    Color resolution are max (8).
    Support only 2 extensions: Graphic Control Extension and Application Extension.
    Color Table has always 256 colors which last color is used as unvisible color,
    that means the GIF file always have unvisible (transparent) pixels.
    The input image will be color quantized to fit 255 colors.
 */

#import <Foundation/Foundation.h>

@interface GifEncode : NSObject

// GIF file path
@property ( nonatomic, readonly ) NSString *gifFile;
// Size in pixel of Gif image
@property ( nonatomic, readonly ) CGSize size;
// Last error code
@property ( nonatomic, readonly ) int error;

// Init the encoder, open the destination file, put gif file header, App Extension ....
// If error occurs, it still returns object. Check error code after init
// before continue to use.
- ( id )initWithFile:( NSString* )destinationFile   // Path to write.
          targetSize:( CGSize )imgSize              // Destination Gif image size.
           loopCount:( short )numLoop               // Loop count, 0 to loop forever
                                                    // but many GIF viewer ignores this field.
            optimize:( BOOL )optimize;              // Remove same pixels of image with the current GIF image state
                                                    // (depends on disposal mode) and crop. This helps decrease file size
                                                    // but takes more time and memory
// Put an image as Gif frame
- ( int )putImageAsFrame:( UIImage* )image      // Image.
             frameBounds:( CGRect )bounds       // Position of this frame in the GIF image,
                                                // the image will be draw to fill this rect,
                                                // and the image part which is outside of Gif image will be ignored.
               delayTime:( CGFloat )delay       // Delay time for animation. Unit: second.
            disposalMode:( int )disposal        // Read GIF 89a spec for more detail. Range: 0 - 3.
          alphaThreshold:( CGFloat )threshold;  // GIF does not support alpha channel. Pixel has alpha <= this value
                                                // will be processed as unvisible one. Range: 0.0 - 1.0.

// Close file, should release self after this.
- ( void )close;

@end
