//
//  TriggerController.mm
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TriggerController.h"
#import "GraphicView.h"
#import "ACSDGraphic.h"
#import "ACSDPage.h"


@implementation TriggerController

-(id)init
{
	if (self = [super initWithTitle:@"Triggers"])
	{
	}
	return self;
}

- (void)zeroControls
{
	[triggerTableSource setObjectList:nil];
	[triggerTableSource setLayerList:nil];
	[tableView reloadData];
}

-(void)setGraphicControls
{
	id selectedGraphics = [[[self inspectingGraphicView] selectedGraphics]allObjects];
	id g = nil;
	if ([selectedGraphics count] == 1)
		g = [selectedGraphics objectAtIndex:0];
	if (g)
	   {
		[triggerTableSource setObjectList:[g triggers]];
		[triggerTableSource setLayerList:[[[self inspectingGraphicView]currentPage]layers]];
		if ([[g triggers]count] > 0)
			[triggerTableSource refreshLayerTitles];
	   }
	else
	   {
	    [self zeroControls];
	   }
}	

- (IBAction)plusHit:(id)sender
{
	id selectedGraphics = [[self inspectingGraphicView] selectedGraphics];
	ACSDGraphic *g = nil;
	if ([selectedGraphics count] == 1)
		g = [[selectedGraphics allObjects]objectAtIndex:0];
	else
		return;
	if (![g triggers])
	{
		[g allocTriggers];
		[triggerTableSource setObjectList:[g triggers]];
		[triggerTableSource refreshLayerTitles];
	}
	NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithCapacity:3];
	[dict setObject:[NSNumber numberWithInt:1] forKey:@"event"];
	[dict setObject:[NSNumber numberWithInt:1] forKey:@"action"];
	[triggerTableSource addTrigger:dict toGraphic:g];
}

- (IBAction)minusHit:(id)sender
{
	id selectedGraphics = [[self inspectingGraphicView] selectedGraphics];
	ACSDGraphic *g = nil;
	if ([selectedGraphics count] == 1)
		g = [[selectedGraphics allObjects]objectAtIndex:0];
	else
		return;
	[triggerTableSource deleteSelectedTriggerFromGraphic:g];

}



@end
