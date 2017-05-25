//
//  GXPArchiveDelegate.h
//  ACSDraw
//
//  Created by alan on 29/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GXPArchiveDelegate : NSObject<NSKeyedArchiverDelegate>
{

}
-(BOOL)filterLayers:(BOOL)b;

@end
