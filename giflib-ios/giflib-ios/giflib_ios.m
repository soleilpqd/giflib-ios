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

#import <UIKit/UIKit.h>
#import "giflib_ios.h"

@implementation giflib_ios

+ ( NSString* )getErrorDescription:( int )errorCode {
	NSString *s;
	switch ( errorCode ) {
		case E_GIF_ERR_OPEN_FAILED:
			s = NSLocalizedString( @"Failed to open given file",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_WRITE_FAILED:
			s = NSLocalizedString( @"Failed to write to given file",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_HAS_SCRN_DSCR:
			s = NSLocalizedString( @"Screen descriptor has already been set",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_HAS_IMAG_DSCR:
			s = NSLocalizedString( @"Image descriptor is still active",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_NO_COLOR_MAP:
			s = NSLocalizedString( @"Neither global nor local color map",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_DATA_TOO_BIG:
			s = NSLocalizedString( @"Number of pixels bigger than width * height",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_NOT_ENOUGH_MEM:
			s = NSLocalizedString( @"Failed to allocate required memory",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_DISK_IS_FULL:
			s = NSLocalizedString( @"Write failed (disk full?)",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_CLOSE_FAILED:
			s = NSLocalizedString( @"Failed to close given file",
								  @"GIF error description" );
			break;
		case E_GIF_ERR_NOT_WRITEABLE:
			s = NSLocalizedString( @"Given file was not opened for write",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_OPEN_FAILED:
			s = NSLocalizedString( @"Failed to open given file",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_READ_FAILED:
			s = NSLocalizedString( @"Failed to read from given file",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_NOT_GIF_FILE:
			s = NSLocalizedString( @"Data is not in GIF format",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_NO_SCRN_DSCR:
			s = NSLocalizedString( @"No screen descriptor detected",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_NO_IMAG_DSCR:
			s = NSLocalizedString( @"No Image Descriptor detected",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_NO_COLOR_MAP:
			s = NSLocalizedString( @"Neither global nor local color map",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_WRONG_RECORD:
			s = NSLocalizedString( @"Wrong record type detected",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_DATA_TOO_BIG:
			s = NSLocalizedString( @"Number of pixels bigger than width * height",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_NOT_ENOUGH_MEM:
			s = NSLocalizedString( @"Failed to allocate required memory",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_CLOSE_FAILED:
			s = NSLocalizedString( @"Failed to close given file",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_NOT_READABLE:
			s = NSLocalizedString( @"Given file was not opened for read",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_IMAGE_DEFECT:
			s = NSLocalizedString( @"Image is defective, decoding aborted",
								  @"GIF error description" );
			break;
		case D_GIF_ERR_EOF_TOO_SOON:
			s = NSLocalizedString( @"Image EOF detected before image complete",
								  @"GIF error description" );
			break;
            // Additional errors
		case GIF_ERROR_FRAME_BOUNDS:
			s = NSLocalizedString( @"Frame is not confined to Image dimension",
								  @"GIF error description" );
			break;
		case GIF_ERROR_MAP_COLOR:
			s = NSLocalizedString( @"No color map found, unable to render image",
								  @"GIF error description" );
			break;
		case GIF_ERROR_OUT_MEMORY:
			s = NSLocalizedString( @"Can not allocate memory",
								  @"GIF error description" );
			break;
        case GIF_ERROR_FILE_ACCESS:
            s = NSLocalizedString( @"Can not read from or write to file",
								  @"GIF error description" );
            break;
		default:
			s = nil;
			break;
    }
	return s;
}

@end