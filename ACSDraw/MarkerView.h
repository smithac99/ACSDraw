//
//  MarkerView.h
//  ACSDraw
//
//  Created by alan on 28/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SnapLine;
@class GraphicView;

@interface MarkerView : NSView<CALayerDelegate>
{
}

@property (weak) IBOutlet GraphicView *graphicView;
@property (retain) CALayer *horizontalSnapLineLayer,*verticalSnapLineLayer;
//@property (strong) 	SnapLine *horizontalSnapLine,*verticalSnapLine;

@end
