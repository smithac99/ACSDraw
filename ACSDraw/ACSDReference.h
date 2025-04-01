//
//  ACSDReference.h
//  ACSDraw
//
//  Created by Alan on 11/03/2016.
//
//

#import "ACSDGraphic.h"

@interface ACSDReference : ACSDGraphic<NSSecureCoding>

@property (strong) ACSDGraphic *referenceGraphic;
@end
