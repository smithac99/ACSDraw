//
//  ContainerTabSubview.mm
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ContainerTabSubview.h"
#import "ContainerPalletteController.h"
@interface ContainerTabSubview()
{
    ContainerPalletteController *createdcpc;
}
@end

@implementation ContainerTabSubview

- (id)initWithFrame:(NSRect)frame title:(NSString*)t controller:(ContainerPalletteController*)cpc
{
    if (self = [super initWithFrame:frame])
	{
        title = [t retain];
		cpController = cpc;
    }
    return self;
}

-(void)dealloc
{
	if (title)
		[title release];
	[super dealloc];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)closeTab:(id)sender
{
	[cpController removeTab:self];
}

-(void)allocCloseButton
{
	NSRect r = [self bounds];
	r.size.width = r.size.height;
	r = NSInsetRect(r,3,3);
	NSButton *b = [[[NSButton alloc]initWithFrame:r]autorelease];
	[b setButtonType:NSMomentaryPushInButton];
//	[b setTitle:@""];
	[b setBezelStyle:NSShadowlessSquareBezelStyle];
//	[b setImagePosition:NSNoImage];
	[b setImagePosition:NSImageOnly];
	NSImage *im = [NSImage imageNamed:@"close"];
	[b setImage:im];
	[[b cell]setImageScaling:NSImageScaleProportionallyUpOrDown];
	[self addSubview:b];
	[b setAction:@selector(closeTab:)];
	[b setTarget:self];
}

-(BOOL)active
{
	return active;
}

-(void)setActive:(BOOL)b
{
	active = b;
    [self setNeedsDisplay:YES];
}

-(NSBezierPath*)path
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(0.0,0.0)];
	[path lineToPoint:NSMakePoint(0.0,NSMaxY([self bounds]))];
	[path lineToPoint:NSMakePoint(NSMaxX([self bounds])-20,NSMaxY([self bounds]))];
	[path lineToPoint:NSMakePoint(NSMaxX([self bounds]),0.0)];
	[path closePath];
	return path;
}

- (void)drawRect:(NSRect)rect
{
	if ([[self subviews] count] == 0)
		[self allocCloseButton];
	[[NSColor colorWithCalibratedWhite:0.2 alpha:(active)?1.0:0.5]set];
	NSBezierPath *p = [self path];
	[p fill];
	[[NSColor whiteColor]set];
	NSAttributedString *string = [[NSAttributedString alloc]initWithString:title attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
			[NSColor whiteColor],NSForegroundColorAttributeName,
			nil]];
	float l = ([self bounds].size.width - ([string size].width))/2.0;
	if (l < 0.0)
		l = 0.0;
	[string drawAtPoint:NSMakePoint(l,1.0)];
	[string release];
}

-(void)mouseUp:(NSEvent *)event
{
    createdcpc = nil;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (createdcpc)
    {
        ContainerTabSubview *tsv = [createdcpc tabSubviews][0];
        [tsv mouseDragged:theEvent];
        return;
    }
	NSRect r;
	r.size.width = r.size.height = 1.0;
	r.origin = [theEvent locationInWindow];
	NSPoint currentLocation = [[self window]convertRectToScreen:r].origin;
    //NSPoint currentLocation = [[self window]convertBaseToScreen:[theEvent locationInWindow]];
	NSPoint newOrigin;
    newOrigin.x = currentLocation.x - dragOffset.x;
    newOrigin.y = currentLocation.y - dragOffset.y;
	NSRect  screenFrame = [[NSScreen mainScreen]visibleFrame];
	NSRect  windowFrame = [[self window]frame];
	
	
    if( (newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height) )
	{
		newOrigin.y=screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
    }
    [[self window] setFrameOrigin:newOrigin];
}

- (void)mouseDown:(NSEvent *)theEvent
{    
	NSRect r;
	r.size.width = r.size.height = 1.0;
	r.origin = [theEvent locationInWindow];
	dragOffset = [[self window]convertRectToScreen:r].origin;
	//dragOffset = [[self window]convertBaseToScreen:[theEvent locationInWindow]];
	[cpController tabHit:self];
	r.origin = dragOffset;
	dragOffset = [[self window]convertRectFromScreen:r].origin;
	//dragOffset = [[self window]convertScreenToBase:dragOffset];
	if (([theEvent modifierFlags] & NSCommandKeyMask)!=0 && [theEvent window] == [self window])
    {
		createdcpc = [cpController detachTab:self];
        //ContainerTabSubview *tsv = [createdcpc tabSubviews][0];
        //[tsv mouseDown:theEvent];
        CGPoint pt = NSPointToCGPoint(NSEvent.mouseLocation);
        CGEventRef ev = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, pt, kCGMouseButtonLeft);
        CGEventPost(kCGAnnotatedSessionEventTap, ev);
        CFRelease(ev);
    }
}


@end
