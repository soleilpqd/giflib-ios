giflib-ios
==========

Wrap Giflib for iOS development.


Create by SoleilPQD@gmail.com

Copyright © 2012 GMO RunSystem
 
License: LGPL
 
This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.
 
This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


Features:
=

- Render Gif file into UIImage object(s) then we can play animation with UIImageView.

- Encode UIImage into Gif file.

For more detail, read comments in header files.


How to use:
=

- Get the Giflib source from giflib.sourceforge.net (I use version 5.0.2).

- Gif Encoding requires pngnq at pngnq.sourceforge.net.

- Import necessary source files directly into your project or make a sub-project like the demo (read file list below for more detail).



Files list:
=

- Giflib source files: dgif_lib.c, egif_lib.c, gif_err.c, gif_font.c, gif_hash.c, gif_hash.h, gif_lib.h, gif_lib_private.h, gifalloc.c.

- Color quantization for encode: neuquant32.*

- giflib_ios.*: error list and descriptions.

- GifDecode.*: render Gif file into UIImage.

- GifEncode.*: encode UIImage into Gif file.

- GifPlayback*: render Gif in real time.
