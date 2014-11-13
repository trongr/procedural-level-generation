//
//  Map.m
//  ProceduralLevelGeneration
//
//  Created by Michael T on 2014-11-11.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import "Map.h"
#import "MapTiles.h"

@interface Map ()
@property (nonatomic) MapTiles* tiles;
@property (nonatomic) SKTextureAtlas *tileAtlas;
@property (nonatomic) CGFloat tileSize;
@end

@implementation Map

+ (instancetype) mapWithGridSize:(CGSize)gridSize
{
    return [[self alloc] initWithGridSize:gridSize];
}

- (instancetype) initWithGridSize:(CGSize)gridSize
{
    if (( self = [super init] ))
    {
        self.gridSize = gridSize;
        _spawnPoint = CGPointZero;
        _exitPoint = CGPointZero;
        
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
    
    [self.tiles setTileType:MapTileTypeFloor at:startPoint];
    NSUInteger currentFloorCount = 1;
    CGPoint currentPosition = startPoint;
    _spawnPoint = startPoint;
    
    while ( currentFloorCount < self.maxFloorCount )
    {
        NSInteger direction = [self randomNumberBetweenMin:1 andMax:4];
        CGPoint newPosition;
        switch ( direction )
        {
            case 1: // Up
                newPosition = CGPointMake(currentPosition.x, currentPosition.y + 1);
                break;
            case 2: // Down
                newPosition = CGPointMake(currentPosition.x, currentPosition.y - 1);
                break;
            case 3: // Left
                newPosition = CGPointMake(currentPosition.x - 1, currentPosition.y);
                break;
            case 4: // Right
                newPosition = CGPointMake(currentPosition.x + 1, currentPosition.y);
                break;
        }
    
        if([self.tiles isValidTileCoordinateAt:newPosition] &&
           ![self.tiles isEdgeTileAt:newPosition] &&
           [self.tiles tileTypeAt:newPosition] == MapTileTypeNone)
        {
            currentPosition = newPosition;
            [self.tiles setTileType:MapTileTypeFloor at:currentPosition];
        }
        currentFloorCount++; // putting this guy cause otw can't get out of while loop
    }
    _exitPoint = currentPosition;
    NSLog(@"%@", [self.tiles description]);
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
    [self generateTiles];
    _spawnPoint = [self convertMapCoordinateToWorldCoordinate:_spawnPoint];
    _exitPoint = [self convertMapCoordinateToWorldCoordinate:_exitPoint];
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
