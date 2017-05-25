/* StrokeListTableSource */

#import <Cocoa/Cocoa.h>

@interface StrokeListTableSource : NSObject
   {
    IBOutlet id tableView;
    IBOutlet id windowController;
	NSMutableArray *strokeList;
   }

- (void)setStrokeList:(NSMutableArray*)list;

@end
