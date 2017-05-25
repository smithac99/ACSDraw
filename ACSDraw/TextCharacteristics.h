//
//  TextCharacteristics.h
//  ACSDraw
//
//  Created by Alan Smith on 19/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TextCharacteristics <NSObject>
- (float)topMargin;
- (float)leftMargin;
- (float)bottomMargin;
- (float)rightMargin;
- (VerticalAlignment)verticalAlignment;
@end
