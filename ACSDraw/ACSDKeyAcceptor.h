//
//  ACSDKeyAcceptor.h
//  ACSDraw
//
//  Created by Alan on 06/07/2023.
//

#import <Foundation/Foundation.h>


@protocol ACSDKeyAcceptor <NSObject>

-(void)keyHit:(unichar)key;
@end

