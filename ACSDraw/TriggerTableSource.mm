//
//  TriggerTableSource.mm
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TriggerTableSource.h"
#import "ACSDLayer.h"
#import "ACSDGraphic.h"

NSString *triggerEventStrings[] = 
{
@"mousedown",
@"mouseup",
@"click",
@"mouseover",
@"mouseout"
};



@implementation TriggerTableSource

-(NSUndoManager*)undoManager
{
	return [windowController undoManager];
}

-(void)setLayerList:(NSArray*)list
{
	if (list != layerList)
	{
		layerList = list;
		layerTitleListValid = NO;
	}
}

-(void)refreshLayerTitles
{
	if (layerTitleListValid)
		return;
	NSPopUpButtonCell *pu = [[tableView tableColumnWithIdentifier:@"layer"]dataCell];
	[pu removeAllItems];
	layerTitleListValid = YES;
	if (!layerList)
		return;
	for (unsigned i = 0;i < [layerList count];i++)
		[pu addItemWithTitle:[[layerList objectAtIndex:i]name]];
}

-(void)uRemoveTrigger:(NSMutableDictionary*)t fromLayer:(ACSDLayer*)l
{
	[[[self undoManager] prepareWithInvocationTarget:self] uAddTrigger:t toLayer:l];
	[l removeTrigger:t];
	[t removeObjectForKey:@"layer"];
}

-(void)uRemoveTrigger:(NSMutableDictionary*)t fromGraphic:(ACSDGraphic*)g
{
	[[[self undoManager] prepareWithInvocationTarget:self] uAddTrigger:t toGraphic:g];
	[g removeTrigger:t];
	[t removeObjectForKey:@"graphic"];
	[tableView reloadData];
}

-(void)uAddTrigger:(NSMutableDictionary*)t toLayer:(ACSDLayer*)l
{
	[[[self undoManager] prepareWithInvocationTarget:self] uRemoveTrigger:t fromLayer:l];
	[l addTrigger:t];
	[t setObject:l forKey:@"layer"];
}

-(void)uAddTrigger:(NSMutableDictionary*)t toGraphic:(ACSDGraphic*)g
{
	[[[self undoManager] prepareWithInvocationTarget:self] uRemoveTrigger:t fromGraphic:g];
	[g addTrigger:t];
	[t setObject:g forKey:@"graphic"];
	[tableView reloadData];
}

-(void)addTrigger:(NSMutableDictionary*)t toGraphic:(ACSDGraphic*)g
{
	[self uAddTrigger:t	toGraphic:g];
	[[self undoManager] setActionName:@"Add Trigger"];
}

-(void)deleteSelectedTriggerFromGraphic:(ACSDGraphic*)g
{
	NSInteger i = [tableView selectedRow];
	if (i < 0)
		return;
	NSMutableDictionary *t = [objectList objectAtIndex:i];
	if (!t)
		return;
	[self uRemoveTrigger:t fromGraphic:g];
	ACSDLayer *l = [t objectForKey:@"layer"];
	[self uRemoveTrigger:t fromLayer:l];
	[[self undoManager] setActionName:@"Delete Trigger"];
}

-(void)uUpdateTrigger:(NSMutableDictionary*)t setKey:(id)k toValue:(id)val
{
	id oldValue = [t objectForKey:k];
	if (oldValue && ![oldValue isEqual:val])
		[[[self undoManager] prepareWithInvocationTarget:self] uUpdateTrigger:t setKey:k toValue:oldValue];
	[t setObject:val forKey:k];
	[tableView reloadData];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(rowIndex >= 0 && rowIndex < (NSInteger)[objectList count])
	{
		NSDictionary *d = [objectList objectAtIndex:rowIndex];
		if ([[aTableColumn identifier] isEqual:@"layer"])
		{
			ACSDLayer *l = [d objectForKey:@"layer"];
			if (l == nil)
				return nil;
			NSUInteger i = [layerList indexOfObjectIdenticalTo:l];
			if (i == NSNotFound)
				return nil;
			return [NSNumber numberWithInteger:i];
		}
		return [[objectList objectAtIndex:rowIndex]objectForKey:[aTableColumn identifier]];
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
   {
    NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[objectList count]);
	NSMutableDictionary *d = [objectList objectAtIndex:rowIndex];
	if ([[aTableColumn identifier] isEqual:@"layer"])
	{
		ACSDLayer *lnew = [layerList objectAtIndex:[anObject intValue]];
		ACSDLayer *lold = [d objectForKey:@"layer"];
		if (lnew != lold)
		{
			[self uRemoveTrigger:d fromLayer:lold];
			[self uAddTrigger:d	toLayer:lnew];
			[[self undoManager] setActionName:@"UpDate Trigger Layer"];
		}
	}
	else
		[self uUpdateTrigger:d setKey:[aTableColumn identifier] toValue:anObject];
}

-(void)awakeFromNib
{
	NSPopUpButtonCell *pu = [[tableView tableColumnWithIdentifier:@"event"]dataCell];
	[pu removeAllItems];
	for (int i = 0;i < 5;i++)
		[pu addItemWithTitle:triggerEventStrings[i]];
	pu = [[tableView tableColumnWithIdentifier:@"action"]dataCell];
	[pu removeAllItems];
	[pu addItemWithTitle:@"Show"];
	[pu addItemWithTitle:@"Hide"];
}

@end
