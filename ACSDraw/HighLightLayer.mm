//
//  HighLightLayer.mm
//  ACSDraw
//
//  Created by alan on 02/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "HighLightLayer.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDLink.h"
#import "ACSDText.h"
#import "ACSDPage.h"
#import "ACSDrawDocument.h"


@implementation HighLightLayer

- (id)initWithGraphicView:(GraphicView*)gv
{
    if (self = [super init])
    {
        graphicView = gv;
        highLightColour = [NSColor redColor];
        highLightOn = YES;
    }
    return self;
}

-(void)setTargetObject:(id)tg
{
    if (tg == targetObject)
        return;
    targetObject = tg;
}

-(void)invalObject:(id)obj
{
    if (!obj)
        return;
    if ([obj isKindOfClass:[NSView class]])
    {
        [obj setNeedsDisplayInRect:[obj visibleRect]];
        return;
    }
    NSRect r = NSZeroRect;
    if ([obj isKindOfClass:[NSArray class]])
    {
        ACSDGraphic *g;
        NSEnumerator *objEnum = [obj objectEnumerator];
        while ((g = [objEnum nextObject]) != nil)
            r = NSUnionRect(r,[g displayBounds]);
    }
    else if ([obj isKindOfClass:[ACSDLink class]])
        r = [[(ACSDLink*)obj toObject] displayBounds];
    else if ([obj isKindOfClass:[ACSDPage class]])
    {
        r.size = [[(ACSDPage*)obj document]documentSize];
        r.origin.x = r.origin.y = 0.0;
    }
    else
        r = [(ACSDGraphic*)obj displayBounds];
    [graphicView setNeedsDisplayInRect:r];
}

-(void)highLightObject:(id)obj modifiers:(NSUInteger)modifiers
{
    if (obj == targetObject && ![targetObject isMemberOfClass:[ACSDText class]])
        return;
    modifierFlags = modifiers;
    if (obj)
        highLightOn = YES;
    else
        highLightOn = NO;
    [self invalObject:targetObject];
    [self setTargetObject:obj];
    [self invalObject:targetObject];
}

-(void)flipHighLight
{
    highLightOn = !highLightOn;
}

- (void)finishMethod:(NSTimer*)timer
{
    [self highLightObject:nil modifiers:0];
}

- (void)fireMethod:(NSTimer*)timer
{
    count--;
    [self flipHighLight];
    if (count < 1)
    {
        [timer invalidate];
        [self finishMethod:timer];
    }
    [self invalObject:targetObject];
}

-(void)oneFlash:(id)obj interval:(float)sec
{
    count--;
    [self flipHighLight];
    [self setTargetObject:obj];
    [self invalObject:obj];
    if (count >= 0)
    {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self oneFlash:obj interval:sec];
        });
    }
    else
        [self setTargetObject:nil];
}

-(void)highLightObject:(id)obj times:(int)times interval:(float)sec
{
    count = times;
    [self highLightObject:obj modifiers:modifierFlags];
    //[NSTimer scheduledTimerWithTimeInterval:sec target:self selector:@selector(fireMethod:) userInfo:nil repeats:YES];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self oneFlash:obj interval:sec];
    });
    
}

-(void)highLightObject:(id)obj forSeconds:(float)sec
{
    [self highLightObject:obj modifiers:modifierFlags];
    [NSTimer scheduledTimerWithTimeInterval:sec target:self selector:@selector(finishMethod:) userInfo:nil repeats:NO];
}

-(void)drawObj:(ACSDGraphic*)g rect:(NSRect)r hotPoint:(NSPoint)hotPoint
{
    if (!g)
        return;
    if ([g isMemberOfClass:[ACSDLink class]])
        [[(ACSDLink*)g toObject] drawHighlightRect:r colour:highLightColour anchorID:[(ACSDLink*)g anchorID]overflow:[(ACSDLink*)g overflow]];
    else
        [g drawHighlightRect:r colour:highLightColour hotPoint:hotPoint modifiers:modifierFlags];
}

-(void)outlineRect:(NSRect)rect
{
    NSBezierPath *p = [NSBezierPath bezierPathWithRect:rect];
    [highLightColour set];
    [p setLineWidth:5];
    [p stroke];
}

-(void)drawRect:(NSRect)rect hotPoint:(NSPoint)hotPoint
{
    if (!targetObject)
        return;
    if (!highLightOn)
        return;
    if ([targetObject isKindOfClass:[NSArray class]])
    {
        ACSDGraphic *g;
        NSEnumerator *objEnum = [targetObject objectEnumerator];
        while ((g = [objEnum nextObject]) != nil)
            [self drawObj:g rect:rect hotPoint:hotPoint];
    }
    else if ([targetObject isKindOfClass:[NSView class]])
        [self outlineRect:[targetObject visibleRect]];
    else if ([targetObject isKindOfClass:[ACSDPage class]])
    {
        NSRect r;
        r.size = [[(ACSDPage*)targetObject document]documentSize];
        r.origin.x = r.origin.y = 0.0;
        [self outlineRect:r];
    }
    else
        [self drawObj:targetObject rect:rect hotPoint:hotPoint];
}

-(id)targetObject
{
    return targetObject;
}

@end
