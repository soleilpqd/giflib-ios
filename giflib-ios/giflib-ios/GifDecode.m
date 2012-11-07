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

#import "GifDecode.h"
#include "giflib_ios.h"

void renderGifRow( PixelRGBA *contextBuffer, GifRowType rowBuffer,
				  GifFileType *gifFile, int rowNum,
                  int transFlag, int transIndex );
int renderGifFrame( GifFileType *gifFile, GifRowType rowBuffer,
                   CGContextRef context, PixelRGBA *contextBuffer,
                   GraphicsControlBlock gcb,
                   CGImageRef *image );
int renderGifFile( NSString *path, NSMutableArray *frames, NSMutableDictionary *gifInfo, id delegate, BOOL seperate );

@implementation GifDecode

#pragma mark - Internal functions

void renderGifRow( PixelRGBA *contextBuffer, GifRowType rowBuffer,
				  GifFileType *gifFile, int rowNum,
                  int transFlag, int transIndex ) {
    int colNum = gifFile->Image.Left;
    int width = gifFile->Image.Width;
    ColorMapObject *colorMap = ( gifFile->Image.ColorMap ? gifFile->Image.ColorMap : gifFile->SColorMap );
    for ( int i = colNum; i < colNum + width; i++ ) {
        GifPixelType pix = rowBuffer[i];
        if ( transFlag == 0 || pix != transIndex ) {
            GifColorType *colorMapEntry = &colorMap->Colors[pix];
            int pixIndex = rowNum * gifFile->SWidth + i;
            contextBuffer[pixIndex].red = colorMapEntry->Red;
            contextBuffer[pixIndex].green = colorMapEntry->Green;
            contextBuffer[pixIndex].blue = colorMapEntry->Blue;
            contextBuffer[pixIndex].alpha = 0xff;
        }
		rowBuffer[i] = transIndex;
    }
}

int renderGifFrame( GifFileType *gifFile, GifRowType rowBuffer,
                   CGContextRef context, PixelRGBA *contextBuffer,
                   GraphicsControlBlock gcb,
                   CGImageRef *image ) {
    Byte *tmp = NULL;
    unsigned long bufferSize = gifFile->SWidth * 4 * gifFile->SHeight;
    int
	InterlacedOffset[] = { 0, 4, 2, 1 },  // The way Interlaced image should.
	InterlacedJumps[] = { 8, 8, 4, 2 };   // be read - offsets and jumps...
    int transFlag = gcb.TransparentColor == NO_TRANSPARENT_COLOR ? 0 : 1;
    int transIndex = gcb.TransparentColor == NO_TRANSPARENT_COLOR ? 0 : gcb.TransparentColor;
    
    if ( DGifGetImageDesc( gifFile ) == GIF_ERROR )
        return gifFile->Error;
    
    // Image Position relative to Screen.
    int row = gifFile->Image.Top;
    int col = gifFile->Image.Left;
    int width = gifFile->Image.Width;
    int height = gifFile->Image.Height;
    if ( gifFile->Image.Left + gifFile->Image.Width > gifFile->SWidth ||
        gifFile->Image.Top + gifFile->Image.Height > gifFile->SHeight)
        return GIF_ERROR_FRAME_BOUNDS;
    
    if ( gifFile->Image.ColorMap == NULL && gifFile->SColorMap == NULL )
        return GIF_ERROR_MAP_COLOR;
    
    // Reset buffer
    for ( int i = 0; i < gifFile->SWidth; i++ ) {
        rowBuffer[i] = transIndex;
    }
    
    if ( gcb.DisposalMode == DISPOSE_PREVIOUS ) {
        tmp = malloc( bufferSize );
        if ( tmp == NULL )
            return GIF_ERROR_OUT_MEMORY;
        memcpy( tmp, contextBuffer, bufferSize );
    }
    
    if ( gifFile->Image.Interlace ) {
        // Need to perform 4 passes on the images:
        for ( int i = 0; i < 4; i++ ) {
            for ( int j = row + InterlacedOffset[i]; j < row + height; j += InterlacedJumps[i] ) {
                if ( DGifGetLine( gifFile, &rowBuffer[col], width ) == GIF_ERROR )
                    return gifFile->Error;
                renderGifRow( contextBuffer, rowBuffer,
                             gifFile, j, transFlag, transIndex );
            }
        }
    } else {
        for ( int i = 0; i < height; i++ ) {
            if ( DGifGetLine( gifFile, &rowBuffer[col], width ) == GIF_ERROR )
                return gifFile->Error;
            renderGifRow( contextBuffer, rowBuffer,
                         gifFile, row, transFlag, transIndex );
            row +=1;
        }
    }
    *image = CGBitmapContextCreateImage( context );
    switch ( gcb.DisposalMode ) {
        case DISPOSE_BACKGROUND:
            memset( contextBuffer, 0, bufferSize );
            break;
        case DISPOSE_PREVIOUS:
            memcpy( contextBuffer, tmp, bufferSize );
            free( tmp );
            tmp = NULL;
            break;
        case DISPOSAL_UNSPECIFIED:
        case DISPOSE_DO_NOT:
        default:
            // Do nothing
            break;
    }
    return 0;
}

int renderGifFile( NSString *path, NSMutableArray *frames, NSMutableDictionary *gifInfo, id delegate, BOOL separate ) {
    int errorCode = 0;
    GifFileType *gifFile = DGifOpenFileName( path.UTF8String, &errorCode );
    if ( gifFile == NULL ) return errorCode;
    
    if ( delegate ) {
        if ([ delegate respondsToSelector:@selector( setImageSize: )])
            [ delegate performSelectorOnMainThread:@selector( setImageSize: )
                                        withObject:[ NSValue valueWithCGSize:CGSizeMake( gifFile->SWidth, gifFile->SHeight )]
                                     waitUntilDone:YES ];
    }
    
    int rowByteSize = gifFile->SWidth * sizeof( GifPixelType );
    GifRowType rowBuffer = ( GifRowType )malloc( rowByteSize );
    if ( rowBuffer == NULL ) {
        errorCode = GIF_ERROR_OUT_MEMORY;
        goto close_gif;
    }
    for ( int i = 0; i < gifFile->SWidth; i++ ) {
        rowBuffer[i] = gifFile->SBackGroundColor;
    }
    
    GifRecordType recordType;
    int frameIndex = 0;
    GraphicsControlBlock gcb;
    gcb.DelayTime = 0;
    gcb.TransparentColor = -1;
    gcb.DisposalMode = separate ? DISPOSE_BACKGROUND : DISPOSAL_UNSPECIFIED;
    if ( frames == nil && delegate == nil ) frames = [ NSMutableArray array ];
    
    unsigned long bufferSize = gifFile->SWidth * gifFile->SHeight * 4; //  4 = SizeOf( PixelRGBA )
    PixelRGBA *contextBuffer = malloc( bufferSize );
    memset( contextBuffer, 0, bufferSize );
    if ( contextBuffer == NULL ) {
        errorCode = GIF_ERROR_OUT_MEMORY;
        goto close_gif;
    }
    CGContextRef context = CGBitmapContextCreate( contextBuffer, gifFile->SWidth, gifFile->SHeight,
                                                 8, 4 * gifFile->SWidth, CGColorSpaceCreateDeviceRGB(),
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast );
    
    /* Scan the content of the GIF file and load the image(s) in: */
    do {
        if ( DGifGetRecordType( gifFile, &recordType ) == GIF_ERROR ) {
            errorCode = gifFile->Error;
            goto close_context;
        }
        
        switch ( recordType ) {
            case EXTENSION_RECORD_TYPE:
            {
                GifByteType *gifExtBuffer;
                int gifExtCode;
                if ( DGifGetExtension( gifFile, &gifExtCode, &gifExtBuffer ) == GIF_ERROR ) {
                    errorCode = gifFile->Error;
                    goto close_context;
                }
                if ( gifExtCode == GRAPHICS_EXT_FUNC_CODE && gifExtBuffer[0] == 4 ) { // Graphic Control Extension block
                    DGifExtensionToGCB( 4, &gifExtBuffer[1], &gcb );
                    if ( gifInfo ) {
                        NSMutableArray *delayDic = [ gifInfo objectForKey:kGifInfoFramesDelay ];
                        if ( delayDic == nil ) {
                            delayDic = [[[ NSMutableArray alloc ] init ] autorelease ];
                            [ gifInfo setObject:delayDic forKey:kGifInfoFramesDelay ];
                        }
                        [ delayDic insertObject:[ NSNumber numberWithInt:gcb.DelayTime ]
                                        atIndex:frameIndex ];
                    }
                    if ( separate )
                        gcb.DisposalMode = DISPOSE_BACKGROUND;
                }
                while ( gifExtBuffer != NULL ) {
                    if ( DGifGetExtensionNext( gifFile, &gifExtBuffer ) == GIF_ERROR )
                        return gifFile->Error;
                    if ( gifExtBuffer && gifExtCode == APPLICATION_EXT_FUNC_CODE && gifExtBuffer[0] == 3 && gifExtBuffer[1] == 1 ) {
                        int loopCount = INT_2_BYTES( gifExtBuffer[2], gifExtBuffer[3] );
                        if ( delegate ) {
                            if ( loopCount > 0 && [ delegate respondsToSelector:@selector( setLoopCount: )])
                                [ delegate performSelectorOnMainThread:@selector( setLoopCount: )
                                                            withObject:[ NSNumber numberWithInt:loopCount ]
                                                         waitUntilDone:YES ];
                        } else if ( gifInfo ) {
                            [ gifInfo setObject:[ NSNumber numberWithInt:loopCount ]
                                         forKey:kGifInfoLoopCount ];
                        }
                    }
                }
            }
                break;
            case IMAGE_DESC_RECORD_TYPE:
            {
                CGImageRef image = NULL;
                errorCode = renderGifFrame( gifFile, rowBuffer, context, contextBuffer, gcb, &image );
                if ( errorCode )
                    goto close_context;
                
                if ( delegate ) {
                    if ( separate ) {
                        CGRect imgRect = CGRectMake( gifFile->Image.Left, gifFile->Image.Top, gifFile->Image.Width, gifFile->Image.Height );
                        CGImageRef frameImage = CGImageCreateWithImageInRect( image, imgRect );
                        [ delegate performSelectorOnMainThread:@selector( setGifFrame: )
                                                    withObject:[ NSDictionary dictionaryWithObjectsAndKeys:
                                                                [ UIImage imageWithCGImage:frameImage ], kGifRenderImage,
                                                                path, kGifRenderPath,
                                                                [ NSNumber numberWithInt:frameIndex ], kGifRenderFrame,
                                                                [ NSNumber numberWithInt:gcb.DelayTime ], kGifRenderFrameDelay,
                                                                [ NSValue valueWithCGRect:imgRect ], kGifRenderBounds, nil ]
                                                 waitUntilDone:YES ];
                        CGImageRelease( frameImage );
                    } else {
                        [ delegate performSelectorOnMainThread:@selector( setGifFrame: )
                                                    withObject:[ NSDictionary dictionaryWithObjectsAndKeys:
                                                                [ UIImage imageWithCGImage:image ], kGifRenderImage,
                                                                path, kGifRenderPath,
                                                                [ NSNumber numberWithInt:frameIndex ], kGifRenderFrame,
                                                                [ NSNumber numberWithInt:gcb.DelayTime ], kGifRenderFrameDelay, nil ]
                                                 waitUntilDone:YES ];
                    }
                } else {
                    if ( separate ) {
                        CGRect imgRect = CGRectMake( gifFile->Image.Left, gifFile->Image.Top, gifFile->Image.Width, gifFile->Image.Height );
                        CGImageRef frameImage = CGImageCreateWithImageInRect( image, imgRect );
                        [ frames addObject:[ UIImage imageWithCGImage:frameImage ]];
                        CGImageRelease( frameImage );
                        if ( gifInfo ) {
                            NSMutableArray *frameBounds = [ gifInfo objectForKey:kGifRenderBounds ];
                            if ( frameBounds == nil ) {
                                frameBounds = [[[ NSMutableArray alloc ] init ] autorelease ];
                                [ gifInfo setObject:frameBounds forKey:kGifRenderBounds ];
                            }
                            CGRect imgRect = CGRectMake( gifFile->Image.Left, gifFile->Image.Top, gifFile->Image.Width, gifFile->Image.Height );
                            [ frameBounds insertObject:[ NSValue valueWithCGRect:imgRect ]
                                               atIndex:frameIndex ];
                        }
                    } else {
                        [ frames addObject:[ UIImage imageWithCGImage:image ]];
                    }
                }
                CGImageRelease( image );
                frameIndex++;
            }
                break;
            case TERMINATE_RECORD_TYPE:
                break;
            default:		    /* Should be trapped by DGifGetRecordType. */
                break;
        }
    } while ( recordType != TERMINATE_RECORD_TYPE );
    
close_context:
    CGContextRelease( context );
    free( contextBuffer );
    if ( gifInfo ) {
        if ( frames.count == 0 ) {
            [ gifInfo removeAllObjects ];
        } else {
            NSMutableArray *delayDic = [ gifInfo objectForKey:kGifInfoFramesDelay ];
            if ( delayDic ) {
                double duration = 0;
                for ( NSNumber *num in delayDic ) {
                    duration += [ num intValue ];
                }
                [ gifInfo setObject:[ NSNumber numberWithDouble:duration ]
                             forKey:kGifInfoAnimationDuration ];
            }
        }
    }
    
close_gif:
    free( rowBuffer );
    DGifCloseFile( gifFile );
    gifFile = NULL;
    return errorCode;
}

#pragma mark - Lib API

+ ( int )decodeGifFramesFromFile:( NSString* )path
                   storeFramesIn:( NSMutableArray* )gifFrames // must not be nil
                       storeInfo:( NSMutableDictionary* )gifInfo
               separateFrameOnly:( BOOL )separate {
    return renderGifFile( path, gifFrames, gifInfo, nil, separate );
}

+ ( int )decodeGifFramesFromFile:( NSString* )path
                  renderDelegate:( id<GifRenderDelegate> )delegate
               separateFrameOnly:( BOOL )separate {
    if ( delegate == nil )
        [ NSException raise:@"GIF render with delegate"
                     format:@"Delegate must not be NIL" ];
    return renderGifFile( path, nil, nil, delegate, separate );
}

@end
