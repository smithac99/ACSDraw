//
//  TriggerController.h
//  ACSDraw
//
//  Created by alan on 07/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"
#import "TriggerTableSource.h"


@interface TriggerController : ViewController 
{
	IBOutlet TriggerTableSource *triggerTableSource;
	IBOutlet NSTableView *tableView;
}

- (IBAction)plusHit:(id)sender;
- (IBAction)minusHit:(id)sender;

@end
