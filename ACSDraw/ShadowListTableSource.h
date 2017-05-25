/* ShadowListTableSource */

#import <Cocoa/Cocoa.h>

@interface ShadowListTableSource : NSObject
   {
    IBOutlet id tableView;
    IBOutlet id windowController;
	NSMutableArray *shadowList;
   }

- (void)setShadowList:(NSMutableArray*)list;

@end
