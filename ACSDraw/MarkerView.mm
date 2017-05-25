//
//  MarkerView.mm
//  ACSDraw
//
//  Created by alan on 28/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MarkerView.h"
#import "SnapLine.h"
#import "GraphicView.h"
#import "ACSDLayer.h"
#import "ACSDPage.h"
#import "SelectionSet.h"
#import "ACSDGraphic.h"
#import "gSubPath.h"
#import "gCurve.h"
#import "gLine.h"
#import "geometry.h"
#import "ACSDPrefsController.h"
#import "AffineTransformAdditions.h"

@interface MarkerView ()

@property float directionOffset;
@property (weak) CALayer *mainLayer;

@end

@implementation MarkerView


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		self.mainLayer = [CALayer layer];
		[self setLayer:self.mainLayer];
		self.mainLayer.frame=NSRectToCGRect([self bounds]);
		
		[self.mainLayer setDelegate:self];
		self.mainLayer.autoresizingMask = kCALayerWidthSizable|kCALayerHeightSizable;
		[self setWantsLayer:YES];
		[self.mainLayer setNeedsDisplay];
		
		self.verticalSnapLineLayer = [CALayer layer];
		self.verticalSnapLineLayer.bounds = CGRectMake(0, 0, 1, [self bounds].size.height);
		self.verticalSnapLineLayer.anchorPoint = CGPointMake(0.5, 0);
		self.verticalSnapLineLayer.position = CGPointMake(10, 0);
		self.verticalSnapLineLayer.autoresizingMask = kCALayerHeightSizable;
		self.verticalSnapLineLayer.hidden = true;
		self.verticalSnapLineLayer.backgroundColor = [[NSColor cyanColor]CGColor];
		self.verticalSnapLineLayer.delegate = self;
		[self.mainLayer addSublayer:self.verticalSnapLineLayer];
		
		self.horizontalSnapLineLayer = [CALayer layer];
		self.horizontalSnapLineLayer.bounds = CGRectMake(0, 0, [self bounds].size.width,1);
		self.horizontalSnapLineLayer.anchorPoint = CGPointMake(0, 0.5);
		self.horizontalSnapLineLayer.position = CGPointMake(0, 10);
		self.horizontalSnapLineLayer.autoresizingMask = kCALayerWidthSizable;
		self.horizontalSnapLineLayer.hidden = true;
		self.horizontalSnapLineLayer.backgroundColor = [[NSColor cyanColor]CGColor];
		self.horizontalSnapLineLayer.delegate = self;
		[self.mainLayer addSublayer:self.horizontalSnapLineLayer];
    }
    return self;
}

-(void)setNeedsDisplayInRect:(NSRect)invalidRect
{
	[self.mainLayer setNeedsDisplayInRect:invalidRect];
}

-(void)setNeedsDisplay:(BOOL)needsDisplay
{
	[self.mainLayer setNeedsDisplay];
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext
{
	if (theLayer == self.mainLayer)
	{
		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:theContext flipped:NO]];
		[[NSGraphicsContext currentContext]saveGraphicsState];
		CGRect dirtyRect = CGContextGetClipBoundingBox(theContext);
		[self drawRect:dirtyRect];
		[[NSGraphicsContext currentContext]restoreGraphicsState];
		[NSGraphicsContext restoreGraphicsState];
	}
}

- (id < CAAction >)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
	return (id < CAAction >)[NSNull null];
}

- (void)drawRect:(NSRect)aRect
{
	if (![NSGraphicsContext currentContextDrawingToScreen])
		return;
    BOOL showPathDirection = [[ACSDPrefsController sharedACSDPrefsController:nil]showPathDirection];
	float mag = [_graphicView magnification];
//	[[NSAffineTransform transformWithScaleBy:mag] concat];
	for (ACSDLayer *layer in [_graphicView layers])
		if ([layer visible])
		{
			if ([layer editable] && layer == [_graphicView currentEditableLayer] && _graphicView.showSelection)
				for (ACSDGraphic *g in [[layer selectedGraphics]allObjects])
					[g drawHandlesGuide:NO magnification:mag options:showPathDirection?DRAW_HANDLES_PATH_DIR:0];
			else if ([layer isGuideLayer])
				for (ACSDGraphic *g in [layer graphics])
					[g drawHandlesGuide:YES magnification:mag options:0];
		}
	if ([_graphicView creatingGraphic])
	{
        NSRect displayBounds = [[_graphicView creatingGraphic] displayBounds];
        if (NSIntersectsRect(aRect, displayBounds))
			[[_graphicView creatingGraphic] drawHandlesGuide:NO magnification:mag options:0];
	}
	NSArray *masters = [[_graphicView currentPage] masters];
	NSInteger pno = [[_graphicView currentPage] pageNo];
	if (masters)
	{
		for (ACSDPage *mp in masters)
		{
			if (([mp masterType] == MASTER_TYPE_ALL) || ([mp masterType] == MASTER_TYPE_ODD && (pno &1)) || ([mp masterType] == MASTER_TYPE_EVEN && !(pno &1)))
				for (ACSDLayer *layer in [mp layers])
					if ([layer visible])
					{
						if ([layer isGuideLayer])
							for (ACSDGraphic *g in [layer graphics])
								[g drawHandlesGuide:YES magnification:mag options:0];
					}
		}
	}
}

@end
