//
//  PageListTableSource.h
//  ACSDraw
//
//  Created by alan on 09/03/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PageListTableSource : NSObject 
   {
    IBOutlet id tableView;
    IBOutlet id windowController;
	NSMutableArray *pageList;
   }

- (void)setPageList:(NSMutableArray*)list;

@end
