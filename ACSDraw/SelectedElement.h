//
//  SelectedElement.h
//  ACSDraw
//
//  Created by alan on 28/04/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"

@interface SelectedElement : NSObject 
   {
	KnobDescriptor *knobDescriptor;
   }

+(id)SelectedElementWithKnobDescriptor:(const KnobDescriptor&)kd;

-(id)initWithKnobDescriptor:(const KnobDescriptor&)kd;
-(KnobDescriptor)knobDescriptor;
-(NSComparisonResult)compareWith:(id)obj;

@end
