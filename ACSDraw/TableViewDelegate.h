/*
 *  TableViewDelegate.h
 *  ACSDraw
 *
 *  Created by alan on 01/03/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

@protocol TableViewDelegate
- (BOOL)handleClickAtPoint:(NSPoint)pt inTableView:(NSTableView*)tableView;
-(int)displayRowForContextualMenu;

@end

