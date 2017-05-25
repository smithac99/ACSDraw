/* HtmlExportController */

#import <Cocoa/Cocoa.h>

enum
   {
	   PICS_ORIGINAL=0,
	   PICS_MAX_DIM,
	   PICS_MAX_AREA,
	   VECTOR_GRAPHICS_BITMAP = 0,
	   VECTOR_GRAPHICS_SVG,
	   VECTOR_GRAPHICS_CANVAS
   };

@interface HtmlExportController : NSObject
   {
    IBOutlet id clickThroughCB;
    IBOutlet id document;
    IBOutlet id ieCompatibility;
    IBOutlet id picFormatMenu;
    IBOutlet id picDimension;
    IBOutlet id picArea;
    IBOutlet id picSizeRB;
    IBOutlet id vectorGraphicsRB;
	IBOutlet id openAfterExportCB;
   }

@property (retain) IBOutlet id accessoryView;

-(BOOL)clickThrough;
-(NSString*)picFormat;
- (IBAction)clickThroughCBHit:(id)sender;
-(void)enableControls;
-(int)clickThroughLimitType;
-(int)clickThroughLimit;
-(void)setControls:(NSMutableDictionary*)htmlSettings;
-(void)updateSettingsFromControls:(NSMutableDictionary*)htmlSettings;

@end

