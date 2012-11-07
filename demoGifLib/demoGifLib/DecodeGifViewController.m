//
//  DecodeGifViewController.m
//  demoGifLib
//
//  Created by soleilpqd on 10/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DecodeGifViewController.h"
#import "GifViewController.h"


@interface DecodeGifViewController() {
	NSArray* _images;
    NSArray *_demos;
	int _realTime;
}

@end

@implementation DecodeGifViewController

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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	if ( _images ) [ _images release ];
	_images = [[[ NSFileManager defaultManager ] contentsOfDirectoryAtPath:[[[ NSBundle mainBundle ] bundlePath ]
                                                                            stringByAppendingPathComponent:@"images" ]
																	error:NULL ] retain ];
    if ( _demos ) [ _demos release ];
    _demos = [[[ NSFileManager defaultManager ] contentsOfDirectoryAtPath:[ NSHomeDirectory() stringByAppendingPathComponent:@"Documents" ]
                                                                   error:NULL ] retain ];
	[ self. tableView reloadData ];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ( _demos && _demos.count ) return 3;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ( section ) {
        case 0:
            return 2;
            break;
        case 1:
            return _images.count;
            break;
        case 2:
            return _demos.count;
            break;
    }
    return 0;
}

- ( NSString* )tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return  @"Render type";
            break;
        case 1:
            return @"Files test";
            break;
        case 2:
            return @"Encode test";
            break;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    switch ( indexPath.section ) {
        case 0:
            switch ( indexPath.row ) {
                case 0:
                    cell.textLabel.text = @"1 time";
                    break;
                case 1:
                    cell.textLabel.text = @"Real-time";
                    break;
            }
            cell.accessoryType = _realTime == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case 1:
            cell.textLabel.text = [[ _images objectAtIndex:indexPath.row ] stringByDeletingPathExtension ];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 2:
            cell.textLabel.text = [[ _demos objectAtIndex:indexPath.row ] stringByDeletingPathExtension ];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
    }
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch ( indexPath.section ) {
		case 0:
			_realTime = indexPath.row;
			[ tableView reloadSections:[ NSIndexSet indexSetWithIndex:0 ]
					  withRowAnimation:UITableViewRowAnimationAutomatic ];
			break;
		case 1:
		{
			[ tableView deselectRowAtIndexPath:indexPath animated:NO ];
			GifViewController *controller = [[ GifViewController alloc ] initWithNibName:@"GifViewController"
																				  bundle:nil ];
			[ controller setGifFile:[[ NSBundle mainBundle ] pathForResource:[ _images objectAtIndex:indexPath.row ]
                                                                      ofType:nil
                                                                 inDirectory:@"images" ]
                         renderMode:_realTime ];
			[ self.navigationController pushViewController:controller animated:YES ];
			[ controller release ];
		}
			break;
        case 2:
		{
			[ tableView deselectRowAtIndexPath:indexPath animated:NO ];
			GifViewController *controller = [[ GifViewController alloc ] initWithNibName:@"GifViewController"
																				  bundle:nil ];
			[ controller setGifFile:[ NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", [ _demos objectAtIndex:indexPath.row ]]
                         renderMode:_realTime ];
			[ self.navigationController pushViewController:controller animated:YES ];
			[ controller release ];
		}
            break;
	}
}

@end
