//
//  FloorMaker.h
//  ProceduralLevelGeneration
//
//  Created by Michael T on 2014-11-13.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FloorMaker : NSObject
@property (nonatomic) CGPoint currentPosition;
@property (nonatomic) NSUInteger direction;

- (instancetype) initWithCurrentPosition:(CGPoint)currentPosition andDirection:(NSUInteger)direction;
@end
