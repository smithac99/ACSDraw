#import "ToolWindowController.h"

NSString *ACSDSelectedToolDidChangeNotification = @"ACSDSelectedToolDidChange";
NSString *ACSDSnapButtonDidChangeNotification = @"ACSDSnapButtonDidChange";
NSString *prefsSnapKey = @"ACSDrawSnap";


@implementation ToolWindowController

+ (id)sharedToolWindowController:(ToolWindowController*)controller
   {
    static ToolWindowController *sharedToolWindowController = nil;
	if (controller)
        sharedToolWindowController = controller;
    return sharedToolWindowController;
   }

-(id)init
{
	if (self = [super init])
		self.previousTool = -1;
	return self;
}

-(void)awakeFromNib
   {
	[ToolWindowController sharedToolWindowController:self];
    for (NSCell *cell in [self.toolMatrix cells])
        [cell setRefusesFirstResponder:YES];
    [self.toolPanel setFloatingPanel:YES];
    [self.toolPanel setBecomesKeyOnlyIfNeeded:YES];
	[self.snapButton setIntegerValue:[[NSUserDefaults standardUserDefaults] integerForKey:prefsSnapKey]];
   }

- (IBAction)selectToolAction:(id)sender
   {
       self.lastTool = self.previousTool;
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDSelectedToolDidChangeNotification object:self];
	self.previousTool = [self currentTool];
   }

- (IBAction)snapButtonHit:(id)sender
   {
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDSnapButtonDidChangeNotification object:self];
	[[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:prefsSnapKey];
   }

- (int)currentTool
{
    return (int)([self.toolMatrix selectedRow] * 2 + [self.toolMatrix selectedColumn]);
}

- (void)selectToolAtRow:(int)row column:(int)column
{
    self.lastTool = [self currentTool];
    [self.toolMatrix selectCellAtRow:row column:column];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACSDSelectedToolDidChangeNotification object:self];
    self.previousTool = [self currentTool];
}

- (void)selectArrowTool
{
	[self selectToolAtRow:0 column:0];
}

-(void)selectLastTool
{
    if (self.lastTool >= 0)
    {
        int row = self.lastTool / 2;
        int col = self.lastTool % 2;
        [self selectToolAtRow:row column:col];
    }
}

@end
