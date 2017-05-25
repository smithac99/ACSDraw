//
//  ACSDAttribute.mm
//  ACSDraw
//
//  Created by Alan Smith on Sat Mar 02 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDAttribute.h"
#import "ACSDGraphic.h"
#import "GraphicView.h"
#import "SVGWriter.h"


@implementation ACSDAttribute

-(id)init
   {
	if (self = [super init])
	   {
		graphics = [NSMutableSet setWithCapacity:10];
		nonDeletedCount = 0;
	   }
	return self;
   }

-(void)addGraphic:(id)g
   {
	[graphics addObject:g];
	if (![g deleted])
	   {
		nonDeletedCount++;
		if (nonDeletedCount == 1)
			[self notifyOnADDOrRemove];
		if ([g respondsToSelector:@selector(invalidateGraphicSizeChanged:shapeChanged:redraw:notify:)])
		   {
			[g invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
		   }
	   }
   }

-(void)notifyOnADDOrRemove
   {
   }

-(void)removeGraphic:(id)g
   {
	[graphics removeObject:g];
	if (![g deleted])
	   {
		nonDeletedCount--;
		if (nonDeletedCount == 0)
			[self notifyOnADDOrRemove];
		if ([g respondsToSelector:@selector(invalidateGraphicSizeChanged:shapeChanged:redraw:notify:)])
		   {
			[g invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
		   }
	   }
   }

-(void)invalidateGraphicsRefreshCache:(BOOL)redo
   {
	NSEnumerator *objEnum = [graphics objectEnumerator];
	ACSDGraphic *curGraphic;
    while ((curGraphic = [objEnum nextObject]) != nil)
		[curGraphic invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:redo notify:NO];
   }

-(NSMutableSet*)graphics
   {
    return graphics;
   }

-(BOOL)isSameAs:(id)obj
   {
	return [self class] == [obj class];
   }
   
-(void)writeSVGData:(SVGWriter*)svgWriter
   {
   }

-(NSSet*)usedStrokes
   {
	return [NSSet set];
   }

-(NSSet*)usedFills
   {
	return [NSSet set];
   }

-(NSSet*)usedShadows
   {
	return [NSSet set];
   }

- (int)showIndicator
   {
	if (nonDeletedCount > 0)
		return 2;
	return 0;
   }

-(BOOL)addToNonDeletedCount:(int)inc
   {
	nonDeletedCount += inc;
	if ((nonDeletedCount == inc) || (nonDeletedCount == 0))
	   {
		[self notifyOnADDOrRemove];
		return YES;
	   }
	return NO;
   }

-(int)nonDeletedCount
   {
	return nonDeletedCount;
   }

-(void)setDeleted:(BOOL)d
   {
	if (d == deleted)
		return;
	deleted = d;
   }

-(BOOL)deleted
   {
	return deleted;
   }

-(NSString*)canvasData:(CanvasWriter*)canvasWriter
{
	return @"";
}

@end
