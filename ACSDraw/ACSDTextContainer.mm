//
//  ACSDTextContainer.mm
//  ACSDraw
//
//  Created by alan on 17/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ACSDTextContainer.h"
#import "ACSDText.h"
#import "ACSDSubPath.h"
#import "ACSDRect.h"
#import "GraphicView.h"
#import "ACSDPath.h"

void sortRectsByX(NSRect* rList,NSInteger count);
float minY(NSRect* rList,int count);

@implementation ACSDTextContainer

- (id)initWithContainerSize:(NSSize)aSize graphic:(ACSDText*)g
   {
	if (self = [super initWithContainerSize:aSize])
		graphic = g;
	return self;
   }

- (BOOL)isSimpleRectangularTextContainer
   {
	return ([graphic flowMethod] == FLOW_METHOD_NONE) || ([[graphic objectsInTheWay]count] == 0) ;
   }

void sortRectsByX(NSRect* rList,NSInteger count)
   {
	BOOL changed = YES;
	while (changed)
	   {
		changed = NO;
		for (int i = 1;i < count;i++)
			if (rList[i].origin.x < rList[i-1].origin.x)
			   {
				NSRect temp = rList[i];
				rList[i] = rList[i-1];
				rList[i-1] = temp;
				changed = YES;
			   }
	   }
   }

float minY(NSRect* rList,int count)
   {
	if (count == 0)
		return 0.0;
	float minnY =  rList[0].origin.y;
	for (int i = 1;i < count;i++)
	   {
		if (rList[i].origin.y < minnY)
			minnY = rList[i].origin.y;
	   }
	return minnY;
   }

-(NSRect)containerCoordsToGlobalCoords:(NSRect)r
   {
	NSSize sz = [self containerSize];
	r.origin.y = sz.height - (r.origin.y + r.size.height);
	return NSOffsetRect(r,[graphic bounds].origin.x,[graphic bounds].origin.y);
   }

-(NSRect)globalCoordsToContainerCoords:(NSRect)r
   {
	r.origin.x -= [graphic bounds].origin.x;
	r.origin.y = NSMaxY([graphic bounds]) - NSMaxY(r);
	return r;
   }

- (NSRect)lineFragmentRectForProposedRect:(NSRect)proposedRect sweepDirection:(NSLineSweepDirection)sweepDirection
                        movementDirection:(NSLineMovementDirection)movementDirection remainingRect:(NSRect *)remainingRect
{
    if (([graphic flowMethod] == FLOW_METHOD_NONE) || ([[graphic objectsInTheWay]count] == 0))
        return [super lineFragmentRectForProposedRect:proposedRect sweepDirection:sweepDirection movementDirection:movementDirection remainingRect:remainingRect];
    NSRect contRect,intersectRect;
    contRect.origin = NSMakePoint(0.0,0.0);
    contRect.size = [self containerSize];
    //    NSRect r = NSIntersectionRect(proposedRect,contRect);    Has rounding errors
    intersectRect.origin.x = fmax(contRect.origin.x,proposedRect.origin.x);
    intersectRect.origin.y = fmax(contRect.origin.y,proposedRect.origin.y);
    float f = fmin(NSMaxX(contRect),NSMaxX(proposedRect));
    intersectRect.size.width = f - intersectRect.origin.x;
    if (NSMaxY(proposedRect) > NSMaxY(contRect))
        intersectRect.size.height = NSMaxY(contRect) - intersectRect.origin.y;
    else
        intersectRect.size.height = proposedRect.size.height;
    if (intersectRect.size.height < proposedRect.size.height)
        return NSZeroRect;
    *remainingRect = NSZeroRect;
    NSRect globalr = [self containerCoordsToGlobalCoords:intersectRect];
    if ([graphic flowMethod] == FLOW_METHOD_NO_BESIDE)
    {
        *remainingRect = NSZeroRect;
        NSArray *objs = [[graphic objectsInTheWay]allObjects];
        for (id obj in objs)
        {
            NSRect b = [obj viewableBounds];
            b = NSInsetRect(b, -[graphic flowPad], -[graphic flowPad]);
            if (!NSEqualRects(NSIntersectionRect(b,globalr),NSZeroRect))
            {
                NSRect prop = [graphic bounds];
                prop.origin.y = b.origin.y -  proposedRect.size.height;
                if (prop.origin.y < [graphic bounds].origin.y)
                    return NSZeroRect;
                prop.size.height = proposedRect.size.height;
                prop = [self globalCoordsToContainerCoords:prop];
                //                *remainingRect = prop;
                return prop;
            }
        }
        return intersectRect;
    }
    //
    //    flowMethod is FLOW_METHOD_AROUND
    //
    ACSDPath *frontPaths = [graphic pathInTheWay];
    ACSDPath *rectPaths = [[ACSDRect rectWithRect:globalr]convertToPath];
    
    NSMutableArray<ACSDPath*>*paths = [GraphicView subPathsFromSelectedObjects:@[frontPaths,rectPaths]];
    ACSDPath *intersectedpath = [ACSDPath intersectedSubPathsFromObjects:paths];
    NSArray<ACSDSubPath*>*intersectPaths = [intersectedpath subPaths];
    
    //NSArray *intersectPaths = [GraphicView intersectedSubPathsFromVertexList:[ACSDSubPath intersectionsBetweenPath:frontPaths andPath:rectPaths]];
    if ([intersectPaths count] == 0)
        return intersectRect;
    NSMutableArray *rList = [NSMutableArray array];
    for (ACSDSubPath *sp in intersectPaths)
        [rList addObject:[NSValue valueWithRect:[sp bounds]]];
    NSArray *rects = [rList sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSRect r1 = [obj1 rectValue];
        NSRect r2 = [obj2 rectValue];
        if (r1.origin.x < r2.origin.x)
            return NSOrderedAscending;
        if (r1.origin.x > r2.origin.x)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    //sortRectsByX(rList,[intersectPaths count]);
    float lastX = globalr.origin.x;
    for (NSValue *v in rects)
    {
        NSRect ri = [v rectValue];
        if (ri.origin.x > globalr.origin.x)
        {
            NSRect resultRect = globalr;
            resultRect.origin.x = lastX;
            resultRect.size.width = ri.origin.x - lastX;
            NSRect tempRemainder = globalr;
            tempRemainder.origin.x = CGRectGetMaxX(ri);
            tempRemainder.size.width = proposedRect.size.width;
            *remainingRect = [self globalCoordsToContainerCoords:tempRemainder];
            return [self globalCoordsToContainerCoords:resultRect];
        }
        else
        {
            NSRect resultRect = globalr;
            CGFloat right = CGRectGetMaxX(resultRect);
            resultRect.origin.x = CGRectGetMaxX(ri);
            resultRect.size.width = right - resultRect.origin.x;
            return [self globalCoordsToContainerCoords:resultRect];
        }
    }
    return [self globalCoordsToContainerCoords:globalr];
}

@end
