//
//  SceneView.h
//  ACSDraw
//
//  Created by alan on 06/02/16.
//
//

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>
@class GroupViewController;

@interface SceneView : SCNView

@property (strong) IBOutlet GroupViewController *controller;

@end
