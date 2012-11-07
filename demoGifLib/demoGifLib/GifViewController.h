//
//  GifViewController.h
//  demoGifLib
//
//  Created by soleilpqd on 10/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <giflib/GifPlayback.h>

@interface GifViewController : UIViewController <GifPlaybackDelegate> {
	IBOutlet UIImageView *_imageView;
	IBOutlet UIActivityIndicatorView *_indicator;
}

- ( void )setGifFile:( NSString* )name renderMode:( int )rMode;

@end
