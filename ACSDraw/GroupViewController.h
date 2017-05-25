//
//  GroupViewController.h
//  ACSDraw
//
//  Created by Alan on 03/02/2016.
//
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "SceneView.h"
#import "GraphicView.h"

#define RADIANS(x) ((x)/(360.0/(2.0 * M_PI)))
#define DEGREES(x) ((x)*(360.0/(2.0 * M_PI)))

@class ACSDGraphic;

@interface GroupViewController : NSObject<NSOutlineViewDataSource,NSOutlineViewDelegate,NSTextFieldDelegate>

@property (assign) IBOutlet SceneView *sceneView;
@property (assign) IBOutlet NSOutlineView *outlineView;
@property (retain) GraphicView *graphicView;
@property (retain) ACSDGraphic *graphic;

@property (retain) SCNScene *scene;
@property (retain) SCNCamera *camera;
@property (nonatomic)float displayZInc;
@property (nonatomic)float displayZVal;

-(void)mouseUp:(NSEvent *)theEvent;
-(void)mouseDragged:(NSEvent *)theEvent;
-(void)mouseDown:(NSEvent *)theEvent;
-(void)setUpObjectsForGraphic:(ACSDGraphic*)graphic;

@end
