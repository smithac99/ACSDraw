//
//  DragView.mm
//  ACSDraw
//
//  Created by alan on 19/01/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DragView.h"
#import "PanelController.h"


@implementation DragView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
	{
        // Initialization code here.
    }
    return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(void)allocCloseButton
{
	NSRect r = [self bounds];
	r.origin.x = left;
	r.size.width = r.size.height;
	r = NSInsetRect(r,4,4);
	NSButton *b = [[[NSButton alloc]initWithFrame:r]autorelease];
	[b setButtonType:NSMomentaryPushInButton];
	[b setTitle:@""];
	[b setBezelStyle:NSRoundRectBezelStyle];
	[b setImagePosition:NSNoImage];
	[self addSubview:b];
	[b setAction:@selector(orderOut:)];
	[b setTarget:[self window]];
}

-(void)awakeFromNib
{
}

-(NSBezierPath*)path
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(left,0.0)];
	[path lineToPoint:NSMakePoint(left,NSMaxY([self bounds]))];
	[path lineToPoint:NSMakePoint(right,NSMaxY([self bounds]))];
	[path lineToPoint:NSMakePoint(right+20,0.0)];
	[path closePath];
	return path;
}

-(float)minTitleWidth
{
	NSAttributedString *string = [[[NSAttributedString alloc]initWithString:[[self window]title]attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
			nil]]autorelease];
	return [self bounds].size.height + [string size].width;
}

- (void)drawRect:(NSRect)rect 
{
	if ([[self subviews] count] == 0)
		[self allocCloseButton];
	[[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]set];
	NSBezierPath *p = [self path];
	[p fill];
	[[NSColor whiteColor]set];
	NSAttributedString *string = [[NSAttributedString alloc]initWithString:[[self window]title]attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
			[NSColor whiteColor],NSForegroundColorAttributeName,
			nil]];
	float l = (right - (left + [self bounds].size.height) - [string size].width)/2.0 + [self bounds].size.height + left;
	if (l < left)
		l = left;
	[string drawAtPoint:NSMakePoint(l,1.0)];
	[string release];
}

-(void)setLeft:(float)l
{
	left = l;
}

-(void)setRight:(float)r
{
	right = r;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint currentLocation = [[self window]convertBaseToScreen:[theEvent locationInWindow]];
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
	PanelController *controller = [[self window]delegate];
	PanelController *pc = [controller linkedPeer];
	while (pc && (pc != controller))
	{
		[pc alignWith:controller];
		pc = [pc linkedPeer];
	}
}

-(BOOL)containsScreenPoint:(NSPoint)screenPt
{
	return (NSPointInRect([self convertPoint:[[self window]convertScreenToBase:screenPt]fromView:nil],[self bounds]));
}

- (void)mouseDown:(NSEvent *)theEvent
{    
	dragOffset = [theEvent locationInWindow];
	if (([theEvent modifierFlags] & NSCommandKeyMask)!=0)
		[(PanelController*)[[self window]delegate]unlink];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (([theEvent modifierFlags] & NSCommandKeyMask)!=0)
		[(PanelController*)[[self window]delegate]dockIfAppropriate:[[self window]convertBaseToScreen:[theEvent locationInWindow]]];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

@end
