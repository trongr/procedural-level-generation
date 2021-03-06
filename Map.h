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

// fine tuning map generation
@property (nonatomic) NSUInteger turnProb;
@property (nonatomic) NSUInteger floorMakerSpawnProbability;
@property (nonatomic) NSUInteger maxFloorMakerCount;

// more options for room sizes
@property (nonatomic) NSUInteger roomProbability;
@property (nonatomic) CGSize roomMinSize;
@property (nonatomic) CGSize roomMaxSize;

+ (instancetype) mapWithGridSize:(CGSize)gridSize;
- (instancetype) initWithGridSize:(CGSize)gridSize;

- (void) generate;

@end
