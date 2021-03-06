//
//  Map.m
//  ProceduralLevelGeneration
//
//  Created by Michael T on 2014-11-11.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import "Map.h"
#import "MapTiles.h"
#import "FloorMaker.h"
#import "MyScene.h"

@interface Map ()
@property (nonatomic) MapTiles* tiles;
@property (nonatomic) SKTextureAtlas *tileAtlas;
@property (nonatomic) CGFloat tileSize;
@property (nonatomic) NSMutableArray *floorMakers;
@end

@implementation Map

+ (instancetype) mapWithGridSize:(CGSize)gridSize
{
    return [[self alloc] initWithGridSize:gridSize];
}

// todo debug. maxFloorCount should be less than gridSize.width * gridSize.height
- (instancetype) initWithGridSize:(CGSize)gridSize
{
    if (( self = [super init] ))
    {
        self.gridSize = gridSize;
        _spawnPoint = CGPointZero;
        _exitPoint = CGPointZero;
        
        // defaults if user doesn't specify
        self.maxFloorCount = 256;
        self.turnProb = 50; // 0-100 less-more likely to turn
        self.floorMakerSpawnProbability = 25; // 0-100 again. TODO use 0-1 to follow convention
        self.maxFloorMakerCount = 5;
        
        self.roomProbability = 20;
        self.roomMinSize = CGSizeMake(2, 2);
        self.roomMaxSize = CGSizeMake(6, 6);
        
        self.tileAtlas = [SKTextureAtlas atlasNamed:@"tiles"];
        NSArray *textureNames = [self.tileAtlas textureNames];
        SKTexture *tileTexture = [self.tileAtlas textureNamed:(NSString *)[textureNames firstObject]];
        self.tileSize = tileTexture.size.width;
    }
    return self;
}

- (void) generateTiles
{
    for ( NSInteger y = 0; y < self.tiles.gridSize.height; y++ )
    {
        for ( NSInteger x = 0; x < self.tiles.gridSize.width; x++ )
        {
            CGPoint tileCoordinate = CGPointMake(x, y);
            MapTileType tileType = [self.tiles tileTypeAt:tileCoordinate];
            if ( tileType != MapTileTypeNone )
            {
                SKTexture *tileTexture = [self.tileAtlas textureNamed:[NSString stringWithFormat:@"%i", tileType]];
                SKSpriteNode *tile = [SKSpriteNode spriteNodeWithTexture:tileTexture];
                tile.position = [self convertMapCoordinateToWorldCoordinate:tileCoordinate];
                [self addChild:tile];
            }
        }
    }
}

- (void) generateTileGrid
{
    CGPoint startPoint = CGPointMake(self.gridSize.width / 2, self.gridSize.height / 2);
    _spawnPoint = startPoint;

    [self.tiles setTileType:MapTileTypeFloor at:startPoint];

    self.floorMakers = [NSMutableArray array];
    [self.floorMakers addObject:[[FloorMaker alloc] initWithCurrentPosition:startPoint andDirection:0]];
    __block NSUInteger currentFloorCount = 1;
    
    // starts walking with one random walker. at every step 50-50 chance of adding another walker per current walker, at current walker's current position. the last walker sets the exit point with its current position.
    __block int actualFloorCount = 0;
    __block int dupFloorCount = 0;
    while ( currentFloorCount < self.maxFloorCount )
    {
        [self.floorMakers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            FloorMaker *floorMaker = (FloorMaker *)obj;
            // only turn if floor maker has no direction (initially) or based on turn probability: the bigger the turnProb, the more likely the walker turns
            if ( floorMaker.direction == 0 || [self randomNumberBetweenMin:0 andMax:100] < self.turnProb ){
                floorMaker.direction = [self randomNumberBetweenMin:1 andMax:4];
            }
            CGPoint newPosition;
            switch ( floorMaker.direction )
            {
                case 1: // Up
                    newPosition = CGPointMake(floorMaker.currentPosition.x, floorMaker.currentPosition.y + 1);
                    break;
                case 2: // Down
                    newPosition = CGPointMake(floorMaker.currentPosition.x, floorMaker.currentPosition.y - 1);
                    break;
                case 3: // Left
                    newPosition = CGPointMake(floorMaker.currentPosition.x - 1, floorMaker.currentPosition.y);
                    break;
                case 4: // Right
                    newPosition = CGPointMake(floorMaker.currentPosition.x + 1, floorMaker.currentPosition.y);
                    break;
            }
            if ([self.tiles isValidTileCoordinateAt:newPosition] &&
                ![self.tiles isEdgeTileAt:newPosition] &&
                [self.tiles tileTypeAt:newPosition] == MapTileTypeNone){
                
                floorMaker.currentPosition = newPosition;
                [self.tiles setTileType:MapTileTypeFloor at:floorMaker.currentPosition];
                actualFloorCount++;
            } else if ([self.tiles tileTypeAt:newPosition] == MapTileTypeFloor) {
                dupFloorCount++;
            }
            currentFloorCount++;
            _exitPoint = floorMaker.currentPosition;

            // generate room at current position
            if ( [self randomNumberBetweenMin:0 andMax:100] < self.roomProbability )
            {
                NSUInteger roomSizeX = [self randomNumberBetweenMin:self.roomMinSize.width
                                                             andMax:self.roomMaxSize.width];
                NSUInteger roomSizeY = [self randomNumberBetweenMin:self.roomMinSize.height
                                                             andMax:self.roomMaxSize.height];
                
                currentFloorCount += [self generateRoomAt:floorMaker.currentPosition
                                                 withSize:CGSizeMake(roomSizeX, roomSizeY)];
            }
            
            if ( [self randomNumberBetweenMin:0 andMax:100] <= self.floorMakerSpawnProbability &&
                [self.floorMakers count] < self.maxFloorMakerCount ){
                
                FloorMaker *newFloorMaker = [[FloorMaker alloc] initWithCurrentPosition:floorMaker.currentPosition andDirection:[self randomNumberBetweenMin:1 andMax:4]];
                [self.floorMakers addObject:newFloorMaker];
            }
        }];
    }
    NSLog(@"%@", [self.tiles description]);
    NSLog(@"currentFloorCount %i", currentFloorCount);
    NSLog(@"actual floor count %i", actualFloorCount);
    NSLog(@"dup floor count %i", dupFloorCount);
    NSLog(@"random walkers %i", [self.floorMakers count]);
}

- (void) generateWallGrid
{
    for ( NSInteger y = 0; y < self.tiles.gridSize.height; y++ )
    {
        for ( NSInteger x = 0; x < self.tiles.gridSize.width; x++ )
        {
            CGPoint tileCoordinate = CGPointMake(x, y);
            if ( [self.tiles tileTypeAt:tileCoordinate] == MapTileTypeNone )
            {
                [self.tiles setTileType:MapTileTypeWall at:tileCoordinate];
            }
        }
    }
}

- (void) generate {
    self.tiles = [[MapTiles alloc] initWithGridSize:self.gridSize];
    [self generateTileGrid];
    [self generateWallGrid];
    [self generateCollisionWalls];
    [self generateTiles];
    _spawnPoint = [self convertMapCoordinateToWorldCoordinate:_spawnPoint];
    _exitPoint = [self convertMapCoordinateToWorldCoordinate:_exitPoint];
}

- (void) addCollisionWallAtPosition:(CGPoint)position withSize:(CGSize)size
{
    SKNode *wall = [SKNode node];
    
    wall.position = CGPointMake(position.x + size.width * 0.5f - 0.5f * self.tileSize,
                                position.y - size.height * 0.5f + 0.5f * self.tileSize);
    wall.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:size];
    wall.physicsBody.dynamic = NO;
    wall.physicsBody.categoryBitMask = CollisionTypeWall;
    wall.physicsBody.contactTestBitMask = 0;
    wall.physicsBody.collisionBitMask = CollisionTypePlayer;
    
    [self addChild:wall];
}

- (void) generateCollisionWalls
{
    for ( NSInteger y = 0; y < self.tiles.gridSize.height; y++ )
    {
        CGFloat startPointForWall = 0;
        CGFloat wallLength = 0;
        for ( NSInteger x = 0; x < self.tiles.gridSize.width; x++ )
        {
            BOOL isWall = [self.tiles tileTypeAt:CGPointMake(x, y)] == MapTileTypeWall;
            // add the wall tile to the current wall
            if (isWall)
            {
                if ( startPointForWall == 0 && wallLength == 0 )
                {
                    // startPointForWall is the first wall tile you see, and it goes on for wallLength tiles
                    startPointForWall = x;
                }
                wallLength += 1;
            }
            // actually create the wall
            if ((!isWall && wallLength > 0) || (x == self.tiles.gridSize.width - 1)){
                CGPoint wallOrigin = CGPointMake(startPointForWall, y);
                CGSize wallSize = CGSizeMake(wallLength * self.tileSize, self.tileSize);
                [self addCollisionWallAtPosition:[self convertMapCoordinateToWorldCoordinate:wallOrigin]
                                        withSize:wallSize];
                startPointForWall = 0;
                wallLength = 0;
            }
        }
    }
}

- (NSUInteger) generateRoomAt:(CGPoint)position withSize:(CGSize)size
{
    NSUInteger numberOfFloorsGenerated = 0;
    for ( NSUInteger y = 0; y < size.height; y++)
    {
        for ( NSUInteger x = 0; x < size.width; x++ )
        {
            CGPoint tilePosition = CGPointMake(position.x + x, position.y + y);
            if ([self.tiles isValidTileCoordinateAt:tilePosition] &&
                ![self.tiles isEdgeTileAt:tilePosition] &&
                [self.tiles tileTypeAt:tilePosition] == MapTileTypeNone){
                
                [self.tiles setTileType:MapTileTypeFloor at:tilePosition];
                numberOfFloorsGenerated++;
            }
        }
    }
    return numberOfFloorsGenerated;
}

- (CGPoint) convertMapCoordinateToWorldCoordinate:(CGPoint)mapCoordinate
{
    return CGPointMake(mapCoordinate.x * self.tileSize, mapCoordinate.y * self.tileSize);
}

// returns random int in [min, max]
- (NSInteger) randomNumberBetweenMin:(NSInteger)min andMax:(NSInteger)max
{
    return min + arc4random() % (max - min + 1);
}


@end
