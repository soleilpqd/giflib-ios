//
//  EncodeViewController.m
//  demoGifLib
//
//  Created by soleilpqd on 10/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EncodeViewController.h"
#import <giflib/GifEncode.h>
#import <giflib/giflib_ios.h>

@interface EncodeViewController() {
    NSArray *_items;
    UIView *_vwLock;
    UIActivityIndicatorView *_indicator;
}

- ( void )showLockView;
- ( void )dismissLockView;

@end

@implementation EncodeViewController

- ( void )showLockView {
    if ( _vwLock == nil ) {
        _vwLock = [[ UIView alloc ] initWithFrame:self.view.bounds ];
        _indicator = [[ UIActivityIndicatorView alloc ] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge ];
        _vwLock.backgroundColor = [[ UIColor blackColor ] colorWithAlphaComponent:0.5 ];
        _indicator.center = CGPointMake( _vwLock.bounds.size.width / 2, _vwLock.bounds.size.height / 2 );
        [ _vwLock addSubview:_indicator ];
    }
    [ self.view addSubview:_vwLock ];
    [ _indicator startAnimating ];
}

- ( void )dismissLockView {
    [ _vwLock removeFromSuperview ];
    [ _indicator stopAnimating ];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    _items = [[[ NSFileManager defaultManager ] contentsOfDirectoryAtPath:[[[ NSBundle mainBundle ] bundlePath ] stringByAppendingPathComponent:@"frames" ]
                                                                    error:NULL ] retain ];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait( interfaceOrientation );
}

- ( void )dealloc {
    [ _items release ];
    if ( _vwLock ) {
        [ _vwLock release ];
        [ _indicator release ];
    }
    [ super dealloc ];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    NSString *s = [ _items objectAtIndex:indexPath.row ];
    cell.textLabel.text = s.stringByDeletingPathExtension;
    NSBundle *bundle = [ NSBundle bundleWithPath:[[[ NSBundle mainBundle ] bundlePath ] stringByAppendingFormat:@"/frames/%@", s ]];
    cell.imageView.image = [ UIImage imageWithContentsOfFile:[ bundle pathForResource:@"0" ofType:@"png" ]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [ tableView deselectRowAtIndexPath:indexPath animated:YES ];
    NSString *s = [ _items objectAtIndex:indexPath.row ];
    NSBundle *bundle = [ NSBundle bundleWithPath:[[[ NSBundle mainBundle ] bundlePath ] stringByAppendingFormat:@"/frames/%@", s ]];
    NSArray *arr = [[ NSFileManager defaultManager ] contentsOfDirectoryAtPath:bundle.bundlePath
                                                                         error:NULL ];
    UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:@"Encode confirm"
                                                      message:[ NSString stringWithFormat:@"Encode %i frames of \"%@\"?", arr.count, s.stringByDeletingPathExtension ]
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"OK", nil ];
    alert.tag = indexPath.row;
    [ alert show ];
    [ alert release ];
}

- ( void )alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ( buttonIndex ) {
        [ self showLockView ];
        [ self performSelectorInBackground:@selector( startEncodeWithBundleName: )
                                withObject:[ _items objectAtIndex:alertView.tag ]];
    }
}

- ( void )startEncodeWithBundleName:( NSString* )bundleName {
    NSAutoreleasePool *pool = [[ NSAutoreleasePool alloc ] init ];
    NSFileManager *fileMan = [ NSFileManager defaultManager ];
    NSBundle *bundle = [ NSBundle bundleWithPath:[[[ NSBundle mainBundle ] bundlePath ] stringByAppendingFormat:@"/frames/%@", bundleName ]];
    UIImage *image = [ UIImage imageWithContentsOfFile:[ bundle pathForResource:@"0"
                                                                         ofType:@"png" ]];
    
    GifEncode *encoder = [[ GifEncode alloc ] initWithFile:[ NSHomeDirectory() stringByAppendingString:@"/Library/Caches/temp.gif" ]
                                                targetSize:image.size
                                                 loopCount:0
                                                  optimize:YES ];
    if ( encoder.error == 0 ) {
        NSLog( @"Encode frame 0" );
        [ encoder putImageAsFrame:image
                      frameBounds:CGRectMake( 0, 0, image.size.width, image.size.height )
                        delayTime:0.3
                     disposalMode:DISPOSE_DO_NOT
                   alphaThreshold:0.5 ];
        if ( encoder.error != 0 ) {
            [ self showError:encoder.error ];
            [ encoder release ];
            [ pool release ];
            return;
        }
        NSArray *arr = [ fileMan contentsOfDirectoryAtPath:bundle.bundlePath
                                                     error:NULL ];
        for ( int i = 1; i < arr.count; i++ ) {
            NSLog( @"Encode frame %i", i );
            image = [ UIImage imageWithContentsOfFile:[ bundle pathForResource:[ NSString stringWithFormat:@"%i", i ]
                                                                                 ofType:@"png" ]];
            [ encoder putImageAsFrame:image
                          frameBounds:CGRectMake( 0, 0, image.size.width, image.size.height )
                            delayTime:0.1
                         disposalMode:DISPOSE_DO_NOT
                       alphaThreshold:0.5 ];
            if ( encoder.error != 0 ) {
                [ self showError:encoder.error ];
                [ encoder release ];
                [ pool release ];
                return;
            }
        }
        [ encoder close ];
        NSString *lastPath = [ NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@.gif", bundleName.stringByDeletingPathExtension ];
        if ([ fileMan fileExistsAtPath:lastPath ]) [ fileMan removeItemAtPath:lastPath error:NULL ];
        [ fileMan moveItemAtPath:encoder.gifFile
                          toPath:lastPath
                           error:NULL ];
        [ encoder release ];
        [ self performSelectorOnMainThread:@selector( dismissLockView )
                                withObject:nil
                             waitUntilDone:NO ];
    } else {
        [ self showError:encoder.error ];
        [ encoder release ];
    }
    [ pool release ];
}

- ( void )showError:( int )errCode {
    UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:@"Error while encode"
                                                      message:[ giflib_ios getErrorDescription:errCode ]
                                                     delegate:nil
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:nil ];
    [ alert show ];
    [ alert release ];
    [ self performSelectorOnMainThread:@selector( dismissLockView )
                            withObject:nil
                         waitUntilDone:NO ];
}

@end
