//
//  ACSDPath.mm
//  ACSDraw
//
//  Created by Alan Smith on Sun Feb 03 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDPath.h"
#import "ACSDSubPath.h"
#import "ACSDPathElement.h"
#import "ACSDLineEnding.h"
#import "GraphicView.h"
#import "ShadowType.h"
#import "IPolygon.h"
#import "SelectedElement.h"
#import "geometry.h"
#import "ArrayAdditions.h"
#import "AffineTransformAdditions.h"
#import "ToolWindowController.h"
#import "ACSDCursor.h"
#import "NSString+StringAdditions.h"
#import "gSubPath.h"
#import "XMLNode.h"
#import "SizeController.h"
#import <CoreGraphics/CoreGraphics.h>
#import <CoreGraphics/CGPath.h>
#import "SVGWriter.h"
#import "ACSDPrefsController.h"

void bezierPathFromSubPath(NSArray* subPaths,NSBezierPath *path);

static NSCharacterSet *svgPathDelimCharacterSet()
{
    static NSMutableCharacterSet *charset = nil;
    if (charset == nil)
    {
        charset = [[NSCharacterSet whitespaceAndNewlineCharacterSet]mutableCopyWithZone:nil];
        [charset addCharactersInString:@","];
    }
    return charset;
}

static NSCharacterSet *svgFloatCharacterSet()
{
    static NSMutableCharacterSet *charset = nil;
    if (charset == nil)
    {
        charset = [[NSCharacterSet decimalDigitCharacterSet]mutableCopyWithZone:nil];
        [charset addCharactersInString:@".e"];
    }
    return charset;
}

static NSCharacterSet *svgCommandCharacterSet()
{
    static NSCharacterSet *charset = nil;
    if (charset == nil)
    {
        charset = [[NSCharacterSet characterSetWithCharactersInString:@"zZMmLlHhVvCcSsQqTtAa"]retain];
    }
    return charset;
}

static int skipdelims(NSString *str,int idx)
{
    NSCharacterSet *charset = svgPathDelimCharacterSet();
    while (idx < [str length])
    {
        unichar uc = [str characterAtIndex:idx];
        if (![charset characterIsMember:uc])
            return idx;
        idx++;
    }
    return idx;
}

static float getFloat(NSString* str,int *i)
{
    int idx = *i;
    NSMutableString *rstr = [[[NSMutableString alloc]init]autorelease];
    unichar lastChar = 0;
    idx = skipdelims(str, idx);
    if (idx < [str length])
    {
        if ([[str substringWithRange:NSMakeRange(idx, 1)]isEqualToString:@"-"])
        {
            idx++;
            [rstr appendString:@"-"];
        }
    }
    while (idx < [str length])
    {
        unichar uc = [str characterAtIndex:idx];
        if (![svgFloatCharacterSet() characterIsMember:uc] || (uc == '-' && lastChar == 'e'))
            break;
        lastChar = uc;
        [rstr appendString:[str substringWithRange:NSMakeRange(idx, 1)]];
        idx++;
    }
    *i = idx;
    return [rstr floatValue];
}

NSBezierPath* bezierPathFromSVGPath(NSString *str)
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    int idx = 0;
    idx = skipdelims(str,idx);
    float currx = 0.0,curry = 0.0,cx1,cy1,cx2,cy2,dx,dy,qx,qy;
	float rx,ry,xrot;
	int largearcflag,sweepflag;

    unichar implicitCommand = 'M',lastCommand=0,uc=0;
    NSPoint lastcurvepoint = NSZeroPoint;
    while (idx < [str length])
    {
        lastCommand = uc;
        uc = [str characterAtIndex:idx];
        if ([svgCommandCharacterSet() characterIsMember:uc])
            idx++;
        else
            uc = implicitCommand;
        switch (uc)
        {
            case 'M':
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path moveToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'L';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'm':
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path moveToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'l';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'L':
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                lastcurvepoint = NSZeroPoint;
                implicitCommand = 'L';
                break;
            case 'l':
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'l';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'H':
                currx = getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'H';
                break;
            case 'h':
                currx += getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'h';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'V':
                curry = getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'V';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'v':
                curry += getFloat(str,&idx);
                [path lineToPoint:NSMakePoint(currx, curry)];
                implicitCommand = 'v';
                lastcurvepoint = NSZeroPoint;
                break;
            case 'C':
                cx1 = getFloat(str,&idx);
                cy1 = getFloat(str,&idx);
                cx2 = getFloat(str,&idx);
                cy2 = getFloat(str,&idx);
                lastcurvepoint = NSMakePoint(cx2,cy2);
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'C';
                break;
            case 'c':
                cx1 = currx + getFloat(str,&idx);
                cy1 = curry + getFloat(str,&idx);
                cx2 = currx + getFloat(str,&idx);
                cy2 = curry + getFloat(str,&idx);
                lastcurvepoint = NSMakePoint(cx2,cy2);
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'c';
                break;
            case 'S':
                if (! [@"CcSs" containsChar:lastCommand])
                    lastcurvepoint = NSZeroPoint;
                dx = currx - lastcurvepoint.x;
                dy = curry - lastcurvepoint.y;
                cx1 = currx + dx;
                cy1 = curry + dy;
                cx2 = getFloat(str,&idx);
                cy2 = getFloat(str,&idx);
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                lastcurvepoint = NSMakePoint(cx2,cy2);
                implicitCommand = 'S';
                break;
            case 's':
                if (! [@"CcSs" containsChar:lastCommand])
                    lastcurvepoint = NSZeroPoint;
                dx = currx - lastcurvepoint.x;
                dy = curry - lastcurvepoint.y;
                cx1 = currx + dx;
                cy1 = curry + dy;
                cx2 = currx + getFloat(str,&idx);
                cy2 = curry + getFloat(str,&idx);
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                lastcurvepoint = NSMakePoint(cx2,cy2);
                implicitCommand = 's';
                break;
            case 'Q':
                qx = getFloat(str,&idx);
                qy = getFloat(str,&idx);
                cx1 = currx + (2.0 / 3.0 * (qx - currx));
                cy1 = curry + (2.0 / 3.0 * (qy - curry));
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                cx2 = currx + (2.0 / 3.0 * (qx - currx));
                cy2 = curry + (2.0 / 3.0 * (qy - curry));
                lastcurvepoint = NSMakePoint(qx,qy);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'Q';
                break;
            case 'q':
                qx = currx + getFloat(str,&idx);
                qy = curry + getFloat(str,&idx);
                cx1 = currx + (2.0 / 3.0 * (qx - currx));
                cy1 = curry + (2.0 / 3.0 * (qy - curry));
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                cx2 = currx + (2.0 / 3.0 * (qx - currx));
                cy2 = curry + (2.0 / 3.0 * (qy - curry));
                lastcurvepoint = NSMakePoint(qx,qy);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'q';
                break;
            case 'T':
                if (! [@"QqTt" containsChar:lastCommand])
                    lastcurvepoint = NSZeroPoint;
                dx = currx - lastcurvepoint.x;
                dy = curry - lastcurvepoint.y;
                qx = currx + dx;
                qy = curry + dy;
                cx1 = currx + (2.0 / 3.0 * (qx - currx));
                cy1 = curry + (2.0 / 3.0 * (qy - curry));
                currx = getFloat(str,&idx);
                curry = getFloat(str,&idx);
                cx2 = currx + (2.0 / 3.0 * (qx - currx));
                cy2 = curry + (2.0 / 3.0 * (qy - curry));
                lastcurvepoint = NSMakePoint(qx,qy);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 'T';
                break;
            case 't':
                if (! [@"QqTt" containsChar:lastCommand])
                    lastcurvepoint = NSZeroPoint;
                dx = currx - lastcurvepoint.x;
                dy = curry - lastcurvepoint.y;
                qx = currx + dx;
                qy = curry + dy;
                cx1 = currx + (2.0 / 3.0 * (qx - currx));
                cy1 = curry + (2.0 / 3.0 * (qy - curry));
                currx += getFloat(str,&idx);
                curry += getFloat(str,&idx);
                cx2 = currx + (2.0 / 3.0 * (qx - currx));
                cy2 = curry + (2.0 / 3.0 * (qy - curry));
                lastcurvepoint = NSMakePoint(qx,qy);
                [path curveToPoint:NSMakePoint(currx, curry) controlPoint1:NSMakePoint(cx1, cy1) controlPoint2:NSMakePoint(cx2, cy2)];
                implicitCommand = 't';
                break;
			case 'A':
				rx = getFloat(str,&idx);
				ry = getFloat(str,&idx);
				xrot = getFloat(str,&idx);
				largearcflag = getFloat(str,&idx);
				sweepflag = getFloat(str,&idx);
				currx = getFloat(str,&idx);
				curry = getFloat(str,&idx);
				[path lineToPoint:NSMakePoint(currx, curry)];
				implicitCommand = 'A';
				break;
			case 'a':
				rx = getFloat(str,&idx);
				ry = getFloat(str,&idx);
				xrot = getFloat(str,&idx);
				largearcflag = getFloat(str,&idx);
				sweepflag = getFloat(str,&idx);
				currx += getFloat(str,&idx);
				curry += getFloat(str,&idx);
				[path lineToPoint:NSMakePoint(currx, curry)];
				implicitCommand = 'a';
				break;

            case 'z':
            case 'Z':
                [path closePath];
                break;
            default:
                break;
        }
        idx = skipdelims(str,idx);
    }
    return path;
}

static void CGPToBezFunction(void *info, const CGPathElement *element)
{
	NSBezierPath *bez = (__bridge NSBezierPath*)info;
    if (element->type == kCGPathElementAddCurveToPoint)
    {
        [bez curveToPoint:element->points[2] controlPoint1:element->points[0] controlPoint2:element->points[1]];
    }
    else if (element->type == kCGPathElementAddLineToPoint)
    {
		[bez lineToPoint:element->points[0]];
    }
    else if (element->type == kCGPathElementMoveToPoint)
    {
        [bez moveToPoint:element->points[0]];
    }
    else if (element->type == kCGPathElementCloseSubpath)
    {
        [bez closePath];
    }
}

NSBezierPath *bezierPathFromCGPath(CGPathRef path)
{
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
	CGPathApply(path, (__bridge void*)bezierPath, CGPToBezFunction);
	return bezierPath;
}

CGPathRef createCGPathFromNSBezierPath(NSBezierPath *bez)
{
    NSInteger i, numElements;
    
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = [bez elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
		
        for (i = 0; i < numElements; i++)
        {
            switch ([bez elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    break;
            }
        }
        
        // Be sure the path is closed or Quartz may not do valid hit detection.
        /*if (!didClosePath)
            CGPathCloseSubpath(path);*/
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }    
    return immutablePath;
}

static NSPoint *PointsFromBezierPath(NSBezierPath *bez,int *count)
{
    NSInteger i, numElements;
    
    numElements = [bez elementCount];
    if (numElements > 0)
    {
        NSPoint *pathPoints = new NSPoint[numElements+1];
        NSPoint             points[3];
        int idx = 0;
        
        for (i = 0; i < numElements; i++)
        {
            switch ([bez elementAtIndex:i associatedPoints:points])
            {
				case NSMoveToBezierPathElement:
                    pathPoints[idx] = points[0];
                    idx++;
                    break;
                    
				case NSLineToBezierPathElement:
                    pathPoints[idx] = points[0];
                    idx++;
                    break;
                    
				case NSCurveToBezierPathElement:
                    pathPoints[idx] = points[0];
                    idx++;
                    break;
                    
				case NSClosePathBezierPathElement:
                    break;
            }
        }
        if (! NSEqualPoints(pathPoints[idx-1], pathPoints[0]))
            pathPoints[idx++] = points[0];
        *count = idx;
        return pathPoints;
    }
    *count = 0;
    return nil;
}

NSBezierPath *outlinedStrokePath(NSBezierPath *inPath)
{
    CGPathRef cgp = createCGPathFromNSBezierPath(inPath);
    CGPathRef scgp = CGPathCreateCopyByStrokingPath(cgp, NULL, [inPath lineWidth], (CGLineCap)[inPath lineCapStyle], (CGLineJoin)[inPath lineJoinStyle], [inPath miterLimit]);
    NSBezierPath *outPath = bezierPathFromCGPath(scgp);
    CGPathRelease(scgp);
    CGPathRelease(cgp);
    return outPath;
}

@implementation ACSDPath

+ (NSString*)graphicTypeName
   {
	return @"Path";
   }

+(id)pathWithSubPaths:(NSArray*)subPaths
   {
	return [[[ACSDPath alloc]initWithName:@"" fill:nil stroke:nil rect:NSZeroRect layer:nil subPaths:[[subPaths mutableCopy]autorelease]]autorelease];
   }

+(id)pathWithPath:(NSBezierPath*)p
   {
	return [[[ACSDPath alloc]initWithName:@"" fill:nil stroke:nil rect:NSZeroRect layer:nil bezierPath:p]autorelease];
   }

+(id)pathWithSVGPath:(NSBezierPath*)p settings:(NSMutableDictionary*)settings
{
	if ([p isEmpty] || [p elementCount] < 2)
		return nil;
	settings[@"_originalbbox"] = [NSValue valueWithRect:[p bounds]];
	NSAffineTransform *t = [settings objectForKey:@"transform"];
	if (t)
		[p transformUsingAffineTransform:t];
	return [[[ACSDPath alloc]initWithName:@"" fill:nil stroke:nil rect:NSZeroRect layer:nil bezierPath:p]autorelease];
}

+(id)pathWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    NSString *pathString = [xmlnode attributeStringValue:@"d"];
    NSBezierPath *p = bezierPathFromSVGPath(pathString);
	return [ACSDPath pathWithSVGPath:p settings:[settingsStack lastObject]];
}

+(id)polylineWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    NSString *pathString = [xmlnode attributeStringValue:@"points"];
    NSBezierPath *p = bezierPathFromSVGPath(pathString);
	return [ACSDPath pathWithSVGPath:p settings:[settingsStack lastObject]];
}

+(id)polygonWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    NSString *pathString = [xmlnode attributeStringValue:@"points"];
    NSBezierPath *p = bezierPathFromSVGPath(pathString);
	[p closePath];
	return [ACSDPath pathWithSVGPath:p settings:[settingsStack lastObject]];
}

+(id)pathLineWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    float x1 = [xmlnode attributeFloatValue:@"x1"];
    float x2 = [xmlnode attributeFloatValue:@"x2"];
    float y1 = [xmlnode attributeFloatValue:@"y1"];
    float y2 = [xmlnode attributeFloatValue:@"y2"];
    NSBezierPath *p = [NSBezierPath bezierPath];
    [p moveToPoint:NSMakePoint(x1, y1)];
    [p lineToPoint:NSMakePoint(x2, y2)];
	return [ACSDPath pathWithSVGPath:p settings:[settingsStack lastObject]];
}

+(id)pathRectWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    float x = [xmlnode attributeFloatValue:@"x"];
    float y = [xmlnode attributeFloatValue:@"y"];
    float width = [xmlnode attributeFloatValue:@"width"];
    float height = [xmlnode attributeFloatValue:@"height"];
    NSBezierPath *p = [NSBezierPath bezierPathWithRect:NSMakeRect(x, y, width, height)];
	return [ACSDPath pathWithSVGPath:p settings:[settingsStack lastObject]];
}

+(id)ellipseWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    float cx = [xmlnode attributeFloatValue:@"cx"];
    float cy = [xmlnode attributeFloatValue:@"cy"];
    float rx = [xmlnode attributeFloatValue:@"rx"];
    float ry = [xmlnode attributeFloatValue:@"ry"];
    CGRect r = CGRectMake(cx-rx, cy-ry, rx*2, ry*2);
    NSBezierPath *p = [NSBezierPath bezierPathWithOvalInRect:r];
	return [ACSDPath pathWithSVGPath:p settings:[settingsStack lastObject]];
}

+(id)circleWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack
{
    float cx = [xmlnode attributeFloatValue:@"cx"];
    float cy = [xmlnode attributeFloatValue:@"cy"];
    float r = [xmlnode attributeFloatValue:@"r"];
    CGRect rct = CGRectMake(cx-r, cy-r, r*2, r*2);
    NSBezierPath *p = [NSBezierPath bezierPathWithOvalInRect:rct];
	return [ACSDPath pathWithSVGPath:p settings:[settingsStack lastObject]];
}

+(ACSDPath*)aNotBSubPathsFromObjects:(NSArray*)objectArray
   {
	NSInteger ct = [objectArray count];
	ACSDPath *o0 = [objectArray objectAtIndex:0];
	for (NSInteger i = 1;i < ct;i++)
	   {
		ACSDPath *o1 = [objectArray objectAtIndex:i];
		[o1 reversePathWithStrokeList:nil];
		NSArray *vertexList = [ACSDSubPath aNotBBetweenPath:o0 andPath:o1];
		NSMutableArray *subPaths = [GraphicView intersectedSubPathsFromVertexList:vertexList];
		o0 = [[[ACSDPath alloc]initWithName:@"path" fill:nil stroke:nil rect:NSZeroRect layer:nil subPaths:subPaths]autorelease];
	   }
	return o0;
   }

+(ACSDPath*)unionSubPathsFromObjects:(NSArray*)objectArray
   {
	NSInteger ct = [objectArray count];
	ACSDPath *o0 = [objectArray objectAtIndex:(ct - 1)];
	for (NSInteger i = ct - 2;i >= 0;i--)
	   {
		ACSDPath *o1 = [objectArray objectAtIndex:i];
		NSArray *vertexList = [ACSDSubPath intersectionsBetweenPath:o0 andPath:o1];
		NSMutableArray *subPaths = [ACSDSubPath unionSubPathsFromVertexList:vertexList];
		o0 = [[[ACSDPath alloc]initWithName:@"path" fill:nil stroke:nil rect:NSZeroRect layer:nil subPaths:subPaths]autorelease];
	   }
	return o0;
   }

+(ACSDPath*)intersectedSubPathsFromObjects:(NSMutableArray*)objectArray
   {
	NSInteger ct = [objectArray count];
	ACSDPath *o0 = [objectArray objectAtIndex:(ct - 1)];
	for (NSInteger i = ct - 2;i >= 0;i--)
	   {
		ACSDPath *o1 = [objectArray objectAtIndex:i];
		NSArray *vertexList = [ACSDSubPath intersectionsBetweenPath:o0 andPath:o1];
		NSMutableArray *subPaths = [GraphicView intersectedSubPathsFromVertexList:vertexList];
		o0 = [[[ACSDPath alloc]initWithName:@"path" fill:nil stroke:nil rect:NSZeroRect layer:nil subPaths:subPaths]autorelease];
	   }
	return o0;
   }

+(ACSDPath*)xorSubPathsFromObjects:(NSMutableArray*)objectArray
   {
	NSInteger ct = [objectArray count];
	ACSDPath *o0 = [objectArray objectAtIndex:(ct - 1)];
	for (NSInteger i = ct - 2;i >= 0;i--)
	   {
		ACSDPath *o1 = [objectArray objectAtIndex:i];
		NSMutableArray *s0 = [[self aNotBSubPathsFromObjects:[NSArray arrayWithObjects:o1,o0,nil]]subPaths];
		[o1 reversePathWithStrokeList:nil];
		NSMutableArray *s1 = [[self aNotBSubPathsFromObjects:[NSArray arrayWithObjects:o0,o1,nil]]subPaths];
		[s0 addObjectsFromArray:s1];
		o0 = [ACSDPath pathWithSubPaths:s0];
	   }
	return o0;
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
   {
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l])
	   {
		path = [[NSBezierPath bezierPath]retain];
		subPaths = [[NSMutableArray arrayWithCapacity:1]retain];
		[subPaths addObject:[ACSDSubPath subPath]];
		currentSubPathInd = 0;
		isCreating = YES;
		selectedElements = [[NSMutableSet alloc]init];	   
	   }
	return self;
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l bezierPath:(NSBezierPath*)p
   {
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l])
	   {
		path = [p retain];
		subPaths = [[ACSDSubPath subPathsFromBezierPath:path ]retain];
		isCreating = NO;
		addingPointPath = nil;
		[self generatePath];
		[self setBounds:[path controlPointBounds]];
		selectedElements = [[NSMutableSet alloc]init];
	   }
	return self;
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l bezierPath:(NSBezierPath*)p
		   xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a
   {
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l xScale:xs yScale:ys rotation:rot shadowType:st label:lab alpha:a])
	   {
		path = [p retain];
		subPaths = [[ACSDSubPath subPathsFromBezierPath:path ]retain];
		isCreating = NO;
		addingPointPath = nil;
		[self generatePath];
		[self setBounds:[path controlPointBounds]];
		selectedElements = [[NSMutableSet alloc]init];
	   }
	return self;
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l subPaths:(NSMutableArray*)sp
		   xScale:(float)xs yScale:(float)ys rotation:(float)rot shadowType:(ShadowType*)st label:(ACSDLabel*)lab alpha:(float)a
   {
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l xScale:xs yScale:ys rotation:rot shadowType:st label:lab alpha:a])
	   {
		subPaths = [[NSMutableArray arrayWithCapacity:[sp count]]retain];
		[subPaths addObjectsFromArray:sp];
		isCreating = NO;
		addingPointPath = nil;
		[self generatePath];
		[self setBounds:[path controlPointBounds]];
		selectedElements = [[NSMutableSet alloc]init];
	   }
	return self;
   }



-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l subPaths:(NSMutableArray*)sp
   {
    if (self = [super initWithName:n fill:f stroke:str rect:r layer:l])
	   {
		subPaths = [[NSMutableArray arrayWithCapacity:[sp count]]retain];
		[subPaths addObjectsFromArray:sp];
		isCreating = NO;
		addingPointPath = nil;
		[self generatePath];
		[self setBounds:[path controlPointBounds]];
		selectedElements = [[NSMutableSet alloc]init];
	   }
	return self;
   }

- (NSMutableArray*)copySubPaths 
   {
	NSMutableArray *arr = [[NSMutableArray arrayWithCapacity:[subPaths count] + 1]retain];
	for (int i = 0;i < (signed)[subPaths count];i++)
		[arr addObject:[[[subPaths objectAtIndex:i]copy]autorelease]];
	return arr;
   }

- (id)copyWithZone:(NSZone *)zone 
{
	NSMutableArray *arr = [[self copySubPaths]autorelease];
	//    ACSDPath *obj =  [[[self class] allocWithZone:zone] initWithName:[self name] fill:[self fill] stroke:[self stroke] rect:[self bounds]
	//																layer:layer subPaths:arr xScale:xScale 
	//															  yScale:yScale rotation:rotation shadowType:[self shadowType] label:[textLabel copy] alpha:alpha];
	ACSDPath *obj = [super copyWithZone:zone];
	[obj setSubPaths:arr];
	[obj generatePath];
	[obj setBounds:[[obj path] controlPointBounds]];
	
	return obj;
}

-(void)allocHandlePoints
   {
	handlePoints = NULL;
	noHandlePoints = 0;
   }


- (void) encodeWithCoder:(NSCoder*)coder
   {
	[super encodeWithCoder:coder];
	[coder encodeObject:subPaths forKey:@"ACSDPath_subPaths"];
	[coder encodeInteger:currentSubPathInd forKey:@"ACSDPath_currentSubPathInd"];
	[coder encodeInt:isCreating forKey:@"ACSDPath_isCreating"];
   }

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	subPaths = [[coder decodeObjectForKey:@"ACSDPath_subPaths"]retain];
	currentSubPathInd = [coder decodeIntegerForKey:@"ACSDPath_currentSubPathInd"];
	isCreating = [coder decodeIntForKey:@"ACSDPath_isCreating"];
	handlePoints = NULL;
	noHandlePoints = 0;
	path = [[NSBezierPath bezierPath]retain];
	isCreating = NO;
	addingPointPath = nil;
	[self generatePath];
	if (path && [path elementCount] > 1)
		[self setBounds:[path controlPointBounds]];
	else
		[self setBounds:NSZeroRect];
	selectedElements = [[NSMutableSet alloc]init];
	return self;
}

-(void)dealloc
{
	[path release];
	[subPaths release];
	[addingPointPath release];
	[selectedElements release];
	[super dealloc];
}

-(bool)reversePathWithStrokeList:(NSMutableArray*)strokes
   {
	bool lineEndingsChanged = NO;
	if (stroke && strokes && ([stroke lineStart] != [stroke lineEnd]))
	   {
		[self setStroke:[stroke strokeWithReversedLineEndingsFromList:strokes]];
		lineEndingsChanged = YES;
	   }
	NSBezierPath *p = [[self path] bezierPathByReversingPath];
	[self setPath:p];
	[self setSubPaths:[ACSDSubPath subPathsFromBezierPath:p]];
	return lineEndingsChanged;
   }

-(NSMutableArray*)reversedSubPaths
   {
	NSBezierPath *p = [path bezierPathByReversingPath];
	return [ACSDSubPath subPathsFromBezierPath:p];
   }

-(NSMutableArray*)mercatorSubPathsWithRect:(NSRect)r
{
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[subPaths count]];
	for (ACSDSubPath *sp in subPaths)
		[arr addObject:[sp mercatorSubPathWithRect:r]];
	return arr;
}

-(NSMutableArray*)demercatorSubPathsWithRect:(NSRect)r
{
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[subPaths count]];
	for (ACSDSubPath *sp in subPaths)
		[arr addObject:[sp demercatorSubPathWithRect:r]];
	return arr;
}

-(void)setSubPathsAndRebuild:(NSMutableArray*) arr
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSubPathsAndRebuild:subPaths];
    [self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
    [self setSubPaths:arr];
    [self generatePath];
    [self completeRebuild];
}

-(void)applyTransform
   {
	if (!transform)
		return;
	NSMutableArray *arr = [[self copySubPaths]autorelease];
	[arr makeObjectsPerformSelector:@selector(applyTransform:) withObject:transform];
	[self setGraphicTransform:nil];
	[self setSubPathsAndRebuild:arr];
	[self setGraphicRotation:0.0 notify:YES];
	[self setGraphicXScale:1.0 notify:YES];
	[self setGraphicYScale:1.0 notify:YES];
   }

-(void)permanentScale:(float)sc transform:(NSAffineTransform*)t
{
	NSMutableArray *arr = [[self copySubPaths]autorelease];
	[arr makeObjectsPerformSelector:@selector(applyTransform:) withObject:t];
	[self setGraphicTransform:nil];
	[self setSubPathsAndRebuild:arr];
}

-(NSMutableArray*)transformedSubPaths
   {
	NSMutableArray *arr = [[self copySubPaths]autorelease];
	if (transform)
		[arr makeObjectsPerformSelector:@selector(applyTransform:) withObject:transform];
	return arr;
   }

- (void)completeRebuild
   {
	if ([path elementCount] > 1)
	   [self setBounds:[path controlPointBounds]];
	else 
		[self setBounds:NSZeroRect];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
   }

- (void)flipH
   {
    NSBezierPath *p = path;
	NSAffineTransform *tf = [NSAffineTransform transform];
	NSPoint pt = [self centrePoint];
	[tf translateXBy:-pt.x yBy:-pt.y];
	NSAffineTransform *tf2 = [NSAffineTransform transform];
	[tf2 scaleXBy:-1.0 yBy:1.0];
	[tf appendTransform:tf2];
	tf2 = [NSAffineTransform transform];
	[tf2 translateXBy:pt.x yBy:pt.y];
	[tf appendTransform:tf2];
	p = [tf transformBezierPath:p];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setPath:p];
	[self setSubPaths:[ACSDSubPath subPathsFromBezierPath:p]];	
	[self setBounds:[path controlPointBounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
   }

- (void)flipV
   {
    NSBezierPath *p = path;
	NSAffineTransform *tf = [NSAffineTransform transform];
	NSPoint pt = [self centrePoint];
	[tf translateXBy:-pt.x yBy:-pt.y];
	NSAffineTransform *tf2 = [NSAffineTransform transform];
	[tf2 scaleXBy:1.0 yBy:-1.0];
	[tf appendTransform:tf2];
	tf2 = [NSAffineTransform transform];
	[tf2 translateXBy:pt.x yBy:pt.y];
	[tf appendTransform:tf2];
	p = [tf transformBezierPath:p];
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	[self setPath:p];
	[self setSubPaths:[ACSDSubPath subPathsFromBezierPath:p]];	
	[self setBounds:[path controlPointBounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
   }


- (BOOL)closePathWithEvent:(NSEvent *)theEvent inView:(GraphicView *)view 
   {
    while (1)
	   {
        theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        if ([theEvent type] == NSLeftMouseUp)
            break;
       }
	ACSDPathElement *firstEl = [[self pathElements] objectAtIndex:0];
	if ([theEvent modifierFlags] & NSAlternateKeyMask)
		if ([firstEl hasPostControlPoint])
		   {
			[firstEl setPreCPFromPostCP];
			[firstEl setHasPreControlPoint:YES];
			[firstEl setControlPointsContinuous:YES];
		   }
	[[self currentSubPath]setIsClosed:YES];
	[self generatePath];
	[self setBounds:[path controlPointBounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	[view setCreatingPath:nil];
	[[view window]invalidateCursorRectsForView:view];
	return YES;
   }

- (BOOL)trackAndAddPointWithEvent:(NSEvent *)theEvent inView:(GraphicView *)view 
   {
    NSPoint origPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
	[self setActualAddingPoint:origPoint];
	NSPoint lastPt=NSZeroPoint;
	[self lastPoint:&lastPt];
	if ([theEvent modifierFlags] & NSShiftKeyMask)
	   {
		restrictTo45(lastPt,&origPoint);
	   }
	[self setAddingPoint:origPoint];
	[view setHandleBitsH:(int)origPoint.x v:(int)origPoint.y];
	if (NSPointInRect(origPoint,[self handleRect:[[[self pathElements] objectAtIndex:0]point]magnification:[view magnification]]))
	   {
		[self setAddingPoints:NO];
		[view setCreatingPath:nil];
		return [self closePathWithEvent:theEvent inView:view];
	   }
	NSPoint lastPoint = origPoint;
	ACSDPathElement *el = [[ACSDPathElement alloc]initWithPoint:origPoint preControlPoint:origPoint postControlPoint:origPoint hasPreControlPoint:NO
			hasPostControlPoint:NO isLineToPoint:YES];
	[[self pathElements] addObject:[el autorelease]];
    while (1)
	   {
        theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        NSPoint currPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		if ([theEvent modifierFlags] & NSShiftKeyMask)
		   {
			restrictTo45(lastPt,&currPoint);
		   }
		currPoint.y = [view adjustHSmartGuide:currPoint.y tool:1];
		currPoint.x = [view adjustVSmartGuide:currPoint.x tool:1];
		if (!NSEqualPoints(lastPoint,currPoint))
		   {
			[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			[el setPostControlPoint:currPoint];
			[el setPreCPFromPostCP];
			[el setHasPreControlPoint:YES];
			[el setHasPostControlPoint:YES];
			lastPoint = currPoint;
			[self generatePath];
			[self setBounds:[path controlPointBounds]];
			[self constructAddingPointPath];
			[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
			NSSize sz = NSMakeSize(currPoint.x - origPoint.x,currPoint.y - origPoint.y);
			   NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithPoint:currPoint],@"xy",
									  [NSValue valueWithSize:sz],@"dxdy",
									  [NSNumber numberWithFloat:angleForPoints(origPoint,currPoint)],@"theta",
									  [NSNumber numberWithFloat:pointDistance(origPoint,currPoint)],@"dist",
									  nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:ACSDMouseDidMoveNotification object:self userInfo:dict2];
		   }
        if ([theEvent type] == NSLeftMouseUp)
            break;
       }
	if (NSEqualPoints([el point],[el postControlPoint]))
	   {
		[el setHasPreControlPoint:NO];
		[el setHasPostControlPoint:NO];
	   }
	else
		[el setControlPointsContinuous:YES];
	[self generatePath];
    [self setBounds:[path controlPointBounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	[[view window]invalidateCursorRectsForView:view];
    return YES;
   }

-(BOOL)lastPoint:(NSPoint*)pt
   {
	if ([subPaths count] == 0)
		return NO;
	ACSDSubPath *sp = [subPaths objectAtIndex:[subPaths count]-1];
	if ([[sp pathElements]count] == 0)
		return NO;
	ACSDPathElement *el = [[sp pathElements] objectAtIndex:[[sp pathElements] count]-1];
	*pt = [el point];
	return YES;
   }

-(BOOL)lastControlPoint:(NSPoint*)pt
   {
	if ([subPaths count] == 0)
		return NO;
	ACSDSubPath *sp = [subPaths objectAtIndex:[subPaths count]-1];
	if ([[sp pathElements]count] == 0)
		return NO;
	ACSDPathElement *el = [[sp pathElements] objectAtIndex:[[sp pathElements] count]-1];
	if ([el hasPostControlPoint])
	   {
		*pt = [el postControlPoint];
		return YES;
	   }
	return NO;
   }

-(NSRect)controlPointBounds
   {
	NSRect r = [super controlPointBounds];
	NSPoint pt;
	if ([self lastControlPoint:&pt])
		r = expandRectToPoint(r,pt);
	return r;
   }

- (ACSDSubPath*)currentSubPath
   {
	if (currentSubPathInd > -1 && currentSubPathInd < [subPaths count])
		return [subPaths objectAtIndex:currentSubPathInd];
	return nil;
   }

- (void)addPoint:(NSPoint)pt 
   {
	[path lineToPoint:pt];
	[self setBounds:[path bounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
   }

- (void)setPath:(NSBezierPath*)p 
   {
	if (path)
		[path release];
	path = [p retain];
   }

- (void)setAddingPointPath:(NSBezierPath*)p 
   {
	if (p == addingPointPath)
		return;
	if (addingPointPath)
		[addingPointPath release];
	addingPointPath = [p retain];
   }

- (void)setSubPaths:(NSMutableArray*)p
   {
	if (subPaths)
		[subPaths release];
	subPaths = [p retain];
   }

- (NSMutableArray*)subPaths
   {
    return subPaths;
   }

void generateSubPath(NSBezierPath* path,NSMutableArray* pathElements,BOOL isClosed)
   {
	NSInteger ct = [pathElements count];
	if (ct == 0)
		return;
	NSPoint lastCP,thisPreControlpoint;
	ACSDPathElement *element = [pathElements objectAtIndex:0];
	[path moveToPoint:[element point]];
	BOOL lastHasPostControlPoint = [element hasPostControlPoint];
	if (lastHasPostControlPoint)
		lastCP = [element postControlPoint];
	else
		lastCP = [element point];
	for (NSInteger i = 1;i < ct;i++)
	   {
		element = [pathElements objectAtIndex:i];
		if ([element isLineToPoint])
		   {
			if (lastHasPostControlPoint || [element hasPreControlPoint])
			   {
				if ([element hasPreControlPoint])
					thisPreControlpoint = [element preControlPoint];
				else
					thisPreControlpoint = [element point];
				[path curveToPoint:[element point]controlPoint1:lastCP controlPoint2:thisPreControlpoint];
			   }
			else
				[path lineToPoint:[element point]];
		   }
		else
			[path moveToPoint:[element point]];
		lastHasPostControlPoint = [element hasPostControlPoint];
		if (lastHasPostControlPoint)
			lastCP = [element postControlPoint];
		else
			lastCP = [element point];
	   }
	if (isClosed)
	   {
		element = [pathElements objectAtIndex:0];
		if (lastHasPostControlPoint || [element hasPreControlPoint])
		   {
			if ([element hasPreControlPoint])
				thisPreControlpoint = [element preControlPoint];
			else
				thisPreControlpoint = [element point];
			[path curveToPoint:[element point]controlPoint1:lastCP controlPoint2:thisPreControlpoint];
		   }
		else
			[path lineToPoint:[element point]];
		[path closePath];
	   }
   }

void bezierPathFromSubPath(NSArray* subPaths,NSBezierPath *path)
   {
	NSInteger ct = [subPaths count];
	[path removeAllPoints];
	if (ct == 0)
		return;
	for (NSInteger i = 0;i < ct;i++)
	   {
		ACSDSubPath *sub = [subPaths objectAtIndex:i];
		generateSubPath(path,[sub pathElements],[sub isClosed]);
	   }
   }
   
- (void)generatePath 
   {
	if (path == nil)
		path = [[NSBezierPath bezierPath]retain];
	bezierPathFromSubPath(subPaths,path);
	[self setDisplayBoundsValid:NO];
   }

- (void)addSubPath:(ACSDSubPath*)asp 
   {
	[subPaths addObject:asp];
   }

- (void)addSubPaths:(NSArray*)arr 
   {
	NSInteger ct = [arr count];
	if (ct == 0)
		return;
	for (NSInteger i = 0;i < ct;i++)
		[self addSubPath:[subPaths objectAtIndex:i]];
	[self generatePath];
   }

- (NSBezierPath*)path
{
	if (path == nil)
		[self generatePath];
    return path;
}

- (NSBezierPath*)addingPointPath
{
    return addingPointPath;
}

- (NSBezierPath *)bezierPath
{
    return [self path];
}

-(NSPoint)centroid
{
    int ct;
    NSPoint *points = PointsFromBezierPath([self bezierPath], &ct);
    if (ct == 0)
        return NSMakePoint(0,0);
    NSPoint pt = Centroid(points, ct);
    delete[] points;
    return pt;
}

-(BOOL)hasClosedPath
{
	return NO;
}

- (NSMutableArray*)pathElements
   {
    return [[self currentSubPath]pathElements];
   }

- (void)setIsCreating:(BOOL)b
   {
    isCreating = b;
   }

-(void)computeHandlePoints
   {
   }

-(void)recalcBounds
   {
	[self setBounds:[path controlPointBounds]];
   }

-(NSRect)displayBoundsSansShadow
   {
	NSInteger ct = [[self pathElements] count];
	if ((ct  == 0) && !(addingPoints && addingPointPath))
		return NSZeroRect;
	NSRect r = [super displayBoundsSansShadow];
	if (addingPoints && addingPointPath)
	   {
		NSRect pr = [addingPointPath controlPointBounds];
		if (pr.size.width == 0.0)
			pr.size.width = 1.0;
		if (pr.size.height == 0.0)
			pr.size.height = 1.0;
		r = NSUnionRect(r,pr);
	   }
	if (ct > 0)
	   {
	    ACSDPathElement *el = [[self pathElements] objectAtIndex:ct - 1];
		r = NSUnionRect(r,[el controlPointBounds]);
	   }
    return  r;
   }

-(void)offsetPointValue:(NSValue*)vp
{
	[subPaths makeObjectsPerformSelector:@selector(offsetPointValue:)withObject:vp];
}

- (void)moveBy:(NSPoint)vector
{
	[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	vector.x /= xScale;
	vector.y /= yScale;
	[self offsetPointValue:[NSValue valueWithPoint:vector]];
	if (rotation != 0.0)
	{
		rotationPoint.x += vector.x;
		rotationPoint.y += vector.y;
		[self computeTransform];
	}
	[self generatePath];
	[self setBounds:[path controlPointBounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
	[self invalidateConnectors];
	[self postChangeOfBounds];
}

- (void)startBoundsManipulation
{
}

- (void)stopBoundsManipulation
{
}

- (void)addHandleRectsForView:(GraphicView*)view
{
    int selectedTool = [[ToolWindowController sharedToolWindowController:nil] currentTool];
    if (selectedTool != ACSD_SPLIT_POINT_TOOL)
		return;
	NSRect visRect = [view visibleRect];
	for (ACSDSubPath *sp in subPaths)
	{
		for (ACSDPathElement *el in [sp pathElements])
		{
			NSRect hR = [self handleRect:[el point] magnification:[view magnification]];
			if (NSIntersectsRect(hR, visRect))
				[view addCursorRect:hR cursor:[NSCursor splitCursorPoint]];
		}
	}
}


-(ACSDPathElement*) pathElementForKnob:(const KnobDescriptor&)kd
   {
	if (kd.subPath > (int)[subPaths count])
		return nil;
	ACSDSubPath *subPath = [subPaths objectAtIndex:kd.subPath];
	NSArray *pathElements = [subPath pathElements];
	if (kd.knob >= (int)[pathElements count])
		if ([subPath isClosed] && kd.knob == (int)[pathElements count])
			return [pathElements objectAtIndex:0];
		else
			return nil;
	return [pathElements objectAtIndex:kd.knob];
   }

-(KnobDescriptor)nearestKnobForPoint:(NSPoint)pt
   {
	float squaredDist = 10000*10000;
	KnobDescriptor minKnob = KnobDescriptor(NoKnob);
	for (unsigned i = 0;i < [subPaths count];i++)
	   {
		int k = [[subPaths objectAtIndex:i]nearestKnobForPoint:pt squaredDist:squaredDist];
		if (k > -1)
			minKnob = KnobDescriptor(i,k,0);
	   }
	return minKnob;
   }

-(NSPoint)pointForKnob:(const KnobDescriptor&)kd
   {
	ACSDPathElement *pe = [self pathElementForKnob:kd];
	if (pe)
		return [pe point];
	return NSZeroPoint;
   }

- (void)uChangeElement:(ACSDPathElement*)el point:(NSPoint)pt preControlPoint:(NSPoint)preCP postControlPoint:(NSPoint)postCP 
	hasPreControlPoint:(BOOL) hasPreCP hasPostControlPoint:(BOOL)hasPostCP isLineToPoint:(BOOL)iltp 
	controlPointsContinuous:(BOOL) cpc
   {
    [[[self undoManager] prepareWithInvocationTarget:self] uChangeElement:el point:[el point] 
				preControlPoint:[el preControlPoint] postControlPoint:[el postControlPoint]
				hasPreControlPoint:[el hasPreControlPoint] hasPostControlPoint:[el hasPostControlPoint]
				isLineToPoint:[el isLineToPoint] controlPointsContinuous:[el controlPointsContinuous]];
	[el setWithPoint:pt preControlPoint:preCP postControlPoint:postCP 
		hasPreControlPoint: hasPreCP hasPostControlPoint:hasPostCP isLineToPoint:iltp controlPointsContinuous:cpc];
	[self generatePath];
	[self setBounds:[path controlPointBounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
   }

- (BOOL)trackControlPointForKnob:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent inView:(GraphicView*)view mirrorLengths:(BOOL)mirrorLengths
{
	NSPoint point=NSZeroPoint,lastPoint,originalOtherPoint;
	ACSDPathElement *el = [self pathElementForKnob:kd];
	ACSDPathElement *newEl = [[el copy]autorelease];
	if (kd.controlPoint == 1)
		originalOtherPoint = [el postControlPoint];
	else
		originalOtherPoint = [el preControlPoint];
	if (mirrorLengths)
	{
		[newEl setHasPreControlPoint:YES];
		[newEl setHasPostControlPoint:YES];
		[newEl setControlPointsContinuous:YES];
	}
	lastPoint = NSMakePoint(0.0,0.0);
	BOOL hasSplitPoints = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"vis"]];
	BOOL can = NO,periodicStarted=NO;
	while (1)
	{
		if (opCancelled)
		{
			[self setOpCancelled:NO];
			can = YES;
			break;
		}
		theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask | NSKeyDownMask | NSPeriodicMask)];
		if ([theEvent type] == NSKeyDown)
		{
			[view keyDown:theEvent];
			continue;
		}
		if ([theEvent type] == NSPeriodic)
		{
			[view scrollRectToVisible:RectFromPoint(point,30.0,[view magnification])];
			point = [view convertPoint:[[view window] mouseLocationOutsideOfEventStream] fromView:nil];
		}
		else
			if ([theEvent type] != NSFlagsChanged)
				point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		point.y = [view adjustHSmartGuide:point.y tool:1];
		point.x = [view adjustVSmartGuide:point.x tool:1];
		if (!NSEqualPoints(point,lastPoint))
		{
			NSPoint newPoint = [self invertPoint:point];
			[view invalidateGraphic:self];
			if (NSPointInRect(newPoint,[self handleRect:[newEl point]magnification:[view magnification]]))
			{
				newPoint = [newEl point];
				if (kd.controlPoint == 1)
					[newEl setHasPreControlPoint:NO];
				else
					[newEl setHasPostControlPoint:NO];
				if (!hasSplitPoints && !mirrorLengths && [newEl controlPointsContinuous])
				{
					hasSplitPoints = true;
					[newEl setControlPointsContinuous:NO];
					if (kd.controlPoint == 1)
						[newEl setPostControlPoint:originalOtherPoint];
					else
						[newEl setPreControlPoint:originalOtherPoint];
				}
			}
			else
				if (kd.controlPoint == 1)
					[newEl setHasPreControlPoint:YES];
				else
					[newEl setHasPostControlPoint:YES];
			if (kd.controlPoint == 1)
			{
				[newEl setPreControlPoint:newPoint];
				if (mirrorLengths)
					[newEl setPostCPFromPreCP];
				else if ([newEl hasPostControlPoint] && [newEl controlPointsContinuous])
					[newEl setPostCPFromPreCPAngle];
			}
			else
			{
				[newEl setPostControlPoint:newPoint];
				if (mirrorLengths)
					[newEl setPreCPFromPostCP];
				else if ([newEl hasPreControlPoint] && [newEl controlPointsContinuous])
					[newEl setPreCPFromPostCPAngle];
			}
			[self uChangeElement:el point:[newEl point] preControlPoint:[newEl preControlPoint] postControlPoint:[newEl postControlPoint]
			  hasPreControlPoint:[newEl hasPreControlPoint] hasPostControlPoint:[newEl hasPostControlPoint]
				   isLineToPoint:[newEl isLineToPoint]controlPointsContinuous:[newEl controlPointsContinuous]];
			[self postChangeOfBounds];
			[ACSDGraphic postChangeFromAnchorPoint:originalOtherPoint toPoint:point];
			lastPoint = point;
			[self setOutlinePathValid:NO];
		}
		periodicStarted = [view scrollIfNecessaryPoint:point periodicStarted:periodicStarted];
		if ([theEvent type] == NSLeftMouseUp)
			break;
	}
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSDShowCoordinatesNotification object:self
													  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"vis"]];
	[[self undoManager] setActionName:@"Move Control Point"];
	return !can;
}

-(BOOL)trackInit:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent inView:(GraphicView*)view ok:(BOOL*)success
{
    if (kd.controlPoint > 0)
	{
	    *success = [self trackControlPointForKnob:kd withEvent:theEvent inView:view mirrorLengths:NO];
		return YES;
	}
	if ([theEvent modifierFlags] & NSCommandKeyMask)
	{
	    KnobDescriptor k(kd.subPath,kd.knob,1);
		*success = [self trackControlPointForKnob:k withEvent:theEvent inView:view mirrorLengths:YES];
		return YES;
	}
	return NO;
}

-(void)trackMid:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent point:(NSPoint)point lastPoint:(NSPoint)lastPoint
selectedGraphics:(NSSet*)selectedGraphics
{
	NSPoint movement = NSMakePoint(point.x - lastPoint.x,point.y - lastPoint.y);
	if (selectedGraphics)
		[selectedGraphics makeObjectsPerformSelector:@selector(moveSelectedElementsBy:) withObject:[NSValue valueWithPoint:movement]];
	else
		[self resizeByMovingKnob:kd toPoint:point event:theEvent constrain:(([theEvent modifierFlags] & NSShiftKeyMask)!=0)
					aroundCentre:(([theEvent modifierFlags] & NSAlternateKeyMask)!=0)];
}

- (float)roughArea
   {
	float area = 0.0;
	NSEnumerator *subPathEnum = [subPaths objectEnumerator];
	ACSDSubPath *subPath;
	while ((subPath = [subPathEnum nextObject]) != nil)
		area += [subPath roughArea];
	return area;
   }

- (BOOL)isCounterClockWise
   {
	return [self roughArea] >= 0.0;
   }

- (void)makeSubPathsCounterClockWise
   {
	NSEnumerator *subPathEnum = [subPaths objectEnumerator];
	ACSDSubPath *subPath;
	while ((subPath = [subPathEnum nextObject]) != nil)
		if (![subPath isCounterClockWise])
			[subPath reverse];
	[self generatePath];
   }


- (BOOL)splitPathWithEvent:(NSEvent *)theEvent copy:(BOOL)copy inView:(GraphicView*)view
   {
	NSPoint hitPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
//	NSEnumerator *subPathEnum = [subPaths objectEnumerator];
	unsigned subPathInd;
	ACSDSubPath *subPath;
	for (subPathInd=0;subPathInd < [subPaths count];subPathInd++)
	{
		subPath = [subPaths objectAtIndex:subPathInd];
		if ([subPath splitPathWithPoint:hitPoint copy:copy path:self pathInd:subPathInd])
		   {
//			KnobDescriptor k(subPathInd,index,1);
//			[self uInsertPathElement:elm forKnob:k];
			[self generatePath];
			[self completeRebuild];
			return YES;
		   }
	}
	return NO;
   }

- (BOOL)removePathElementWithEvent:(NSEvent *)theEvent inView:(GraphicView*)view
{
    NSPoint hitPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
    for (NSUInteger i = 0,ct = [subPaths count];i < ct;i++)
    {
           ACSDSubPath *subPath = [subPaths objectAtIndex:i];
           ACSDSubPath *newSubPath=nil;
           if ([subPath removePathElementWithPoint:hitPoint newSubPath:&newSubPath])
           {
               if (newSubPath)
                   [subPaths insertObject:newSubPath atIndex:i+1];
               [self generatePath];
               [self completeRebuild];
               return YES;
           }
    }
    return NO;
}

+ (NSMutableArray*)outlineStrokeFromPath:(ACSDPath*)path
   {
	float strokeWidth = [[path stroke] lineWidth];
	ACSDSubPath *subPath;
	ACSDLineEnding *lineStart,*lineEnd;
	lineStart = [[path stroke] lineStart];
	lineEnd = nil;
	NSArray *subPaths = [path subPaths];
	NSMutableArray *resultSubpaths = [NSMutableArray arrayWithCapacity:[subPaths count]];
	for (unsigned i = 0;i < [subPaths count];i++)
	   {
		if (i == 1)
			lineStart = nil;
		if (i == [subPaths count] - 1)
			lineEnd = [[path stroke] lineEnd];
		subPath = [subPaths objectAtIndex:i];
		if ([[[path stroke] dashes]count] > 0)
			[resultSubpaths addObjectsFromArray:[subPath outlineDashedStroke:strokeWidth lineStart:lineStart lineEnd:lineEnd 
																	 lineCap:[[path stroke] lineCap]dashes:[[path stroke] dashes] dashPhase:[[path stroke] dashPhase]]];
		else
			[resultSubpaths addObjectsFromArray:[subPath outlineStroke:strokeWidth lineStart:lineStart lineEnd:lineEnd lineCap:[[path stroke] lineCap]]];
	   }
	return resultSubpaths;
   }

- (ACSDPath*)outlineStroke
{
	float strokeWidth = [stroke lineWidth];
	ACSDSubPath *subPath;
	ACSDLineEnding *lineStart,*lineEnd;
	lineStart = [stroke lineStart];
	lineEnd = nil;
	NSMutableArray *resultSubpaths = [NSMutableArray arrayWithCapacity:[subPaths count]];
	for (unsigned i = 0;i < [subPaths count];i++)
    {
		if (i == 1)
			lineStart = nil;
		if (i == [subPaths count] - 1)
			lineEnd = [stroke lineEnd];
		subPath = [subPaths objectAtIndex:i];
		if ([[stroke dashes]count] > 0)
			[resultSubpaths addObjectsFromArray:[subPath outlineDashedStroke:strokeWidth lineStart:lineStart lineEnd:lineEnd
                                                                     lineCap:[stroke lineCap]dashes:[stroke dashes] dashPhase:[stroke dashPhase]]];
		else
			[resultSubpaths addObjectsFromArray:[subPath outlineStroke:strokeWidth lineStart:lineStart lineEnd:lineEnd lineCap:[stroke lineCap]]];
    }
	ACSDPath *acsdPath = [[[ACSDPath alloc]initWithName:[NSString stringWithFormat:@"%@Stroke",self.name] fill:nil stroke:nil
                                                  rect:[self bounds] layer:[self layer] subPaths:resultSubpaths]autorelease];
	return acsdPath;
}


- (void)trackSplitKnob:(KnobDescriptor&)kd withEvent:(NSEvent *)theEvent copy:(BOOL)copy inView:(GraphicView*)view
{
	NSInteger elInd = kd.knob;
	NSInteger subPathInd = kd.subPath;
	ACSDSubPath *subPath = [subPaths objectAtIndex:subPathInd];
	ACSDPathElement *el = [[subPath pathElements] objectAtIndex:elInd];
	ACSDPathElement *el2 = [[el copy]autorelease];
	[el setHasPostControlPoint:NO];
	[el2 setHasPreControlPoint:NO];
	[[subPath pathElements]insertObject:el2 atIndex:elInd+1];
	if (copy)
		kd.knob++;
	else
	{
		if ([subPath isClosed])
		{
			[subPath splitAndRotateAtIndex:elInd+1];
			kd.knob = 0;
			//			for (int i = 0;i < subPathInd;i++)
			//				knob += [[subPaths objectAtIndex:i]count];
		}
		else
		{
			ACSDSubPath *sp = [ACSDSubPath subPath];
			[subPaths insertObject:sp atIndex:subPathInd+1];
			for (NSUInteger i = elInd+1;i<[[subPath pathElements]count];i++)
				[[sp pathElements]addObject:[[subPath pathElements]objectAtIndex:i]];
			[[subPath pathElements]removeObjectsInRange:NSMakeRange(elInd+1,[[subPath pathElements]count]-(elInd+1))];
			kd.knob++;
		}
	}
//	[self trackKnob:kd withEvent:theEvent inView:view selectedGraphics:[NSSet setWithObject:self]];
	[view trackGraphic:self knob:kd withEvent:theEvent selectedGraphics:[NSSet setWithObject:self]];
}

-(void)createInit:(NSPoint)anchorPoint event:(NSEvent*)theEvent
{
	ACSDPathElement *el = [[ACSDPathElement alloc]initWithPoint:anchorPoint preControlPoint:anchorPoint postControlPoint:anchorPoint hasPreControlPoint:NO
											hasPostControlPoint:NO isLineToPoint:NO];
	[[self pathElements] addObject:[el autorelease]];
	[self generatePath];
    [self setBounds:NSMakeRect(anchorPoint.x, anchorPoint.y, 0.0, 0.0)];
}

-(void)createMid:(NSPoint)anchorPoint currentPoint:(NSPoint*)currPoint event:(NSEvent*)theEvent
{
	ACSDPathElement *el = [[self pathElements]objectAtIndex:0];
	[el setPostControlPoint:*currPoint];
	[el setHasPostControlPoint:YES];
	[self setAddingPoint:*currPoint];
	[self setAddingPoints:YES];
	[self generatePath];
	[self constructAddingPointPath];
	[self setBounds:rectFromPoints(anchorPoint,*currPoint)];
}

-(BOOL)createCleanUp:(BOOL)cancelled
{
	return !cancelled;
}

/*
- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(GraphicView *)view 
{
    NSPoint anchorPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil],currPoint=NSZeroPoint;
	[self createInit:anchorPoint];
	NSPoint lastPoint = anchorPoint;
	[ACSDGraphic postShowCoordinates:YES];
	BOOL can = NO,periodicStarted=NO;
    while (1)
	{
		if (can = opCancelled)
		{
			[self setOpCancelled:NO];
			break;
		}
        theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSKeyDownMask | NSPeriodicMask)];
		if ([theEvent type] == NSKeyDown)
		{
			[view keyDown:theEvent];
			continue;
		}
        if ([theEvent type] == NSPeriodic)
		{
			[view scrollRectToVisible:RectFromPoint(currPoint,30.0,[view magnification])];
			currPoint = [view convertPoint:[[view window] mouseLocationOutsideOfEventStream] fromView:nil];
		}
		else
			currPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
		if (!NSEqualPoints(lastPoint,currPoint))
		{
			currPoint.y = [view adjustHSmartGuide:currPoint.y tool:1];
			currPoint.x = [view adjustVSmartGuide:currPoint.x tool:1];
			[self invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			[self createMid:anchorPoint currentPoint:&currPoint modifiers:[theEvent modifierFlags]];
			[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
 		    [self postChangeOfBounds];
		    [ACSDGraphic postChangeFromAnchorPoint:anchorPoint toPoint:currPoint];
			lastPoint = currPoint;
		}
		periodicStarted = [view scrollIfNecessaryPoint:currPoint periodicStarted:periodicStarted];
        if ([theEvent type] == NSLeftMouseUp)
            break;
	}
	if (periodicStarted)
		[NSEvent stopPeriodicEvents];
	[ACSDGraphic postShowCoordinates:NO];
	isCreating = NO;
    return !can;
}*/

- (KnobDescriptor)knobUnderPoint:(NSPoint)point view:(GraphicView*)gView
   {
	if (transform)
		point = [self invertPoint:point];
	for (unsigned int j = 0;j < [subPaths count];j++)
	   {
		ACSDSubPath *subPath = [subPaths objectAtIndex:j];
		NSInteger ct = [[subPath pathElements] count];
		for (NSInteger i = ct - 1;i >= 0;i--)
		   {
			ACSDPathElement *el = [[subPath pathElements] objectAtIndex:i];
			if (NSPointInRect(point,[self handleRect:[el point]magnification:[gView magnification]]))
				return KnobDescriptor(j,i,0);
			if ([el hasPreControlPoint])
				if (NSPointInRect(point,[self handleRect:[el preControlPoint]magnification:[gView magnification]]))
					return KnobDescriptor(j,i,1);
			if ([el hasPostControlPoint])
				if (NSPointInRect(point,[self handleRect:[el postControlPoint]magnification:[gView magnification]]))
					return KnobDescriptor(j,i,2);
		   }
	   }
    return KnobDescriptor(NoKnob);
   }

- (KnobDescriptor)knobOrLineUnderPoint:(NSPoint)point view:(GraphicView*)gView
   {
	KnobDescriptor kd = [self knobUnderPoint:point view:gView];
	if (kd.knob != NoKnob)
		return kd;
	for (unsigned int j = 0;j < [subPaths count];j++)
	   {
		ACSDSubPath *subPath = [subPaths objectAtIndex:j];
		NSInteger ct = [[subPath pathElements] count];
		for (NSInteger i = ct - 1;i >= 0;i--)
		   {
			ACSDPathElement *el = [[subPath pathElements] objectAtIndex:i];
			ACSDPathElement *nextEl = nil;
			if (i + 1 < ct)
				nextEl = [[subPath pathElements] objectAtIndex:i+1];
			else if ([subPath isClosed])
				nextEl = [[subPath pathElements] objectAtIndex:0];
			if (nextEl)
			   {
				CGFloat dummy,dummy2;
				NSPoint dummyPt;
				if ([el hasPostControlPoint] || [nextEl hasPreControlPoint])
				   {
					if (testCurveHit([el point],[nextEl point],[el postControlPoint],[nextEl preControlPoint],point,dummy,dummyPt,dummy2,4.0,2.0,0.0,1.0))
						return KnobDescriptor(j,i,0,YES);
				   }
				else
				   {
					if (testLineSegmentHit([el point],[nextEl point],point,4.0))
						return KnobDescriptor(j,i,0,YES);
				   }
			   }
		   }
	   }
    return KnobDescriptor(NoKnob);
	
   }

- (void)uMoveKnob:(KnobDescriptor)kd toPoint:(NSPoint)point
   {
	[self invalidateInView];
	ACSDPathElement *el = [self pathElementForKnob:kd];
    [[[self undoManager] prepareWithInvocationTarget:self] uMoveKnob:kd toPoint:[el point]];
	[el moveToPoint:point];
	[self generatePath];
	[self setBounds:[path controlPointBounds]];
	[self invalidateGraphicSizeChanged:YES shapeChanged:YES redraw:YES notify:NO];
   }

- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd by:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain
   {
	if (transform)
		point = [self invertPoint:point];
	NSPoint curPoint = [[self pathElementForKnob:kd]point];
	if (point.x != 0.0 || point.y != 0.0)
		[self uMoveKnob:kd toPoint:NSMakePoint(point.x + curPoint.x,point.y + curPoint.y)];
	return kd;
   }

- (KnobDescriptor)resizeByMovingKnob:(KnobDescriptor)kd toPoint:(NSPoint)point event:(NSEvent *)theEvent constrain:(BOOL)constrain aroundCentre:(BOOL)aroundCentre
   {
	if (transform)
		point = [self invertPoint:point];
	[self uMoveKnob:kd toPoint:point];
	return kd;
   }

-(void)moveSelectedElementsBy:(NSValue*)amt
   {
	NSPoint amount = [amt pointValue];
	if (amount.x == 0.0 && amount.y == 0.0)
		return;
	if ([[self selectedElements] count] == 0)
		return;
	NSMutableSet *knobs = [NSMutableSet setWithCapacity:[selectedElements count]];
    NSEnumerator *objEnum = [selectedElements objectEnumerator];
    SelectedElement *element;
    while ((element = [objEnum nextObject]) != nil)
	   {
		KnobDescriptor kd = [element knobDescriptor];
		if (kd.isLine)
		   {
			KnobDescriptor k(kd.subPath,kd.knob,kd.controlPoint,NO);
			[knobs addObject:[SelectedElement SelectedElementWithKnobDescriptor:k]];
			k.knob++;
			[knobs addObject:[SelectedElement SelectedElementWithKnobDescriptor:k]];
		   }
		else
			[knobs addObject:[SelectedElement SelectedElementWithKnobDescriptor:kd]];
	   }
    objEnum = [knobs objectEnumerator];
    while ((element = [objEnum nextObject]) != nil)
	   {
		[self resizeByMovingKnob:[element knobDescriptor] by:amount event:nil constrain:NO];
	   }
   }

-(void)constructAddingPointPath
   {
	if (addingPoints)
	   {
		NSInteger ct = [subPaths count];
		if (ct > 0)
		   {
			NSMutableArray *tempSubPaths = [NSMutableArray arrayWithCapacity:ct];
			for (int i = 0;i < ct;i++)
				[tempSubPaths addObject:[[[subPaths objectAtIndex:i]copy]autorelease]];
			ACSDPathElement *el = [[ACSDPathElement alloc]initWithPoint:addingPoint preControlPoint:addingPoint 
				postControlPoint:addingPoint hasPreControlPoint:NO hasPostControlPoint:NO isLineToPoint:YES];
			[[[tempSubPaths objectAtIndex:(ct - 1)]pathElements]addObject:[el autorelease]];
			NSBezierPath *p = [NSBezierPath bezierPath];
			bezierPathFromSubPath(tempSubPaths,p);
			[p setLineWidth:0.0];
			[self setAddingPointPath:p];
		   }
	   }
   }

- (void)setHandleBitsForview:(GraphicView*)gView
   {
	for (int j = 0;j < (signed)[subPaths count];j++)
	   {
		ACSDSubPath *subPath = [subPaths objectAtIndex:j];
		NSInteger ct = [[subPath pathElements] count];
		for (NSInteger i = 0;i < ct;i++)
		   {
			ACSDPathElement *pe = [[subPath pathElements] objectAtIndex:i];
			NSPoint pt = [pe point];
			[gView setHandleBitsH:(int)pt.x v:(int)pt.y];
		   }
      }
   }

-(NSInteger)nearestHandleToPoint:(NSPoint)pt maxDistance:(float)maxDistance xOffset:(float*)xOff yOffset:(float*)yOff
   {
	float minDistance = maxDistance + 1.0;
	NSInteger nearestHandle = -2;
	NSPoint nearestPoint = NSZeroPoint;
	for (int j = 0;j < (signed)[subPaths count];j++)
	   {
		ACSDSubPath *subPath = [subPaths objectAtIndex:j];
		NSInteger ct = [[subPath pathElements] count];
		for (NSInteger i = 0;i < ct;i++)
		   {
			ACSDPathElement *pe = [[subPath pathElements] objectAtIndex:i];
			NSPoint ept = [pe point];
			float xx = pt.x - ept.x;
			xx = xx * xx;
			float yy = pt.y - ept.y;
			yy = yy * yy;
			float dist = sqrt(xx + yy);
			if (dist < minDistance)
			   {
				minDistance = dist;
				nearestHandle = i;
				nearestPoint = ept;
			   }
		   }
	   }
	if (minDistance > maxDistance)
		return -2;
	*xOff = nearestPoint.x - pt.x;
	*yOff = nearestPoint.y - pt.y;
	return nearestHandle;
   }

-(NSInteger)totalElementCount:(NSBezierPath*)p
{
	NSInteger tot = 0;
	if (addingPoints)
		tot += [addingPointPath elementCount];
	return [p elementCount] + tot;
}

-(float)paddingRequired
{
	float padding = [super paddingRequired];
	if ([[ACSDPrefsController sharedACSDPrefsController:nil]showPathDirection])
	{
		float arrowlen = 16;
		if (arrowlen > padding)
			padding = arrowlen;
	}
	return padding;
}

-(void)drawArrowAtPoint:(NSPoint)pt vector:(NSPoint)vec magnification:(float)mg
{
    [[NSColor redColor]set];
    float veclen = dlen(vec);
    NSPoint apex = offset_point(pt, vecMultiply(vec, 16.0 / veclen / mg));
    NSPoint lp = lperp(vec);
    NSPoint lpt = offset_point(pt, vecMultiply(lp, 8.0 / dlen(lp) / mg));
    NSPoint rp = rperp(vec);
    NSPoint rpt = offset_point(pt, vecMultiply(rp, 8.0 / dlen(lp) / mg));
    NSBezierPath *p = [NSBezierPath bezierPath];
    [p moveToPoint:pt];
    [p lineToPoint:lpt];
    [p lineToPoint:apex];
    [p lineToPoint:rpt];
    [p fill];
}

-(void)drawDirectionSubpathsMagnification:(float)mg
{
    for (ACSDSubPath *sp in [self subPaths])
    {
        gSubPath *gsp = [gSubPath gSubPathFromACSDSubPath:sp];
        NSPoint pt,vec;
        for (id gel in [gsp elements])
        {
            [gel calculateLength];
            if ([gel isMemberOfClass:[gCurve class]])
            {
                gCurve *gc = (gCurve*)gel;
                double t = tForS(gc.pt1, gc.cp1, gc.cp2, gc.pt2, 64, 0.5, gc.length);
                bzTangent((gCurve*)gel, t, pt, vec);
            }
            else
            {
                gLine *g = (gLine*)gel;
                pt = tPointAlongLine(0.5, g.fromPt, g.toPt);
                vec = diff_points(g.toPt, g.fromPt);
            }
            [self drawArrowAtPoint:pt vector:vec magnification:mg];
        }
    }
}

- (void)drawHandlesGuide:(BOOL)forGuide magnification:(float)mg options:(NSUInteger)options
   {
       [NSGraphicsContext saveGraphicsState];
       if (moving)
           [[NSAffineTransform transformWithTranslateXBy:moveOffset.x yBy:moveOffset.y] concat];
       if (transform)
       {
           [transform concat];
       }
       NSColor *mainCol = [self setHandleColour:forGuide];
       NSColor *firstCol = mainCol;
       if (options & DRAW_HANDLES_PATH_DIR)
           firstCol = [NSColor blackColor];
       float mag = fmax(xScale,yScale)*mg;
       if (addingPoints)
           [addingPointPath stroke];
       else
       {
           [path setLineWidth:0.0];
           [path stroke];
       }
       [NSBezierPath setDefaultLineWidth:0.0];
       if (!forGuide)
       {
           for (int j = 0;j < (signed)[subPaths count];j++)
           {
               ACSDSubPath *subPath = [subPaths objectAtIndex:j];
               NSInteger ct = [[subPath pathElements] count];
               for (NSInteger i = 0;i < ct;i++)
               {
                   ACSDPathElement *pe = [[subPath pathElements] objectAtIndex:i];
                   if (i == 0)
                       [firstCol set];
                   else
                       [mainCol set];
                   [self drawHandleAtPoint:[pe point]magnification:mag];
                   [mainCol set];
                   NSPoint pt;
                   if ([pe hasPreControlPoint])
                   {
                       pt = [pe preControlPoint];
                       [[NSBezierPath bezierPathWithOvalInRect:[self handleRect:pt magnification:mag]]fill];
                       [NSBezierPath strokeLineFromPoint:pt toPoint:[pe point]];
                   }
                   if ([pe hasPostControlPoint])
                   {
                       pt = [pe postControlPoint];
                       [[NSBezierPath bezierPathWithOvalInRect:[self handleRect:pt magnification:mag]]fill];
                       [NSBezierPath strokeLineFromPoint:pt toPoint:[pe point]];
                   }
               }
           }
		[[NSColor redColor] set];
		NSEnumerator *objEnum = [selectedElements objectEnumerator];
		SelectedElement *el;
		while ((el = [objEnum nextObject]) != nil) 
		   {
			KnobDescriptor kd = [el knobDescriptor];
			ACSDPathElement *pe = [self pathElementForKnob:kd];
			if ([el knobDescriptor].isLine)
			   {
				KnobDescriptor nextKd(kd.subPath,kd.knob+1,0,NO);
				ACSDPathElement *nextPe = [self pathElementForKnob:nextKd];
				if (nextPe)
				   {
					NSBezierPath *p = [NSBezierPath bezierPath];
					[p moveToPoint:[pe point]];
					if (![pe hasPostControlPoint] && ![nextPe hasPreControlPoint])
						[p lineToPoint:[nextPe point]];
					else
					   {
						NSPoint cp1,cp2;
						if ([pe hasPostControlPoint])
							cp1 = [pe postControlPoint];
						else
							cp1 = [pe point];
						if ([nextPe hasPreControlPoint])
							cp2 = [nextPe preControlPoint];
						else
							cp2 = [nextPe point];
						[p curveToPoint:[nextPe point]controlPoint1:cp1 controlPoint2:cp2];
					   }
					[p stroke];
				   }
			   }
			else
				[self drawHandleAtPoint:[pe point]magnification:mag];
		   }
           if (options & DRAW_HANDLES_PATH_DIR)
               [self drawDirectionSubpathsMagnification:mg];
	   }
	[NSGraphicsContext restoreGraphicsState];
   }

-(SelectedElement*)selectedElement
{
    if ([selectedElements count] == 1)
        return [selectedElements anyObject];
    return nil;
}

-(KnobDescriptor)elementAfter:(KnobDescriptor)kd
{
    KnobDescriptor newkd = kd;
    ACSDSubPath *sp = subPaths[newkd.subPath];
    if (++newkd.knob >= [[sp pathElements]count])
    {
        newkd.subPath++;
        if (newkd.subPath >= [subPaths count])
            return kd;
        sp = subPaths[newkd.subPath];
        newkd.knob = 0;
        return newkd;
    }
    return newkd;
}

-(KnobDescriptor)elementBefore:(KnobDescriptor)kd
{
    KnobDescriptor newkd = kd;
    ACSDSubPath *sp = subPaths[newkd.subPath];
    if (--newkd.knob < 0)
    {
        newkd.subPath--;
        if (newkd.subPath < 0)
            return kd;
        sp = subPaths[newkd.subPath];
        newkd.knob = [sp.pathElements count] - 1;
        if (newkd.knob < 0)
            return kd;
        return newkd;
    }
    return newkd;
}

-(BOOL)selectNextElement
{
    SelectedElement *se = [self selectedElement];
    if (se == nil)
        return NO;
    KnobDescriptor kd = [self elementAfter:se.knobDescriptor];
    [self uClearSelectedElements];
    [self uSelectElementFromKnob:kd extend:NO];
    return YES;
}

-(BOOL)selectPrevElement
{
    SelectedElement *se = [self selectedElement];
    if (se == nil)
        return NO;
    KnobDescriptor kd = [self elementBefore:se.knobDescriptor];
    [self uClearSelectedElements];
    [self uSelectElementFromKnob:kd extend:NO];
    return YES;
}

-(void)markDeletedElements
   {
	NSEnumerator *objEnum = [selectedElements objectEnumerator];
	SelectedElement *el;
	while ((el = [objEnum nextObject]) != nil) 
	   {
		KnobDescriptor kd = [el knobDescriptor];
		ACSDPathElement *pe = [self pathElementForKnob:kd];
		if ([el knobDescriptor].isLine)
			[pe setDeleteFollowingLine:YES];
		else
			[pe setDeletePoint:YES];
	   }
   }

-(void)uReplaceSubPathsInRange:(NSRange)r withSubPaths:(NSArray*)spArray
   {
	[self invalidateInView];
	NSArray *deletedObjects = [subPaths objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:r]];
	[[[self undoManager] prepareWithInvocationTarget:self] uReplaceSubPathsInRange:NSMakeRange(r.location,[spArray count])withSubPaths:deletedObjects];
	[subPaths replaceObjectsInRange:r withObjectsFromArray:spArray];
	if (currentSubPathInd >= (signed)[subPaths count])
		currentSubPathInd = [subPaths count] - 1;
	[self generatePath];
	[self completeRebuild];
   }

-(void)uReplacePathElementsForSubPath:(NSInteger)i inRange:(NSRange)r withPathElements:(NSArray*)peArray
   { 
	[self invalidateInView];
	NSArray *deletedObjects = [[[subPaths objectAtIndex:i]pathElements]objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:r]];
	[[[self undoManager] prepareWithInvocationTarget:self] uReplacePathElementsForSubPath:i 
																			  inRange:NSMakeRange(r.location,[peArray count])withPathElements:deletedObjects];
	[[[subPaths objectAtIndex:i]pathElements] replaceObjectsInRange:r withObjectsFromArray:peArray];
	[self generatePath];
	[self completeRebuild];
   }

-(BOOL)deleteSelectedElements
   {
	if ([[self selectedElements] count] == 0)
		return NO;
	[self markDeletedElements];
	NSInteger count = [subPaths count];
	for (NSInteger i = count - 1;i >= 0;i--)
	   {
		ACSDSubPath *sp = [subPaths objectAtIndex:i];
		NSMutableArray *newArray;
		if ([sp deleteMarkedElementsIntoArray:&newArray])
		{
			for (NSInteger j = [newArray count]-1;j >= 0;j--)
			{
				ACSDSubPath *ssp = [newArray objectAtIndex:j];
				if ([[ssp pathElements]count] == 1)
					[newArray removeObjectAtIndex:j];
			}
			[self uReplaceSubPathsInRange:NSMakeRange(i,1) withSubPaths:newArray];
		}
	   }
	[self uClearSelectedElements];
	return YES;
   }

- (BOOL)usesSimplePath
   {
    return NO;
   }

-(BOOL)isSameAs:(id)obj
   {
	if (![super isSameAs:obj])
		return NO;
//	return [path isEqual:[((ACSDPath*)obj) path]];
	NSUInteger ct = [subPaths count];
	if (ct != [[obj subPaths]count])
		return NO;
	for (unsigned i = 0;i < ct;i++)
		if (!([[subPaths objectAtIndex:i]isSameAs:[[obj subPaths]objectAtIndex:i]]))
			return NO;
	return YES;

   }

-(NSPoint)firstPoint
   {
	return [[[[subPaths objectAtIndex:0]pathElements]objectAtIndex:0]point];
   }

-(NSPoint)lastPoint
   {
	return [[[[subPaths lastObject]pathElements]lastObject]point];
   }

-(BOOL)knobIsSelected:(const KnobDescriptor&)k
   {
	return [[self selectedElements] containsObject:[SelectedElement SelectedElementWithKnobDescriptor:k]];
   }

-(NSMutableSet *)selectedElements
{
	if (selectedElements == nil)
		selectedElements = [[NSMutableSet alloc]init];
	return selectedElements;
}

-(void)selectElement:(SelectedElement*)se
   {
	[[self selectedElements] addObject:se];
   }

-(void)selectElementFromKnob:(KnobDescriptor)kd
   {
	[self selectElement:[SelectedElement SelectedElementWithKnobDescriptor:kd]];
   }

-(void)deselectElement:(SelectedElement*)se
   {
	[[self selectedElements] removeObject:se];
   }

-(void)deselectElementFromKnob:(KnobDescriptor)kd
   {
	[self deselectElement:[SelectedElement SelectedElementWithKnobDescriptor:kd]];
   }

-(void)uDeselectElement:(SelectedElement*)se
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uSelectElement:se];
	[self deselectElement:se];
	[self invalidateInView];
   }

-(void)uDeselectElementFromKnob:(KnobDescriptor)kd
   {
	[self uDeselectElement:[SelectedElement SelectedElementWithKnobDescriptor:kd]];
   }

-(void)uSelectElement:(SelectedElement*)se
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uDeselectElement:se];
	[self selectElement:se];
	[self invalidateInView];
   }

-(void)uSelectElementFromKnob:(KnobDescriptor)kd extend:(BOOL)extend
   {
//	if (!extend)
//		[self uClearSelectedElements];
	[self uSelectElement:[SelectedElement SelectedElementWithKnobDescriptor:kd]];
   }

-(BOOL)elementIsSelected:(KnobDescriptor)kd
   {
	return [[self selectedElements] containsObject:[SelectedElement SelectedElementWithKnobDescriptor:kd]];
   }

-(void)setSelectedElements:(NSSet*)objects
   {
	[selectedElements removeAllObjects];
	[selectedElements addObjectsFromArray:[objects allObjects]];
   }

-(void)uSetSelectedElements:(NSSet*)objects
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uClearSelectedElements];
	[self setSelectedElements:objects];
	[self invalidateInView];
   }

-(BOOL)uClearSelectedElements
   {
	if ([[self selectedElements] count] > 0)
	   {
		[[[self undoManager] prepareWithInvocationTarget:self] uSetSelectedElements:[NSSet setWithSet:selectedElements]];
		[self clearSelectedElements];
		[self invalidateInView];
		return YES;
	   }
	return NO;
   }

-(void)clearSelectedElements
   {
	[[self selectedElements] removeAllObjects];
   }

-(void)uInsertPathElement:(ACSDPathElement*)pe forKnob:(const KnobDescriptor)kd
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uDeletePathElement:kd];
	[[subPaths objectAtIndex:kd.subPath]insertElement:pe atIndex:kd.knob];
	[self generatePath];
	[self completeRebuild];
	[self invalidateInView];
   }

-(void)uReplacePathElementWithElement:(ACSDPathElement*)pr forKnob:(const KnobDescriptor)kd
{
	[self uDeletePathElement:kd];
	[self uInsertPathElement:pr forKnob:kd];
	[self generatePath];
	[self completeRebuild];
	[self invalidateInView];
}

-(void)uDeletePathElement:(const KnobDescriptor)kd
   {
	[[[self undoManager] prepareWithInvocationTarget:self] uInsertPathElement:[self pathElementForKnob:kd] forKnob:kd];
	[[subPaths objectAtIndex:kd.subPath]deleteElement:kd];
	[self generatePath];
	[self completeRebuild];
	[self invalidateInView];
   }

-(KnobDescriptor)uDuplicateKnob:(const KnobDescriptor)kd
   {
	KnobDescriptor kdplus = kd;
	kdplus.knob++;
	[[[self undoManager] prepareWithInvocationTarget:self] uDeletePathElement:kdplus];
	[[subPaths objectAtIndex:kd.subPath]duplicateElement:kd];
	return kdplus;
   }

-(void)uSetSubPathsWithIndexes:(NSIndexSet*)iSet isClosed:(BOOL)cl
   {
	if ([iSet count] == 0)
		return;
	[[[self undoManager] prepareWithInvocationTarget:self] uSetSubPathsWithIndexes:iSet isClosed:!cl];
	[[subPaths objectsAtIndexes:iSet]makeObjectsPerformSelector:@selector(setIsClosedTo:)withObject:[NSNumber numberWithBool:cl]];
	[self generatePath];
	[self completeRebuild];
   }

-(BOOL)uSetSubPathsIsClosedTo:(NSNumber*)ncl
   {
	BOOL cl = [ncl boolValue];
	NSIndexSet *iSet = [subPaths indexesOfObjectsWhichRespond:!cl toSelector:@selector(isClosed)];
	if ([iSet count] > 0)
	   {
		[self uSetSubPathsWithIndexes:iSet isClosed:cl];
		return YES;
	   }
	return NO;
   }

-(BOOL)uMergePoints
   {
	if (![self graphicCanMergePoints])
		return NO;
	NSArray *arr = [self sortedSelectedElements];
	NSInteger subPathInd = [[arr objectAtIndex:0]knobDescriptor].subPath;
	KnobDescriptor kd0 = [[arr objectAtIndex:0]knobDescriptor];
	KnobDescriptor kd1 = [[arr objectAtIndex:1]knobDescriptor];
	NSInteger peind0 = kd0.knob;
	NSInteger peind1 = kd1.knob;
	ACSDPathElement *pe0 = [self pathElementForKnob:kd0];
	ACSDPathElement *pe1 = [self pathElementForKnob:kd1];
	[self uClearSelectedElements];
	if ((peind1 - peind0) == 1)
	   {
		ACSDPathElement *newPe = [ACSDPathElement mergePathElement1:pe0 andPathElement2:pe1];
		[self uReplacePathElementsForSubPath:subPathInd inRange:NSMakeRange(peind0,2) withPathElements:[NSArray arrayWithObject:newPe]];
	   }
	else
	   {
		ACSDPathElement *newPe = [ACSDPathElement mergePathElement1:pe1 andPathElement2:pe0];
		[self uReplacePathElementsForSubPath:subPathInd inRange:NSMakeRange(peind0,1) withPathElements:[NSArray arrayWithObject:newPe]];
		[self uDeletePathElement:kd1];
	   }
	[self uSelectElementFromKnob:kd0 extend:NO];
	return YES;
   }

-(BOOL)hasPathsWithClosed:(BOOL)cl
   {
	return [subPaths orMakeObjectsPerformSelector:@selector(isClosedEqualTo:) withObject:[NSNumber numberWithBool:cl]];
   }

-(NSArray*)sortedSelectedElements
   {
	return [[[self selectedElements] allObjects]sortedArrayUsingSelector:@selector(compareWith:)];
   }

-(BOOL)graphicCanMergePoints
   {
	if ([[self selectedElements] count] != 2)
		return NO;
	NSArray *arr = [self sortedSelectedElements];
	KnobDescriptor k1 = [[arr objectAtIndex:0]knobDescriptor];
	if (k1.isLine)
		return NO;
	KnobDescriptor k2 = [[arr objectAtIndex:1]knobDescriptor];
	if (k2.isLine)
		return NO;
	if (k1.subPath != k2.subPath)
		return NO;
	if ((k2.knob - k1.knob) == 1)
		return YES;
	if (k1.knob != 0)
		return NO;
	if (k2.knob != (int)[[[subPaths objectAtIndex:k2.subPath]pathElements]count] - 1)
		return NO;
	return YES;
   }

-(NSString*)graphicAttributesXML:(NSMutableDictionary*)options
{
    NSMutableString *attrString = [NSMutableString stringWithCapacity:100];
    [attrString appendString:[super graphicAttributesXML:options]];
	for (NSArray *arr in self.attributes)
		if ([arr[0]isEqualToString:@"widthtracksheight"] || [arr[0]isEqualToString:@"heighttrackswidth"])
			[attrString appendFormat:@" pxwidth=\"%g\" pxheight=\"%g\"",[self bounds].size.width,[self bounds].size.height];
    NSBezierPath *p = [self transformedBezierPath];
    NSRect parR = [self parentRect:options];
    NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:-parR.origin.x yBy:-parR.origin.y];
    [t appendTransform:[NSAffineTransform transformWithScaleXBy:1.0 / parR.size.width yBy:1.0 / parR.size.height]];
    [t appendTransform:[NSAffineTransform transformWithTranslateXBy:0 yBy:-1]];
    [t appendTransform:[NSAffineTransform transformWithScaleXBy:1.0 yBy:-1.0]];
    p = [t transformBezierPath:p];
    NSString *pstr = string_from_path(p);
    [attrString appendFormat:@" d=\"%@\"",pstr];
    return attrString;
}



@end
