//
//  TriggerTableSource.h
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TableSource.h"
@class ACSDLayer;
@class ACSDGraphic;

#define TRIGGER_MOUSEDOWN 0
#define TRIGGER_MOUSEUP 1
#define TRIGGER_CLICK 2
#define TRIGGER_MOUSEOVER 3
#define TRIGGER_MOUSEOUT 4
#define TRIGGER_SHOW 0
#define TRIGGER_HIDE 1

extern NSString *triggerEventStrings[];

@interface TriggerTableSource : TableSource 
{
	NSArray *layerList;
	BOOL layerTitleListValid;
}

-(void)setLayerList:(NSArray*)list;
-(void)refreshLayerTitles;
-(void)uRemoveTrigger:(NSMutableDictionary*)t fromLayer:(ACSDLayer*)l;
-(void)uRemoveTrigger:(NSMutableDictionary*)t fromGraphic:(ACSDGraphic*)g;
-(void)uAddTrigger:(NSMutableDictionary*)t toLayer:(ACSDLayer*)l;
-(void)uAddTrigger:(NSMutableDictionary*)t toGraphic:(ACSDGraphic*)g;
-(void)addTrigger:(NSMutableDictionary*)t toGraphic:(ACSDGraphic*)g;
-(void)deleteSelectedTriggerFromGraphic:(ACSDGraphic*)g;

@end
