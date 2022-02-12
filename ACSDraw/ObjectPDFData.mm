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
    if (self = [super init])
	{
		ObjectView *objectView = [[ObjectView alloc]initWithObject:object];
		FlippableView *tempV = [object setCurrentDrawingDestination:objectView];
		_pdfData = [objectView dataWithPDFInsideRect:[objectView bounds]];
		[object setCurrentDrawingDestination:tempV];
		_offset = [objectView offset];
		_bounds = [objectView bounds];
	}
    return self;
}

@end
