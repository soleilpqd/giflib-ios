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

#import "GifPlayback.h"

@interface GifPlayback() {
    NSMutableArray *_frames;
    NSMutableArray *_framesDelay;
    BOOL _isRendering, _isRunning, _waitForNextFrame;
    int _currentFrame, _loopCount;
}

@end

@implementation GifPlayback

@synthesize monitor = _monitor;
@synthesize defaultFrameDelay = _defaultFrameDelay;
@synthesize defaultLoopCount = _defaultLoopCount;
@synthesize gifFile = _gifFile;

- ( void )setDefaultLoopCount:(NSInteger)defaultLoopCount {
    _defaultLoopCount = defaultLoopCount;
    if ( _loopCount == 0 ) _loopCount = defaultLoopCount;
}

- ( BOOL )isRunning {
    return _isRunning;
}

- ( void )resume {
    if ( _isRunning ) return;
    _isRunning = YES;
    [ self nextFrame ];
}

- ( void )pause {
    _isRunning = NO;
}

#pragma mark - Render delegate

- ( void )nextFrame {
    if ( !_isRunning ) return;
    if ( _frames.count == 0 ) {
        _waitForNextFrame = YES;
        return;
    }
    NSAutoreleasePool *pool = [[ NSAutoreleasePool alloc ] init ];
    _waitForNextFrame = NO;
    _currentFrame++;
    if ( _currentFrame >= _frames.count ) {
        if ( _isRendering ) {
            _waitForNextFrame = YES;
            _currentFrame--;
            return;
        } else {
            _currentFrame = 0;
            if ( _loopCount > 0 ) {
                _loopCount--;
                if ( _loopCount == 0 ) {
                    _loopCount = _defaultLoopCount;
                    _currentFrame = -1;
                    return;
                }
            }
        }
    }
    if ([ _monitor respondsToSelector:@selector( setImage: )]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ _monitor setImage:[ _frames objectAtIndex:_currentFrame ]];
        });
    } else if ([ _monitor respondsToSelector:@selector( gifPlayback:setImage: )]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ _monitor gifPlayback:self setImage:[ _frames objectAtIndex:_currentFrame ]];
        });
    } else {
        [ NSException raise:@"GIF Playback Error" format:@"Monitor not respond to set image method" ];
    }
    if ( !_isRendering && _frames.count == 1 ) // 1 frame, no need to set fire-time
        return;
    float currentDelay = _defaultFrameDelay > 0 ? _defaultFrameDelay :  [[ _framesDelay objectAtIndex:_currentFrame ] intValue ] / 100.0;
    if ( currentDelay == 0 ) currentDelay = 0.1;
    [ self performSelector:@selector( nextFrame ) withObject:nil afterDelay:currentDelay ];
    [ pool release ];
}

- ( void )startRender:( NSString* )gifFile {
    NSAutoreleasePool *pool = [[ NSAutoreleasePool alloc ] init ];
    _waitForNextFrame = _isRendering = _isRunning = YES;
    _loopCount = 0;
    _currentFrame = -1;
    int res = [ GifDecode decodeGifFramesFromFile:gifFile
                                    renderDelegate:self
                                 separateFrameOnly:NO ];
    // Render finish
    _isRendering = NO;
    if ( res == 0) {
        int t = 0;
        for ( NSNumber *num in _framesDelay ) {
            t += [ num intValue ];
        }
        if ([ _monitor respondsToSelector:@selector( gifPlaybackloadLoadGifFileDone:framesCount:totalAnimationDuration: )]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ _monitor gifPlaybackloadLoadGifFileDone:self framesCount:_frames.count totalAnimationDuration:t / 100.0 ];
            });
        }
        if ( _waitForNextFrame )
            [ self nextFrame ];
    } else {
        _isRunning = NO;
        if ([ _monitor respondsToSelector:@selector( gifPlaybackError:error: )]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ _monitor gifPlaybackError:self error:res ];
            });
        }
    }
    [ pool release ];
}

- ( void )setImageSize:(NSValue *)imageSize {
    if ([ _monitor respondsToSelector:@selector( gifPlayback:setImageSize: )]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ _monitor gifPlayback:self setImageSize:[ imageSize CGSizeValue ]];
        });
    }
}

- ( void )setGifFrame:(NSDictionary *)frameInfo {
    [ _frames addObject:[ frameInfo objectForKey:kGifRenderImage ]];
    [ _framesDelay addObject:[ frameInfo objectForKey:kGifRenderFrameDelay ]];
    if ( _waitForNextFrame )
        [ self nextFrame ];
}

- ( void )setLoopCount:(NSNumber *)loopCount {
    if ( _defaultLoopCount < 0 )
        _loopCount = _defaultLoopCount = [ loopCount intValue ];
}

#pragma mark - Life cycle

- ( id )initWithGifFile:( NSString* )gifFile delegate:( id<GifPlaybackDelegate> )monitor {
    if ( self = [ super init ]) {
        self.monitor = monitor;
        _defaultLoopCount = -1;
        _defaultFrameDelay = 0;
        _frames = [[ NSMutableArray alloc ] init ];
        _framesDelay = [[ NSMutableArray alloc ] init ];
        _gifFile = [ gifFile retain ];
        [ self performSelectorInBackground:@selector( startRender: ) withObject:gifFile ];
    }
    return self;
}

- ( void )dealloc {
    _isRendering = NO;
    _isRunning = NO;
    [ NSObject cancelPreviousPerformRequestsWithTarget:self
                                              selector:@selector( startRender: )
                                                object:_gifFile ];
    [ _gifFile release ];
    [ _frames release ];
    [ _framesDelay release ];
    [ _monitor release ];
    [ super dealloc ];
}

@end
