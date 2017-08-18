#import "MainWindowController.h"
#import "GraphicView.h"
#import "ACSDrawDocument.h"
#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "ACSDGraphic.h"
#import "TOCController.h"
#import "ACSDText.h"
#import "AffineTransformAdditions.h"
#import "ACSDPrefsController.h"
#import "ACSDFieldEditor.h"
#import "NSView+Additions.h"
#import <QuartzCore/QuartzCore.h>
#import "ACSDPathElement.h"

NSRect ConstrainRectToRect(NSRect littleRect,NSRect bigRect);
NSRect CentreRectInRect(NSRect movableRect,NSRect fixedRect);
CGAffineTransform transformForOrientation(int orientation,float scale,float width,float height);
int orientationOfSource(NSDictionary *properties);

@implementation MainWindowController

- (id)initWithPages:(NSMutableArray*)list
   {
	if ((self = [super initWithWindowNibName:@"MainWindow"]))
	   {
		[self setShouldCloseDocument:YES];
		pages = [list retain];
		printing = NO;
		viewNumber = -1;
	   }
	return self;
   }

- (void)dealloc
{
	[pages release];
	[_scaleSheet release];
	[_rotateSheet release];
	[_abslinkSheet release];
	[_docSizeSheet release];
	[_genTextSheet release];
	[super dealloc];
}

-(void)setViewNumber:(int)vn
   {
	viewNumber = vn;
   }

- (GraphicView*)graphicView
   {
	return graphicView;
   }
   
- (NSUndoManager*)undoManager
   {
	return [[self document]undoManager];
   }

NSRect ConstrainRectToRect(NSRect littleRect,NSRect bigRect)
{
	if (littleRect.origin.x < 0)
		littleRect.origin.x = 0;
	if (littleRect.origin.y < 0)
		littleRect.origin.y = 0;
	if (NSMaxX(littleRect) > NSMaxX(bigRect))
	{
		float diff = NSMaxX(littleRect) - NSMaxX(bigRect);
		if (littleRect.origin.x > 0)
		{
			float fudge = fminf(littleRect.origin.x, diff);
			littleRect.origin.x -= fudge;
			diff -= fudge;
		}
		littleRect.size.width -= diff;
	}
	if (NSMaxY(littleRect) > NSMaxY(bigRect))
	{
		float diff = NSMaxY(littleRect) - NSMaxY(bigRect);
		if (littleRect.origin.y > 0)
		{
			float fudge = fminf(littleRect.origin.y, diff);
			littleRect.origin.y -= fudge;
			diff -= fudge;
		}
		littleRect.size.height -= diff;
	}
	return littleRect;
}

NSRect CentreRectInRect(NSRect movableRect,NSRect fixedRect)
{
	float dx = NSMidX(fixedRect) - NSMidX(movableRect);
	float dy = NSMidY(fixedRect) - NSMidY(movableRect);
	return NSOffsetRect(movableRect, dx, dy);
}

- (void)adjustWindowSize
{
	NSRect oldFrame = [[graphicView window]frame];
	NSScrollView *scrollView = [graphicView enclosingScrollView];
    NSSize gvSize = [graphicView frame].size;
    NSSize gvScale = [graphicView scale];
    gvSize.width *= gvScale.width;
    gvSize.height *= gvScale.height;
	NSSize frameS = [NSScrollView frameSizeForContentSize:gvSize horizontalScrollerClass:[NSScroller class] verticalScrollerClass:[NSScroller class] borderType:[scrollView borderType] controlSize:NSRegularControlSize scrollerStyle:[[scrollView horizontalScroller]scrollerStyle]];
/*	NSSize frameS = [NSScrollView frameSizeForContentSize:([graphicView frame].size)
									hasHorizontalScroller:[scrollView hasHorizontalScroller]
									  hasVerticalScroller: [scrollView hasVerticalScroller]
											   borderType:[scrollView borderType]];*/
	NSRect frameR = NSMakeRect(0.0,0.0,frameS.width,frameS.height);
	frameR = [NSWindow frameRectForContentRect:frameR styleMask:[[graphicView window]styleMask]];
	[[graphicView window]setMaxSize:frameR.size];
	frameR = CentreRectInRect(frameR, oldFrame);
//	frameR.origin = oldFrame.origin;
//	frameR.origin.y = NSMaxY(oldFrame) - frameR.size.height;
	frameR = ConstrainRectToRect(frameR, [[[graphicView window]screen]visibleFrame]);
	[[graphicView window]setFrame:frameR display:YES];
	//	NSClipView *cv = [scrollView contentView];
	//	NSRect clipBounds = [cv bounds];
	//	NSRect frame = [graphicView frame];
	//	if ((frame.size.width < clipBounds.size.width) || (frame.size.height < clipBounds.size.height))
	//		[[self window]zoom:self];
}
   
- (void)windowWillLoad
   {
	if ([[self document]fileURL])
		[self setShouldCascadeWindows:NO];
   }

- (void)windowDidLoad
{
	[graphicView setDocumentBased:YES];
	[graphicView setPages:pages];
	if ([[[self document]strokes]count] >= 3)
		[graphicView setDefaultStroke:[[[self document]strokes]objectAtIndex:2]];
	else
		[graphicView setDefaultStroke:[[[self document]strokes]objectAtIndex:[[[self document]strokes]count]-1]];
	[graphicView setDefaultFill:[[[self document]fills]objectAtIndex:1]];
	[graphicView setPostsBoundsChangedNotifications:YES];
	[graphicView setPostsFrameChangedNotifications:YES];
	[graphicView setFrameSize:[[self document] documentSize]];
	[graphicView setBoundsSize:[[self document] documentSize]];
	if ([[[self document]fileURL]path])
		[[self window] setFrameUsingName:[[[self document]fileURL]path]];
	[self adjustWindowSize];
	[graphicView setNeedsDisplay:YES];
	[[self window]setAcceptsMouseMovedEvents:YES];
	[graphicView resizeHandleBits];
    NSMutableArray *arr = [NSMutableArray arrayWithObjects:@"acsd",@"svg", nil];
    [arr addObjectsFromArray:[NSPasteboard typesFilterableTo:NSTIFFPboardType]];
    [arr addObject:NSFilenamesPboardType];
    [arr addObject:NSURLPboardType];
    [graphicView registerForDraggedTypes:arr];
	/*[graphicView registerForDraggedTypes:[[[@[ACSDrawGraphicPasteboardType,ACSDrawGraphicRefPasteboardType,@"acsd",@"svg"]
											arrayByAddingObjectsFromArray:[NSPasteboard typesFilterableTo:NSTIFFPboardType]]arrayByAddingObject:NSFilenamesPboardType]arrayByAddingObject:NSURLPboardType]];*/
	[[NSNotificationCenter defaultCenter] addObserver:graphicView selector:@selector(cancelOp:)
												 name:ACSDCancelOpNotification object:[self document]];
	[[NSNotificationCenter defaultCenter] addObserver:graphicView selector:@selector(backgroundChanged:)
												 name:ACSDrawDocumentBackgroundDidChangeNotification object:[self document]];
}

- (BOOL)shouldCloseDocument
   {
	NSArray *controllers = [[self document]windowControllers];
	int count = 0;
	for (unsigned i = 0;i < [controllers count];i++)
	   {
		NSWindowController *cont = [controllers objectAtIndex:i];
		if ([cont isMemberOfClass:[MainWindowController class]])
			count++;
	   }
	return count == 1;
   }

- (void)windowWillClose:(NSNotification *)aNotification
   {
    if ([aNotification object]!= [self window])
        return;
	NSArray *controllers = [[self document]windowControllers];
	for (unsigned i = 0;i < [controllers count];i++)
	   {
		NSWindowController *cont = [controllers objectAtIndex:i];
		if (cont != self && ![cont isMemberOfClass:[MainWindowController class]])
		   {
//			if ([cont windowShouldClose:self])
				[[cont window]close];
//			else
//				return NO;
		   }
	   }
//	return [super windowShouldClose:sender];
   }

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)sender
   {
	return [self undoManager];
   }

- (void)windowDidMove:(NSNotification *)aNotification
{
    if ([aNotification object]!= [self window])
        return;
    NSString *fname = [[[self document]fileURL]path];
    if (fname == nil)
        fname = @"__unsaved";
    [[self window] saveFrameUsingName:fname];
}

- (void)windowDidResize:(NSNotification *)aNotification
{
    if ([aNotification object]!= [self window])
        return;
    NSString *fname = [[[self document]fileURL]path];
    if (fname == nil)
        fname = @"__unsaved";
    [[self window] saveFrameUsingName:fname];
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
    static ACSDFieldEditor *fe = nil;
    if (fe == nil)
    {
        fe = [[ACSDFieldEditor alloc]init];
        [fe setFieldEditor:YES];
    }
    if (client == docSizeWidth || client == docSizeHeight)
        return fe;
    return nil;
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation  success:(BOOL)success  contextInfo:(void *)contextInfo
   {
	printing = NO;
   }

- (void)printDocument:(id)sender
   {
    NSPrintInfo *printInfo = [[self document] printInfo];
	[printInfo setVerticallyCentered:YES];
	float temp = [printInfo topMargin];
	if (!(temp < 100))
		[printInfo setTopMargin:72];
	//temp = [printInfo topMargin];
	printing = YES;
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:graphicView printInfo:printInfo];
	[op runOperationModalForWindow:[self window]
						  delegate:self
					didRunSelector:@selector(printOperationDidRun:success:contextInfo:)
					   contextInfo:NULL];
   }

- (NSData*)epsRepresentation
   {
	NSSize sz = [[self document]documentSize];
	return [graphicView dataWithEPSInsideRect:NSMakeRect(0,0,sz.width,sz.height)];
   }

- (NSData*)pdfRepresentation
   {
	NSSize sz = [[self document]documentSize];
	NSData *d = [graphicView dataWithPDFInsideRect:NSMakeRect(0,0,sz.width,sz.height)];
	return d;
   }

NSMutableSet *checkSet;
/*
CGColorSpaceRef CreateICCColorSpaceFromPathToProfile (const char * iccProfilePath) 
{
	CMProfileRef    iccProfile = (CMProfileRef) 0;
	CGColorSpaceRef iccColorSpace = NULL;
	CMProfileLocation loc;
	
	// Specify that the location of the profile will be a POSIX path to the profile.
	loc.locType = cmPathBasedProfile;
	
	// Make sure the path is not larger then the buffer
	if(strlen(iccProfilePath) > sizeof(loc.u.pathLoc.path))
		return NULL;
	
	// Copy the path the profile into the CMProfileLocation structure
	strcpy (loc.u.pathLoc.path, iccProfilePath);
	
	// Open the profile
	if (CMOpenProfile(&iccProfile, &loc) != noErr)
	{
		iccProfile = (CMProfileRef) 0;
		return NULL;
	}
	
	// Create the ColorSpace with the open profile.
	iccColorSpace = CGColorSpaceCreateWithPlatformColorSpace( iccProfile );
	
	// Close the profile now that we have what we need from it.
	CMCloseProfile(iccProfile);
	
	return iccColorSpace;
}

CGColorSpaceRef CreateColorSpaceFromSystemICCProfileName(CFStringRef profileName) 
{
	FSRef pathToProfilesFolder;
    FSRef pathToProfile;
	
	// Find the Systems Color Sync Profiles folder
	if(FSFindFolder(kOnSystemDisk, kColorSyncProfilesFolderType,
					kDontCreateFolder, &pathToProfilesFolder) == noErr) 
	{
		// Make a UniChar string of the profile name
		UniChar uniBuffer[sizeof(CMPathLocation)];
		CFStringGetCharacters (profileName,CFRangeMake(0,CFStringGetLength(profileName)),uniBuffer);
		
		// Create a FSRef to the profile in the Systems Color Sync Profile folder
		if(FSMakeFSRefUnicode (&pathToProfilesFolder,CFStringGetLength(profileName),uniBuffer,
							   kUnicodeUTF8Format,&pathToProfile) == noErr) 
		{
			char path[sizeof(CMPathLocation)];
			// Write the posix path to the profile into our path buffer from the FSRef
			if(FSRefMakePath (&pathToProfile,path,sizeof(CMPathLocation)) == noErr)
				return CreateICCColorSpaceFromPathToProfile(path);
		}
	}
	
	return NULL;
}
*/
CGColorSpaceRef getRGBColorSpace()
{
	static CGColorSpaceRef genericRGBColorSpace = NULL;
	if (genericRGBColorSpace == NULL)
	{
		genericRGBColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	}
	return genericRGBColorSpace;
}

- (void)writePDFRepresentationToURL:(NSURL*)url
   {
	NSSize sz = [[self document]documentSize];
	CGRect pageRect = CGRectMake(0.0,0.0,sz.width,sz.height); 
    CGContextRef pdfContext;
    //CFURLRef url;
    //url = CFURLCreateWithFileSystemPath (NULL,(CFStringRef)fileName,kCFURLPOSIXPathStyle, 0);
    pdfContext = CGPDFContextCreateWithURL ((CFURLRef)url,&pageRect,(CFDictionaryRef)[NSDictionary dictionaryWithObject:@"ACSDraw" forKey:(__bridge NSString*)kCGPDFContextCreator]);
	//CFRelease(url);
	NSMutableDictionary *substitutions = [NSMutableDictionary dictionaryWithCapacity:5];
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:pdfContext flipped:YES]];
	CIContext *ciContext = [[[NSGraphicsContext currentContext]CIContext]retain];
	checkSet = [NSMutableSet setWithCapacity:100];
	for (unsigned i = 0;i < [pages count];i++)
	   {
		ACSDPage *page = [pages objectAtIndex:i];
		if ([page pageType] != PAGE_TYPE_MASTER)
		   {
			CGContextBeginPage (pdfContext, &pageRect);
			[NSGraphicsContext saveGraphicsState];
			CGContextSetFillColorSpace(pdfContext,getRGBColorSpace());
			CGContextSetStrokeColorSpace(pdfContext,getRGBColorSpace());
			[graphicView drawPage:page rect:[graphicView bounds] drawingToScreen:NO drawMarkers:NO drawingToPDF:pdfContext substitutions:substitutions
                    options:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:@"overrideScale"]];
			NSLog(@"Page %ld",[page pageNo]);
			[NSGraphicsContext restoreGraphicsState];
			[page addLinksForPDFContext:pdfContext];
			CGContextEndPage (pdfContext);
		   }
	   }
	[NSGraphicsContext setCurrentContext:currentContext];
	[ciContext release];
	CGContextRelease (pdfContext);
   }

NSBitmapImageRep *newBitmap(int width,int height)
{
	NSBitmapImageRep *bm = [[NSBitmapImageRep alloc]initWithBitmapDataPlanes:nil pixelsWide:width pixelsHigh:height
															   bitsPerSample:8
															 samplesPerPixel:4 
																	hasAlpha:YES
																	isPlanar:NO
															  colorSpaceName:NSCalibratedRGBColorSpace
																 bytesPerRow:0 
																bitsPerPixel:0];
	return [bm autorelease];
}

-(CGImageRef)cgImageFromCurrentPageOfSize:(NSSize)sz
{
	return [[graphicView imageFromCurrentPageOfSize:sz] CGImageForProposedRect:NULL context:nil hints:nil];
}

-(CGImageRef)cgImageFromCurrentPageSelectionOnlyDrawSelectionOnly:(BOOL)drawSelectionOnly
{
    NSRect r = [self rectCroppedToOpaqueSelectionOnly:YES drawSelectionOnly:drawSelectionOnly];
    r = NSZeroRect;
    for (ACSDGraphic *g in [[graphicView currentEditableLayer]selectedGraphics])
    {
        NSRect b = [g bounds];
        if (NSEqualRects(r,NSZeroRect))
            r = b;
        else
            r = NSUnionRect(r, b);
    }
    NSSize sz = r.size;
	NSBitmapImageRep *bm = newBitmap(sz.width,sz.height);
	NSImage *im = [[[NSImage alloc]initWithSize:sz]autorelease];
	[im addRepresentation:bm];
	[im lockFocusFlipped:YES];
	NSRect b = [graphicView bounds];
    [[NSAffineTransform transformWithTranslateXBy:0 yBy:b.size.height]concat];
    [[NSAffineTransform transformWithScaleXBy:1.0 yBy:-1.0]concat];
    [[NSAffineTransform transformWithTranslateXBy:-r.origin.x yBy:b.size.height - (r.origin.y + r.size.height)]concat];
	[graphicView drawPage:[graphicView currentPage] rect:b drawingToScreen:NO drawMarkers:NO
			 drawingToPDF:nil substitutions:[NSMutableDictionary dictionaryWithCapacity:5] 
                  options:@{@"selectionOnly":@(drawSelectionOnly)}];
	[im unlockFocus];
	return [im CGImageForProposedRect:NULL context:nil hints:nil];
}

-(NSRect)rectCroppedToOpaqueSelectionOnly:(BOOL)selectionOnly drawSelectionOnly:(BOOL)drawSelectionOnly
{
    NSSize sz = [[self document]documentSize];
	NSBitmapImageRep *bm = newBitmap(sz.width, sz.height);
    NSGraphicsContext *ctxt = [NSGraphicsContext graphicsContextWithBitmapImageRep:bm];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:ctxt];
	[graphicView drawPage:[graphicView currentPage] rect:NSMakeRect(0,0,sz.width,sz.height) drawingToScreen:NO drawMarkers:NO
			 drawingToPDF:nil substitutions:[NSMutableDictionary dictionaryWithCapacity:5] 
                  options:@{@"overrideScale":@1.0,
                           @"selectionOnly":@YES}];
    [NSGraphicsContext restoreGraphicsState];
    unsigned char *bitmapData = [bm bitmapData];
    NSInteger bytesPerRow = [bm bytesPerRow];
    NSInteger topRow=0,bottomRow=sz.height-1,leftColumn=0,rightColumn=sz.width-1;
    BOOL op = NO;
    for (NSInteger row = topRow;row < sz.height && !op;row++) 
    {
        unsigned char *rowAddr = bitmapData + bytesPerRow * row;
        for (int i = 0;i < sz.width && !op;i++)
            op = rowAddr[i*4+3] > 0;
        if (op)
            topRow = row;
    }
    op = NO;
    for (NSInteger row = bottomRow;row >= 0 && !op;row--) 
    {
        unsigned char *rowAddr = bitmapData + bytesPerRow * row;
        for (int i = 0;i < sz.width && !op;i++)
            op = rowAddr[i*4+3] > 0;
        if (op)
            bottomRow = row;
    }
    op = NO;
    for (NSInteger col = leftColumn;col < sz.width && !op;col++) 
    {
        for (NSInteger i = 0;i < sz.height && !op;i++)
        {
            unsigned char *rowAddr = bitmapData + bytesPerRow * i;
            op = rowAddr[col*4+3] > 0;
            if (op)
                leftColumn = col;
        }
    }
    op = NO;
    for (NSInteger col = rightColumn;col >=0 && !op;col--) 
    {
        for (int i = 0;i < sz.height && !op;i++)
        {
            unsigned char *rowAddr = bitmapData + bytesPerRow * i;
            op = rowAddr[col*4+3] > 0;
            if (op)
                rightColumn = col;
        }
    }
    NSInteger bot = sz.height - bottomRow - 1;
    NSInteger top = sz.height - topRow - 1;
    return NSMakeRect(leftColumn, bot, rightColumn - leftColumn + 1,top - bot + 1);
}

- (NSData*)tiffRepresentation
{
	NSSize sz = [[self document]documentSize];
	NSBitmapImageRep *bm = [graphicView bitmapImageRepForCachingDisplayInRect:[graphicView bounds]];
	NSImage *im = [[[NSImage alloc]initWithSize:sz]autorelease];
	[im addRepresentation:bm];
	//[im setFlipped:YES];
	[im lockFocusFlipped:YES];
	[[NSAffineTransform transformWithTranslateXBy:0 yBy:sz.height]concat];
	[[NSAffineTransform transformWithScaleXBy:1 yBy:-1]concat];
	[graphicView drawPage:[graphicView currentPage] rect:NSMakeRect(0,0,sz.width,sz.height) drawingToScreen:NO drawMarkers:NO
			 drawingToPDF:nil substitutions:[NSMutableDictionary dictionaryWithCapacity:5] options:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:@"overrideScale"]];
	[im unlockFocus];
	return [im TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1.0];
}

CGAffineTransform transformForOrientation(int orientation,float scale,float width,float height)
{
    float x = scale;
    float y = scale;
    float w = x *width;
    float h = y * height;
    
    CGAffineTransform ctms[8] = 
	{
		{ x, 0, 0, y, 0, 0},  //  1 =  row 0 top, col 0 lhs  =  normal
		{-x, 0, 0, y, w, 0},  //  2 =  row 0 top, col 0 rhs  =  flip horizontal
		{-x, 0, 0,-y, w, h},  //  3 =  row 0 bot, col 0 rhs  =  rotate 180
		{ x, 0, 0,-y, 0, h},  //  4 =  row 0 bot, col 0 lhs  =  flip vertical
		{ 0,-x,-y, 0, h, w},  //  5 =  row 0 lhs, col 0 top  =  rot -90, flip vert
		{ 0,-x, y, 0, 0, w},  //  6 =  row 0 rhs, col 0 top  =  rot 90
		{ 0, x, y, 0, 0, 0},  //  7 =  row 0 rhs, col 0 bot  =  rot 90, flip vert
		{ 0, x,-y, 0, h, 0}   //  8 =  row 0 lhs, col 0 bot  =  rotate -90
    };
	return ctms[orientation-1];
}

int orientationOfSource(NSDictionary *properties)
{
	int orientation = [[properties objectForKey:(__bridge NSString*)kCGImagePropertyOrientation]intValue];
	if (orientation <= 0 || orientation > 8)
		orientation = 1;
	return orientation;
}

NSImage *ImageFromFile(NSString* str)
{
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:str],NULL);
	if (!source)
		return nil;
	CGImageRef originalImage = CGImageSourceCreateImageAtIndex(source,0,NULL);
	if (!originalImage)
	{
		CFRelease(source);
		return nil;
	}
	CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source,0,nil);
	NSDictionary *dict = (NSDictionary*)properties;
	//	resolution = [[dict objectForKey:(NSString*)kCGImagePropertyDPIWidth]intValue];
	//	if (resolution < 10)
	//		resolution = 72;
	int orientation = orientationOfSource(dict);
	size_t originalWidth,originalHeight,newWidth,newHeight;
	newWidth = originalWidth = CGImageGetWidth(originalImage);
	newHeight = originalHeight = CGImageGetHeight(originalImage);
	NSBitmapImageRep *bm;
	if (orientation == 1)
		bm = [[[NSBitmapImageRep alloc]initWithCGImage:originalImage]autorelease];
	else
	{
		if (orientation == 6 || orientation == 8 || orientation == 7 || orientation == 5)
		{
			newWidth = originalHeight;
			newHeight = originalWidth;
		}
		CGAffineTransform transform = transformForOrientation(orientation,1.0,originalWidth,originalHeight);
		CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		NSInteger bytesPerRow = (newWidth * 4 + 15) & ~15;
		CGContextRef context = CGBitmapContextCreate(NULL,newWidth,newHeight,8,bytesPerRow,space,kCGImageAlphaPremultipliedLast);
		CFRelease(space);
		CGContextSaveGState(context);
		CGContextConcatCTM(context,transform);
		CGRect destR = CGRectMake(0,0,originalWidth,originalHeight);
		CGContextDrawImage(context,destR,originalImage);
		CGContextRestoreGState(context);		
		CGImageRef newImage = CGBitmapContextCreateImage(context);
		bm = [[[NSBitmapImageRep alloc]initWithCGImage:newImage]autorelease];
		CGImageRelease(newImage);
		CGContextRelease(context);
	}
	NSImage *im = [[[NSImage alloc]initWithSize:NSMakeSize(newWidth,newHeight)]autorelease];
	[im lockFocus];
	[bm draw];
	[im unlockFocus];
//	[im addRepresentation:bm];
	CGImageRelease(originalImage);
	CFRelease(source);
	CFRelease(properties);
	return im;
}

-(int)importImage:(NSString*)str
{
	NSImage *im = ImageFromFile(str);
	if (!im)
		im = [[[NSImage alloc]initWithContentsOfFile:str]autorelease];
	if (im)
	{
		[graphicView createImage:im name:str location:NULL fileName:nil];
		return 1;
	}
	return 0;
}

-(BOOL)printing
   {
	return printing;
   }

- (IBAction)closeSheet: (id)sender
{
    NSInteger reply = [sender tag];
    [[self window]endSheet:[sender window] returnCode:reply];
}
- (IBAction)closeAbsLinkSheet: (id)sender
   {
    NSInteger reply = [sender tag];
	if (reply == 0) //ok
	   {
		NSString *str = [linkTextField stringValue];
		if ([str isEqualToString:@""])
			[[graphicView selectedGraphics]makeObjectsPerformSelector:@selector(uSetLink:) withObject:nil];
		else
		   {
			NSURL *url = [NSURL URLWithString:str];
			if (url)
				[[graphicView selectedGraphics]makeObjectsPerformSelector:@selector(uSetLink:) withObject:url];
			else
				return;
			[[graphicView undoManager] setActionName:@"Set Link"];
		   }
	   }
	[NSApp endSheet:_abslinkSheet];
   }

- (void)abslinkSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	[_abslinkSheet orderOut:self];
}

-(void)loadSheetNib
{
	[[NSBundle mainBundle]loadNibNamed:@"RotationSheet" owner:self topLevelObjects:nil];
}

- (IBAction)absoluteLink: (id)sender
   {
	if (!_abslinkSheet)
		[self loadSheetNib];
	[linkTextField setStringValue:@""];
	if ([[graphicView selectedGraphics]count] == 1)
	   {
		id l = [[[[graphicView selectedGraphics]allObjects]objectAtIndex:0]link];
		if ([l isKindOfClass:[NSURL class]])
			[linkTextField setStringValue:[l description]];
	   }
    [NSApp beginSheet: _abslinkSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(abslinkSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
   }

-(void)showGenTextFieldWithTitle:(NSString*)title completionBlock:(void (^)(NSString *str))completionBlock
{
    if (!_genTextSheet)
		[self loadSheetNib];
	[genTextField setStringValue:@""];
    [genTextTitle setStringValue:title];
    [[self window]beginSheet:_genTextSheet completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == 0)
        {
            NSString *str = [genTextField stringValue];
            if (str)
                completionBlock(str);
        }
    }];
}

#pragma mark

- (IBAction)hideLayerWithName:(id)sender
{
    [self showGenTextFieldWithTitle:@"Hide Layer with Name:" completionBlock:^(NSString *str) {
        [graphicView hideLayersWithName:str];
    }];
}

- (IBAction)selectLayerWithName:(id)sender
{
    [self showGenTextFieldWithTitle:@"Select Layer with Name:" completionBlock:^(NSString *str) {
        [graphicView selectLayersWithName:str];
    }];
}

#pragma mark

- (IBAction)closeRotateSheet: (id)sender
{
    NSInteger reply = [sender tag];
	if (reply < 2)
    {
		if (reply == 1)				//copy
			[graphicView duplicateInPlace:nil];
		float rot = [rotateTextField floatValue];
		[graphicView rotateselectedGraphicsWithDict:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:rot],@"rotation",
                                                     [NSValue valueWithPoint:[graphicView rotationPoint]],@"rotationPoint",nil]];
    }
	[NSApp endSheet:_rotateSheet];
}

- (void)rotateSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	[graphicView setCursorMode:GV_MODE_NONE];
	[_rotateSheet orderOut:self];
}

- (void)showRotateDialog
{
	if (!_rotateSheet)
		[self loadSheetNib];
    [NSApp beginSheet: _rotateSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(rotateSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}

#pragma mark -

- (IBAction)closeEditPointSheet: (id)sender
{
    NSInteger reply = [sender tag];
    if (reply == 0)
    {
        NSDictionary *dict = @{
                               @"point":[NSValue valueWithPoint:NSMakePoint([epPtX floatValue], [epPtY floatValue])],
                               @"preControlPoint":[NSValue valueWithPoint:NSMakePoint([epCP1X floatValue], [epCP1Y floatValue])],
                               @"postControlPoint":[NSValue valueWithPoint:NSMakePoint([epCP2X floatValue], [epCP2Y floatValue])],
                               @"hasPreControlPoint":@([epCBCP1 integerValue]),
                               @"hasPostControlPoint":@([epCBCP2 integerValue])
                               };
        [graphicView updateSelectedPointFromDictionary:dict];
    }
    [NSApp endSheet:self.editPointSheet];
}

- (void)editPointSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    [self.editPointSheet orderOut:self];
}

-(void)showEditPointDialogForPathElement:(ACSDPathElement*)pe
{
    if (!_rotateSheet)
        [self loadSheetNib];
    [epPtX setFloatValue:pe.point.x];
    [epPtY setFloatValue:pe.point.y];
    [epCP1X setFloatValue:pe.preControlPoint.x];
    [epCP1Y setFloatValue:pe.preControlPoint.y];
    [epCP2X setFloatValue:pe.preControlPoint.x];
    [epCP2Y setFloatValue:pe.postControlPoint.y];
    [epCBCP1 setIntegerValue:pe.hasPreControlPoint];
    [epCBCP2 setIntegerValue:pe.hasPostControlPoint];
    [NSApp beginSheet: self.editPointSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(editPointSheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}

-(IBAction)showGroupView:(id)sender
{
    if (self.groupViewController == nil)
        [[NSBundle mainBundle]loadNibNamed:@"GroupWindow" owner:self topLevelObjects:nil];
    [self.groupWindow makeKeyAndOrderFront:self];
	self.groupViewController.graphicView = [self graphicView];
	NSArray *objs = [[[self graphicView]selectedGraphics]allObjects];
	if ([objs count] == 1)
		[self.groupViewController setUpObjectsForGraphic:objs[0]];
}

#pragma mark  - renaming

static NSMutableArray *parseRenameString(NSString* str)
{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:5];
    int idx = 0,startidx = 0;
    while (idx < [str length])
    {
        if ([str characterAtIndex:idx] == '%')
        {
            if (idx > startidx)
            {
                [arr addObject:[str substringWithRange:NSMakeRange(startidx, idx - startidx)]];
                startidx = idx;
            }
            idx++;
            if (idx < [str length])
            {
                unichar uc = [str characterAtIndex:idx];
                if (uc == 'a')
                    [arr addObject:@[@"a",@0]];
                else if (uc == 'n')
                    [arr addObject:@[@"n",@0]];
                else
                    return nil;
                idx++;
                startidx = idx;
            }
            else
                return nil;
        }
        else
            idx++;
    }
    if (idx > startidx)
        [arr addObject:[str substringWithRange:NSMakeRange(startidx, idx - startidx)]];
    return arr;
}

- (IBAction)closeRenameSheet: (id)sender
{
    NSInteger reply = [sender tag];
	if (reply < 1)
    {
        [self.renameSheet makeFirstResponder:nil];
        NSMutableArray *arr = parseRenameString([renameTextField stringValue]);
        if (arr != nil)
        {
            NSString *alphaStartFrom = [renameStartFromTextField stringValue];
            [[NSUserDefaults standardUserDefaults] setObject:[renameTextField stringValue] forKey:prefsRenameString];
            [[NSUserDefaults standardUserDefaults] setObject:[renameStartFromTextField stringValue] forKey:prefsRenameStartFromString];
            int numberStartFrom = [alphaStartFrom intValue];
            [graphicView renameSelectedGraphicsUsingParams:arr startA:alphaStartFrom startN:numberStartFrom orderBy:(int)[renameOrderByMatrix selectedRow] rowAscending:[renameRowDescendingCB intValue] == 0 colAscending:[renameColDescendingCB intValue] == 0 ];
        }
    }
	[NSApp endSheet:_renameSheet];
}

- (void)renameSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	[_renameSheet orderOut:self];
}

- (IBAction)showRenameDialog: (id)sender
{
	if (!_renameSheet)
    {
		[self loadSheetNib];
        NSString *ren = [[NSUserDefaults standardUserDefaults]objectForKey:prefsRenameString];
        if (ren != nil)
            [renameTextField setStringValue:ren];
        NSString *rena = [[NSUserDefaults standardUserDefaults]objectForKey:prefsRenameStartFromString];
        if (rena != nil)
            [renameStartFromTextField setStringValue:rena];
    }
    [NSApp beginSheet: _renameSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(renameSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}

#pragma mark
#define SCOPE_SELECTION 0
#define SCOPE_LAYER 1
#define SCOPE_PAGE 2
#define SCOPE_GLOBAL 3

-(NSArray<ACSDGraphic*>*)graphicsForScope:(int)scope
{
    if (scope == SCOPE_SELECTION)
        return [[[self graphicView] selectedGraphics]allObjects];
    if (scope == SCOPE_LAYER)
        return [[[self graphicView]currentEditableLayer]graphics];
    NSMutableArray<ACSDPage*>* pges = [NSMutableArray array];
    NSMutableArray<ACSDGraphic*>* graphics = [NSMutableArray array];
    if (scope == SCOPE_PAGE)
        [pges addObject:[[self graphicView]currentPage]];
    else
        [pges addObjectsFromArray:pages];
    for (ACSDPage *p in pges)
    {
        for (ACSDLayer *l in [p layers])
        {
            [graphics addObjectsFromArray:[l graphics]];
        }
    }
    return graphics;
}
-(IBAction)previewRename:(id)sender
{
    [self.renameRegexpSheet makeFirstResponder:nil];
    NSString *pattern = [regexpPattern stringValue];
    [[NSUserDefaults standardUserDefaults] setObject:pattern forKey:prefsRegexpPattern];
    [[NSUserDefaults standardUserDefaults] setObject:[regexpTemplate stringValue] forKey:prefsRegexpTemplate];
    pattern = [NSString stringWithFormat:@"^%@$",pattern];
    NSString *templateString = [regexpTemplate stringValue];
    NSError *err = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&err];
    if (err)
    {
        [regexpMsg setStringValue:[err localizedDescription]];
        return;
    }
    if (regexp)
    {
        int scopeIdx = (int)[regexpScope indexOfSelectedItem];
        NSArray<ACSDGraphic*> *selGraphics = [self graphicsForScope:scopeIdx];
        int noChanged = 0;
        NSMutableString *ms = [[NSMutableString alloc]init];
        for (ACSDGraphic *g in selGraphics)
        {
            NSString *nm = [g name];
            if ([regexp numberOfMatchesInString:nm options:0 range:NSMakeRange(0, [nm length])])
            {
                NSString *outstr = [regexp stringByReplacingMatchesInString:nm options:0 range:NSMakeRange(0, [nm length]) withTemplate:templateString];
                [ms appendFormat:@"%@ ==> %@\n",nm,outstr];
                noChanged++;
            }
        }
        [regexpMsg setStringValue:[NSString stringWithFormat:@"%d / %d objects will be renamed.\n%@",noChanged,(int)[selGraphics count],ms]];
    }

}
- (IBAction)closeRegexpSheet: (id)sender
{
	NSInteger reply = [sender tag];
	if (reply < 1)
	{
		[self.renameRegexpSheet makeFirstResponder:nil];
		NSString *pattern = [regexpPattern stringValue];
		[[NSUserDefaults standardUserDefaults] setObject:pattern forKey:prefsRegexpPattern];
		[[NSUserDefaults standardUserDefaults] setObject:[regexpTemplate stringValue] forKey:prefsRegexpTemplate];
		NSString *patternx = [NSString stringWithFormat:@"^%@$",pattern];
		NSError *err = nil;
		NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:patternx options:0 error:&err];
		if (err)
		{
			[regexpMsg setStringValue:[err localizedDescription]];
			return;
		}
		if (regexp)
		{
            int scopeIdx = (int)[regexpScope indexOfSelectedItem];
            int ct = [[self graphicView]renameGraphics:[self graphicsForScope:scopeIdx] usingRegularExpression:regexp template:[regexpTemplate stringValue]];
            NSArray *a = [[NSUserDefaults standardUserDefaults]arrayForKey:@"regexppopup"];
            NSLog(@"%@",a);
            if (a == nil)
            {
                a = [NSMutableArray arrayWithObject:@"/"];
            }
            NSMutableArray *marr = [a mutableCopy];
            NSString *newstr = [NSString stringWithFormat:@"%@ --> %@",pattern,[regexpTemplate stringValue]];
            if ([marr containsObject:newstr])
                [marr removeObject:newstr];
            if ([marr count] == 1)
                [marr addObject:newstr];
            else
                [marr insertObject:newstr atIndex:1];
            while ([marr count] > 10)
                [marr removeLastObject];
            [[NSUserDefaults standardUserDefaults]setObject:marr forKey:@"regexppopup"];
			[regexpMsg setStringValue:[NSString stringWithFormat:@"%d objects renamed",ct]];
		}
	}
	else
		[NSApp endSheet:_renameRegexpSheet];
}

-(IBAction)regexpHistoryPopUpHit:(id)sender
{
    int idx = (int)[sender indexOfSelectedItem];
    NSArray *a = [[NSUserDefaults standardUserDefaults]arrayForKey:@"regexppopup"];
    if (a == nil || idx >= [a count])
        return;
    NSString *s = a[idx];
    NSRange r = [s rangeOfString:@" --> "];
    if (r.location == NSNotFound)
        return;
    [regexpPattern setStringValue:[s substringToIndex:r.location]];
    [regexpTemplate setStringValue:[s substringFromIndex:r.location + r.length]];
}
- (void)regexpSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	[_renameRegexpSheet orderOut:self];
}

- (IBAction)showRegexpDialog: (id)sender
{
	if (!_renameRegexpSheet)
	{
		[self loadSheetNib];
		NSString *ren = [[NSUserDefaults standardUserDefaults]objectForKey:prefsRegexpPattern];
		if (ren != nil)
			[regexpPattern setStringValue:ren];
		NSString *rena = [[NSUserDefaults standardUserDefaults]objectForKey:prefsRegexpTemplate];
		if (rena != nil)
			[regexpTemplate setStringValue:rena];
		[regexpMsg setStringValue:@""];
	}
	[NSApp beginSheet: _renameRegexpSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(regexpSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}



#pragma mark

- (IBAction)closeRepeatSheet: (id)sender
{
    NSInteger reply = [sender tag];
    if (reply < 1)
    {
        [self.repeatSheet makeFirstResponder:nil];
        [graphicView repeatSelectedGraphicsRows:[repeatRowsTextField intValue] cols:[repeatColsTextField intValue] xinc:[repeatxincTextField floatValue] yinc:[repeatyincTextField floatValue] rowOffset:[rowOffsetTextField floatValue]];
    }
    [NSApp endSheet:_repeatSheet];
}

- (void)repeatSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
    [_repeatSheet orderOut:self];
}

- (IBAction)showRepeatDialog: (id)sender
{
    if (!_repeatSheet)
    {
        [self loadSheetNib];
        [repeatColsTextField setIntegerValue:2];
        [repeatRowsTextField setIntegerValue:2];
    }
    NSArray *arr = [[graphicView selectedGraphics]allObjects];
    if ([arr count] > 0)
    {
        ACSDGraphic *g = arr[0];
        NSRect b = [g bounds];
        [repeatwTextField setFloatValue:b.size.width];
        [repeathtextField setFloatValue:b.size.height];
        [repeatxincTextField setFloatValue:b.size.width];
        [repeatyincTextField setFloatValue:b.size.height];
        [NSApp beginSheet: _repeatSheet
           modalForWindow: [self window]
            modalDelegate: self
           didEndSelector: @selector(repeatSheetDidEnd:returnCode:contextInfo:)
              contextInfo: nil];
    }
}

#pragma mark

-(void)generateTocUsingStyles:(NSArray*)stylePairs
   {
	NSMutableAttributedString *tocString = [[NSMutableAttributedString alloc]init];
	NSRect r = [graphicView bounds];
	r = NSInsetRect(r,20,20);
	ACSDText *t = [[ACSDText alloc]initWithName:@"TOC" fill:nil stroke:nil rect:r layer:[graphicView currentEditableLayer]];
	NSTextStorage *ts = [[[NSTextStorage alloc]init]autorelease];
	[t setContents:ts];
	NSMutableArray *styles = [NSMutableArray arrayWithCapacity:[stylePairs count]];
	NSMutableArray *mappedStyles = [NSMutableArray arrayWithCapacity:[stylePairs count]];
	for (unsigned i = 0;i < [stylePairs count];i++)
	{
		NSArray *a = [stylePairs objectAtIndex:i];
		[styles addObject:[a objectAtIndex:0]];
		[mappedStyles addObject:[a objectAtIndex:1]];
	}
	for (unsigned i = 0;i < [pages count];i++)
	   {
		ACSDPage *page = [pages objectAtIndex:i];
		if ([page pageType] != PAGE_TYPE_MASTER)
		   {
			NSArray *textObjects = [page allTextObjectsOrderedByPosition];
			for (unsigned j = 0;j < [textObjects count];j++)
				[[textObjects objectAtIndex:j]addTOCStyles:styles toString:tocString mappedStyles:mappedStyles target:t];
		   }
	   }
	[ts beginEditing];
	[ts appendAttributedString:tocString];
	[ts endEditing];
	[graphicView addGraphic:t];
	[t release];
   }

- (void)tocSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
   {
	[sheet orderOut:self];
   }

- (IBAction)showTOCSheet: (id)sender
   {
	if (!tocController)
		tocController = [[TOCController alloc]initWithController:self];
	[tocController setStyles:[[self document]styles]];
    [NSApp beginSheet: [tocController tocSheet]
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(tocSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
   }

- (IBAction)closeDocSizeSheet: (id)sender
   {
    NSInteger reply = [sender tag];
	if (reply == 0)
	   {
		NSSize sz = NSMakeSize([docSizeWidth intValue],[docSizeHeight intValue]);
		[graphicView changeDocumentSize:sz matrixRow:(int)[docSizeMatrix selectedRow] matrixColumn:(int)[docSizeMatrix selectedColumn]];
	   }
	[NSApp endSheet:_docSizeSheet];
   }

- (IBAction)closeScaleDocSheet: (id)sender
{
    int reply = (int)[sender tag];
	if (reply == 0)
	{
		float scale = [scaleTextField floatValue];
		[graphicView scaleDocumentBy:scale];
	}
	[NSApp endSheet:_scaleSheet];
}

- (void)generalSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
   {
	[sheet orderOut:self];
   }

- (IBAction)showDocSizeDialog: (id)sender
   {
	if (!_docSizeSheet)
		[self loadSheetNib];
	NSSize sz = [graphicView bounds].size;
	[docSizeWidth setIntValue:(int)sz.width];
	[docSizeHeight setIntValue:(int)sz.height];
    [NSApp beginSheet: _docSizeSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(generalSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
   }

- (IBAction)showScaleDocDialog: (id)sender
{
	if (!_scaleSheet)
		[self loadSheetNib];
	[scaleTextField setIntValue:1];
    [NSApp beginSheet: _scaleSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(generalSheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
   {
	if ([pages count] > 1)
		if (viewNumber > -1)
			return [displayName stringByAppendingFormat:@":%d: %@",viewNumber,[[graphicView currentPage]Desc]];
		else
			return [displayName stringByAppendingFormat:@": %@",[[graphicView currentPage]Desc]];
	else
		if (viewNumber > -1)
			return [displayName stringByAppendingFormat:@":%d",viewNumber];
		else
			return displayName;
   }

- (BOOL)validateMenuItem:(id)menuItem
{
	SEL action = [menuItem action];
	if (action == @selector(showGroupView:))
		return [[[self graphicView]selectedGraphics]count] == 1;
	return YES;
}
@end
