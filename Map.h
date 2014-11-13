//
//  Map.h
//  ProceduralLevelGeneration
//
//  Created by Michael T on 2014-11-11.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Map : SKNode

@property (nonatomic) CGSize gridSize;
@property (nonatomic, readonly) CGPoint spawnPoint;
@property (nonatomic, readonly) CGPoint exitPoint;
@property (nonatomic) NSUInteger maxFloorCount;

+ (instancetype) mapWithGridSize:(CGSize)gridSize;
- (instancetype) initWithGridSize:(CGSize)gridSize;

- (void) generate;

@end
