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

#import "GifEncode.h"
#include "neuquant32.h"
#include "giflib_ios.h"

@interface GifEncode() {
    GifFileType *_gifFileOut;
    BOOL _optimize;
    CGContextRef _gifContext;
    PixelRGBA *_gifBuffer;
}
// Remove same pixel, return the biggest rect containing visible pixels inside the frame
CGRect optimizeFrame( PixelRGBA *imageBuffer, CGSize imageSize, PixelRGBA *frameBuffer, CGRect frameBounds, Byte alphaThreshold );
// Create new buffer
PixelRGBA *cropImageBuffer( PixelRGBA *imageBuffer, CGSize imageSize, CGRect destinationRect );

@end

@implementation GifEncode

@synthesize gifFile = _gifFile;
@synthesize size = _size;
@synthesize error = _error;

CGRect optimizeFrame( PixelRGBA *imageBuffer, CGSize imageSize, PixelRGBA *frameBuffer, CGRect frameBounds, Byte alphaThreshold ) {
    int maxX = 0;
    int minX = frameBounds.size.width;
    int maxY = 0;
    int minY = frameBounds.size.height;
    for ( int i = 0; i < frameBounds.size.height; i++ ) {
        BOOL lineVisible = NO;
        for ( int j = 0; j < frameBounds.size.width; j++ ) {
            int framePixId = i * frameBounds.size.width + j;
            int imgPixId = ( i + frameBounds.origin.y ) * imageSize.width + ( j + frameBounds.origin.x );
            if (( frameBuffer[framePixId].alpha <= alphaThreshold ) ||
                ( frameBuffer[framePixId].red == imageBuffer[imgPixId].red &&
                 frameBuffer[framePixId].green == imageBuffer[imgPixId].green &&
                 frameBuffer[framePixId].blue == imageBuffer[imgPixId].blue &&
                 imageBuffer[imgPixId].alpha > 0 )) {
                memset( &frameBuffer[framePixId], 0, 4 );
            } else {
                frameBuffer[framePixId].alpha = 0xff;
                if ( j < minX ) minX = j;
                if ( j > maxX ) maxX = j;
                lineVisible = YES;
            }
        }
        if ( lineVisible ) {
            if ( i < minY ) minY = i;
            if ( i > maxY ) maxY = i;
        }
    }
    return  CGRectMake( minX, minY, maxX - minX + 1, maxY - minY + 1 );
}

PixelRGBA *cropImageBuffer( PixelRGBA *imageBuffer, CGSize imageSize, CGRect destinationRect ) {
    PixelRGBA *buf = malloc( destinationRect.size.width * destinationRect.size.height * 4 );
    for ( int i = 0; i < destinationRect.size.height; i++ ) {
        int srcLineId = ( i + destinationRect.origin.y ) * imageSize.width + destinationRect.origin.x;
        int desLineId = i * destinationRect.size.width;
        memcpy( &buf[desLineId], &imageBuffer[srcLineId], destinationRect.size.width * 4 );
    }
    return buf;
}

#pragma mark - Encode

- ( int )putImageAsFrame:( UIImage* )image
             frameBounds:( CGRect )bounds
                delayTime:( CGFloat )delay
             disposalMode:( int )disposal
           alphaThreshold:( CGFloat )threshold {
    if ( _gifFileOut == NULL ) return _error;
    if ( threshold > 1 ) threshold = 1;
    if ( threshold < 0 ) threshold = 0;
    int iThreshold = threshold * 255;
    // Put Graphic Control Extension
    GraphicsControlBlock gce;
    gce.DelayTime = delay * 100;
    gce.DisposalMode = disposal;
    gce.TransparentColor = 255;
    gce.UserInputFlag = 0;
    GifByteType *gceBlock = malloc( 4 );
    EGifGCBToExtension( &gce, gceBlock );
    if ( EGifPutExtension( _gifFileOut, GRAPHICS_EXT_FUNC_CODE, 4, gceBlock ) == GIF_ERROR ) {
        _error = _gifFileOut->Error;
        free( gceBlock );
        return _error;
    }
    free( gceBlock );
    // Visible rect
    CGRect visibleRect = bounds;
    if ( visibleRect.origin.x < 0 ) {
        visibleRect.size.width += visibleRect.origin.x;
        visibleRect.origin.x = 0;
    }
    if ( visibleRect.origin.y < 0 ) {
        visibleRect.size.width += visibleRect.origin.y;
        visibleRect.origin.y = 0;
    }
    if ( visibleRect.origin.x + visibleRect.size.width > _size.width )
        visibleRect.size.width -= (( visibleRect.origin.x + visibleRect.size.width ) - _size.width );
    if ( visibleRect.origin.y + visibleRect.size.height > _size.height ) {
        visibleRect.size.height -= (( visibleRect.origin.y + visibleRect.size.height ) - _size.height );
    }
    // Get bitmap
    Byte *buffer = malloc( visibleRect.size.width * visibleRect.size.height * 4 );
    memset( buffer, 0, visibleRect.size.width * visibleRect.size.height * 4 );
    CGContextRef context = CGBitmapContextCreate( buffer, visibleRect.size.width, visibleRect.size.height,
                                                 8, visibleRect.size.width * 4, CGColorSpaceCreateDeviceRGB(),
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast );
    if ( bounds.origin.x > 0 ) bounds.origin.x = 0;
    if ( bounds.origin.y > 0 ) bounds.origin.y = 0;
    CGContextDrawImage( context, bounds, image.CGImage );
    CGContextRelease( context );
    // optimize
    if ( _optimize ) {
        CGRect aRect = optimizeFrame( _gifBuffer, _size, ( PixelRGBA* )buffer, visibleRect, threshold );
        if ( !CGSizeEqualToSize( aRect.size, visibleRect.size )) { // recreate frame buffer
            PixelRGBA *croppedBuf = cropImageBuffer(( PixelRGBA* )buffer, visibleRect.size, aRect );
            free( buffer );
            buffer = ( Byte* )croppedBuf;
            visibleRect.origin.x += aRect.origin.x;
            visibleRect.origin.y += aRect.origin.y;
            visibleRect.size.width = aRect.size.width;
            visibleRect.size.height = aRect.size.height;
        }
        switch ( disposal ) {
            case DISPOSAL_UNSPECIFIED:
            case DISPOSE_DO_NOT:
                CGContextDrawImage( _gifContext, bounds, image.CGImage );
                break;
            case DISPOSE_BACKGROUND:
                memset( _gifBuffer, 0, _size.width * _size.height * 4 );
                break;
            case DISPOSE_PREVIOUS:
                // Do nothing
                break;
        }
    }
    // Colors quantization
    PixelRGBA colorMap[256];
    colorMap[255].red = colorMap[255].green = colorMap[255].blue = colorMap[255].alpha = 0;
    GifColorType gifColorMap[256];
    double quantization_gamma = 1.8;
    int sample_factor = 1 + visibleRect.size.width * visibleRect.size.height / ( 512 * 512 );
    if (sample_factor > 10) sample_factor = 10;
    initnet( buffer, visibleRect.size.width * 4 * visibleRect.size.height, 255, quantization_gamma );
    learn( sample_factor, FALSE );
    inxbuild();
    getcolormap(( Byte *)colorMap );
    // Convert color map
    for ( int i = 0; i < 256; i++ ) {
        gifColorMap[i].Red      = colorMap[i].red;
        gifColorMap[i].Green    = colorMap[i].green;
        gifColorMap[i].Blue     = colorMap[i].blue;
    }
    ColorMapObject *gifMapObj = GifMakeMapObject( 256, ( GifColorType* )gifColorMap );
    // Frame description
    if ( EGifPutImageDesc( _gifFileOut, visibleRect.origin.x, visibleRect.origin.y,
                          visibleRect.size.width, visibleRect.size.height, NO, gifMapObj ) == GIF_ERROR ) {
        _error = _gifFileOut->Error;
        goto close_context;
    }
    // Frame data
    GifPixelType *rowBuffer = malloc( visibleRect.size.width );
    for ( int i = 0; i < visibleRect.size.height; i++ ) {
        for ( int j = 0; j < visibleRect.size.width; j++ ) {
            int pixId = ( i * visibleRect.size.width + j ) * 4;
            GifPixelType pix = 255;
            int colorId = inxsearch( buffer[pixId+3], buffer[pixId+2], buffer[pixId+1], buffer[pixId] );
            if ( colorMap[colorId].alpha > iThreshold )
                pix = colorId;
            rowBuffer[j] = pix;
        }
        if ( EGifPutLine( _gifFileOut, rowBuffer, visibleRect.size.width ) == GIF_ERROR ) {
            _error = _gifFileOut->Error;
            break;
        }
    }
    free( rowBuffer );
close_context:
    GifFreeMapObject( gifMapObj );
    free( buffer );
    
    return _error;
}

- ( void )close {
    if ( _gifFileOut )
        EGifCloseFile( _gifFileOut );
    _gifFileOut = NULL;
    if ( _optimize ) {
        CGContextRelease( _gifContext );
        free( _gifBuffer );
    }
}

#pragma mark - Life cycle

- ( id )init {
    [ NSException raise:@"GIF Encode error" format:@"Invalid init method" ];
    return nil;
}

- ( id )initWithFile:( NSString* )destinationFile
          targetSize:( CGSize )imgSize
           loopCount:(short)numLoop
            optimize:(BOOL)optimize {
    if ( self = [ super init ]) {
        _gifFileOut = EGifOpenFileName( destinationFile.UTF8String, NO, &_error );
        if ( _gifFileOut == NULL ) return self;
        
        _gifFile = [ destinationFile retain ];
        _size = imgSize;
        
        EGifSetGifVersion( _gifFileOut, YES );
        // Put image description
        if ( EGifPutScreenDesc( _gifFileOut, imgSize.width, imgSize.height, 8, 0, NULL ) == GIF_ERROR ) {
            _error = _gifFileOut->Error;
            EGifCloseFile( _gifFileOut );
            _gifFileOut = NULL;
            return self;
        }
        // put Application Extenstion
        if ( EGifPutExtensionLeader( _gifFileOut, APPLICATION_EXT_FUNC_CODE ) == GIF_ERROR ) {
            _error = _gifFileOut->Error;
            EGifCloseFile( _gifFileOut );
            _gifFileOut = NULL;
            return self;
        }
        if ( EGifPutExtensionBlock( _gifFileOut, 11, "NETSCAPE2.0" ) == GIF_ERROR ) {
            _error = _gifFileOut->Error;
            EGifCloseFile( _gifFileOut );
            _gifFileOut = NULL;
            return self;
        }
        GifByteType appData[3] = {1, numLoop & 0xff, ( numLoop >> 8 ) & 0xff};
        if ( EGifPutExtensionBlock( _gifFileOut, 3, appData ) == GIF_ERROR ) {
            _error = _gifFileOut->Error;
            EGifCloseFile( _gifFileOut );
            _gifFileOut = NULL;
            return self;
        }
        if ( EGifPutExtensionTrailer( _gifFileOut ) == GIF_ERROR ) {
            _error = _gifFileOut->Error;
            EGifCloseFile( _gifFileOut );
            _gifFileOut = NULL;
            return self;
        }
        _optimize = optimize;
        if ( optimize ) {
            _gifBuffer = malloc( imgSize.width * imgSize.height * 4 );
            memset( _gifBuffer, 0, imgSize.width * imgSize.height  * 4 );
            _gifContext = CGBitmapContextCreate( _gifBuffer, imgSize.width, imgSize.height,
                                                8, imgSize.width * 4, CGColorSpaceCreateDeviceRGB(),
                                                kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast );
        }
    }
    return self;
}

- ( void )dealloc {
    if ( _gifFileOut )
        [ self close ];
    [ _gifFile release ];
    [ super dealloc ];
}

@end
