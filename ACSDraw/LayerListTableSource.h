/* LayerListTableSource */

#import <Cocoa/Cocoa.h>

@class ACSDLayer;

@interface LayerListTableSource : NSObject
   {
    IBOutlet id tableView;
    IBOutlet id windowController;
	NSMutableArray *layerList;
   }

- (void)setLayerList:(NSMutableArray*)list;
-(NSArray*)layerList;

@end
