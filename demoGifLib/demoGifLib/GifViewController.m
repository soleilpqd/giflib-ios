//
//  GifViewController.m
//  demoGifLib
//
//  Created by soleilpqd on 10/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GifViewController.h"
#import <giflib/GifDecode.h>
#import <giflib/giflib_ios.h>

@interface GifViewController() {
	NSString *_gifFile;
	int _renderMode;
	GifPlayback *_gifPlayback;
	CGSize _imageSize;
	int _frameCount;
	CGFloat _animDuration;
	int _error;
}

@end

@implementation GifViewController

- ( void )showError {
	UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:[ NSString stringWithFormat:@"GIF Error %i", _error ]
													  message:[ giflib_ios getErrorDescription:_error ]
													 delegate:nil
											cancelButtonTitle:@"OK"
											otherButtonTitles:nil ];
	[ alert show ];
	[ alert release ];
	[ self.navigationController popViewControllerAnimated:YES ];
}

- ( void )showGifInfo:( id )sender {
	UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:@"GIF info"
													  message:[ NSString stringWithFormat:@"Size: %@\nFrames: %i\nTotal anim duration: %.2fs",
                                                               NSStringFromCGSize( _imageSize), _frameCount, _animDuration ]
													 delegate:nil
											cancelButtonTitle:@"OK"
											otherButtonTitles:nil ];
	[ alert show ];
	[ alert release ];
}

- ( void )setGifFile:( NSString* )name renderMode:( int )rMode {
	self.title = [ name.lastPathComponent stringByDeletingPathExtension ];
	_gifFile =  [ name retain ];
	_renderMode = rMode;
}

// Real time render delegate

- ( void )gifPlayback:(GifPlayback *)sender setImageSize:(CGSize)imageSize {
    _imageSize = imageSize;
    if ( imageSize.width > _imageView.bounds.size.width ||
        imageSize.height > _imageView.bounds.size.height )
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- ( void )gifPlayback:(GifPlayback *)sender setImage:(UIImage *)image {
    _imageView.image = image;
}

- ( void )gifPlaybackloadLoadGifFileDone:(GifPlayback *)sender framesCount:(NSInteger)frCount totalAnimationDuration:(CGFloat)animDuration {
    _frameCount = frCount;
    _animDuration = animDuration;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- ( void )gifPlaybackError:(GifPlayback *)sender error:(NSInteger)code {
    _error = code;
    [ self showError ];
}

// Render 1 time

- ( void )internalLoadGif:( NSString* )gifPath {
    NSAutoreleasePool *pool = [[ NSAutoreleasePool alloc ] init ];
    NSMutableArray *arr = [[ NSMutableArray alloc ] init ];
    NSMutableDictionary *dic = [[ NSMutableDictionary alloc ] init ];
    _error = [ GifDecode decodeGifFramesFromFile:gifPath
                                    storeFramesIn:arr
                                        storeInfo:dic
                                separateFrameOnly:NO ];
    if ( _error == 0) {
        _imageView.image = [ arr objectAtIndex:0 ];
        if ( arr.count > 1 ) {
            _imageView.animationImages = arr;
            _imageView.animationRepeatCount = [[ dic objectForKey:kGifInfoLoopCount ] intValue ];
            _imageView.animationDuration = [[ dic objectForKey:kGifInfoAnimationDuration ] intValue ] / 100.0;
            if ( _imageView.animationDuration == 0 ) _imageView.animationDuration = 0.1 * arr.count;
            [ _imageView startAnimating ];
//            for ( int i = 0; i < arr.count; i++ ) {
//                UIImage *img = [ arr objectAtIndex:i ];
//                NSData *data = UIImagePNGRepresentation( img );
//                [ data writeToFile:[ NSHomeDirectory() stringByAppendingFormat:@"/Library/Caches/%i.png", i ]
//                        atomically:YES ];
//            }
        }
        if ( _imageView.image.size.width > _imageView.bounds.size.width ||
            _imageView.image.size.height > _imageView.bounds.size.height )
            _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageSize = _imageView.image.size;
        _frameCount = arr.count;
        _animDuration = _imageView.animationDuration;
        [ _indicator stopAnimating ];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        [ self performSelectorOnMainThread:@selector( showError ) withObject:nil waitUntilDone:NO ];
    }
    [ arr release ];
    [ dic release ];
    [ pool release ];
}

#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    NSLog( @"Memory warning" );
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- ( void )viewWillDisappear:(BOOL)animated {
    [ super viewWillDisappear:animated ];
    [ _gifPlayback pause ];
}

- ( void )viewWillAppear:(BOOL)animated {
	[ super viewWillAppear:animated ];
	_imageSize = CGSizeZero;
	_frameCount = -1;
    switch ( _renderMode ) {
        case 0:
            [ self performSelectorInBackground:@selector( internalLoadGif: ) withObject:_gifFile ];
            break;
        case 1:
            _gifPlayback = [[ GifPlayback alloc ] initWithGifFile:_gifFile
                                                         delegate:self ];
            [ _indicator stopAnimating ];
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[ UIBarButtonItem alloc ] initWithTitle:@"Info"
																				style:UIBarButtonItemStyleBordered
																			   target:self
																			   action:@selector( showGifInfo: )];
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- ( void )dealloc {
	[ _imageView release ];
	[ _indicator release ];
    [ _gifFile release ];
	if ( _gifPlayback ) {
		[ _gifPlayback release ];
	}
	[ super dealloc ];
}

@end
