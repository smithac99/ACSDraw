//
//  ACSDReference.m
//  ACSDraw
//
//  Created by Alan on 11/03/2016.
//
//

#import "ACSDReference.h"

@implementation ACSDReference

+ (NSString*)graphicTypeName
{
    return @"Reference";
}

-(id)initWithName:(NSString*)n graphic:(ACSDGraphic*)g
{
    if (self = [super init])
        self.referenceGraphic = g;
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACSDReference *obj = [super copyWithZone:zone];
    obj.referenceGraphic = self.referenceGraphic;
    return obj;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.referenceGraphic forKey:@"referenceGraphic"];
}

- (id) initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    self.referenceGraphic = [coder decodeObjectForKey:@"referenceGraphic"];
    return self;
}

-(float)paddingRequired
{
    return [self.referenceGraphic paddingRequired];
}

-(NSRect)displayBoundsSansShadow
{
    return [self.referenceGraphic displayBoundsSansShadow];
}

- (void)drawObject:(NSRect)aRect view:(GraphicView*)gView options:(NSMutableDictionary*)options
{
    [self.referenceGraphic drawObject:aRect view:gView options:options];
}

-(NSSet*)usedFills
{
    return [self.referenceGraphic usedFills];
}

-(NSSet*)usedShadows
{
    return [self.referenceGraphic usedShadows];
}

-(NSSet*)usedStrokes
{
    return [self.referenceGraphic usedStrokes];
}

-(BOOL)isSameAs:(id)obj
{
    if (![super isSameAs:obj])
        return NO;
    return self.referenceGraphic == [((ACSDReference*)obj) referenceGraphic];
}

@end
