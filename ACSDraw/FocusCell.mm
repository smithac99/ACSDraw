//
//  FocusCell.mm
//  ACSDraw
//
//  Created by alan on 29/10/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import "FocusCell.h"
#import "ACSDTableView.h"
//#import "ITabManager.h"


@implementation FocusCell

- (BOOL)isEditable
   {
    return NO;
   }

-(void)drawFocusRingFrame:(NSRect)cellFrame controlView:(NSView *)controlView
   {
	id delegate = [(ACSDTableView*)controlView delegate];
	NSInteger fillInd = [(id<FocusCellDelegate>)delegate rowForContextualMenu];
	if (fillInd < 0)
		return;
	id dataSource = [(ACSDTableView*)controlView dataSource];
	if ([[dataSource tableView:nil objectValueForTableColumn:nil row:fillInd]pointerValue] == [[self objectValue]pointerValue])
	   {
		[[NSColor blueColor] set];
		[NSBezierPath setDefaultLineWidth:4.0];
		[NSBezierPath strokeRect:cellFrame];
	   }
   }


@end
