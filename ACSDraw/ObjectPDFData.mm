//
//  ObjectPDFData.mm
//  ACSDraw
//
//  Created by alan on 16/02/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "ObjectPDFData.h"
#import "ObjectView.h"


@implementation ObjectPDFData

- (id)initWithObject:(ACSDGraphic*)object
{
    self = [super init];
    ObjectView *objectView = [[ObjectView alloc]initWithObject:object];
    FlippableView *tempV = [object setCurrentDrawingDestination:objectView];
    pdfData = [objectView dataWithPDFInsideRect:[objectView bounds]];
    [object setCurrentDrawingDestination:tempV];
    offset = [objectView offset];
    bounds = [objectView bounds];
    return self;
}

- (NSPoint)offset
{
    return offset;
}

- (NSData*)pdfData
{
    return pdfData;
}

- (NSRect)bounds
{
    return bounds;
}

@end
