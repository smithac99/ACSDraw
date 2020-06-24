/* ToolWindowController */

#import <Cocoa/Cocoa.h>

extern NSString *ACSDSelectedToolDidChangeNotification;
extern NSString *ACSDSnapButtonDidChangeNotification;

enum 
{
    ACSD_ARROW_TOOL = 0,
	ACSD_WHITE_ARROW_TOOL,
	ACSD_SPLIT_POINT_TOOL,
    ACSD_RECT_TOOL,
    ACSD_CIRCLE_TOOL,
	ACSD_LINE_TOOL,
    ACSD_PEN_TOOL,
    ACSD_CONNECTOR_TOOL,
	ACSD_POLYGON_TOOL,
    ACSD_GRID_TOOL,
    ACSD_TEXT_TOOL,
	ACSD_ROTATE_TOOL,
	ACSD_FREEHAND_TOOL,
    ACSD_SCALE_TOOL,
	ACSD_GRADIENT_TOOL = 100
};


@interface ToolWindowController : NSWindowController
{
}

@property (assign) IBOutlet NSMatrix *toolMatrix;
@property (assign) IBOutlet NSButton *snapButton;
@property (retain) IBOutlet NSPanel *toolPanel;
@property int previousTool,lastTool;

+ (id)sharedToolWindowController:(ToolWindowController*)controller;
- (IBAction)selectToolAction:(id)sender;
- (int)currentTool;
- (void)selectArrowTool;
- (NSButton*)snapButton;
- (int)previousTool;
- (void)selectToolAtRow:(int)row column:(int)column;
-(void)selectLastTool;

@end
