//
//  MyScene.m
//  ProceduralLevelGeneration
//
//  Created by Kim Pedersen on 09/08/13.
//  Copyright (c) 2013 Kim Pedersen. All rights reserved.
//

#import "MyScene.h"
#import "DPad.h"
#import "Map.h"

static const CGFloat kPlayerMovementSpeed = 100.0f;

@interface MyScene() <SKPhysicsContactDelegate>
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) SKNode *world;
@property (nonatomic) SKNode *hud;
@property (nonatomic) DPad *dPad;
@property (nonatomic) Map *map;
@property (nonatomic) SKSpriteNode *exit;
@property (nonatomic) SKTextureAtlas *spriteAtlas;
@property (nonatomic) SKSpriteNode *player;
@property (nonatomic) SKSpriteNode *playerShadow;
@property (nonatomic) BOOL isExitingLevel;
@property (nonatomic) NSArray *playerIdleAnimationFrames;
@property (nonatomic) NSArray *playerWalkAnimationFrames;
@property (nonatomic) NSUInteger playerAnimationID; // 0 = idle; 1 = walk
@end


@implementation MyScene

- (id)initWithSize:(CGSize)size
{
    if (( self = [super initWithSize:size] ))
    {
        self.backgroundColor = [SKColor colorWithRed:175.0f/255.0f green:143.0f/255.0f blue:106.0f/255.0f alpha:1.0f];
        self.isExitingLevel = NO;
        
        // Add a node for the world - this is where sprites and tiles are added
        self.world = [SKNode node];
        
        // Load the atlas that contains the sprites
        self.spriteAtlas = [SKTextureAtlas atlasNamed:@"sprites"];
        
        // Create a new map
        self.map = [[Map alloc] init];
        
        // Create the exit
        self.exit = [SKSpriteNode spriteNodeWithTexture:[self.spriteAtlas textureNamed:@"exit"]];
        self.exit.position = self.map.exitPoint;
        self.exit.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.exit.texture.size.width - 16, self.exit.texture.size.height - 16)];
        self.exit.physicsBody.categoryBitMask = CollisionTypeExit;
        self.exit.physicsBody.collisionBitMask = 0;
        
        // Create a player node
        self.player = [SKSpriteNode spriteNodeWithTexture:[self.spriteAtlas textureNamed:@"idle_0"]];
        self.player.position = self.map.spawnPoint;
        self.player.physicsBody.allowsRotation = NO;
        self.player.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.player.texture.size];
        self.player.physicsBody.categoryBitMask = CollisionTypePlayer;
        self.player.physicsBody.contactTestBitMask = CollisionTypeExit;
        self.player.physicsBody.collisionBitMask = CollisionTypeWall;
        
        // Load sprites for player into arrays for the animations
        self.playerIdleAnimationFrames = @[[self.spriteAtlas textureNamed:@"idle_0"]];
        
        self.playerWalkAnimationFrames = @[[self.spriteAtlas textureNamed:@"walk_0"],
                                           [self.spriteAtlas textureNamed:@"walk_1"],
                                           [self.spriteAtlas textureNamed:@"walk_2"]];
        
        self.playerShadow = [SKSpriteNode spriteNodeWithTexture:[self.spriteAtlas textureNamed:@"shadow"]];
        self.playerShadow.xScale = 0.6f;
        self.playerShadow.yScale = 0.5f;
        self.playerShadow.alpha = 0.4f;
        
        self.playerAnimationID = 0;
        
        [self.world addChild:self.map];
        [self.world addChild:self.exit];
        [self.world addChild:self.playerShadow];
        [self.world addChild:self.player];
        
        // Create a node for the HUD - this is where the DPad to control the player sprite will be added
        self.hud = [SKNode node];
        
        // Create the DPads
        self.dPad = [[DPad alloc] initWithRect:CGRectMake(0, 0, 64.0f, 64.0f)];
        self.dPad.position = CGPointMake(64.0f / 4, 64.0f / 4);
        self.dPad.numberOfDirections = 24;
        self.dPad.deadRadius = 8.0f;
        
        [self.hud addChild:self.dPad];
        
        // Add the world and hud nodes to the scene
        [self addChild:self.world];
        [self addChild:self.hud];
        
        // Initialize physics
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
    }
    return self;
}


- (void) update:(CFTimeInterval)currentTime
{
    // Calculate the time since last update
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    
    self.lastUpdateTimeInterval = currentTime;
    
    if ( timeSinceLast > 1 )
    {
        timeSinceLast = 1.0f / 60.0f;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    // Poll the DPad
    CGPoint playerVelocity = self.isExitingLevel ? CGPointZero : self.dPad.velocity;
    
    // Update player sprite position and orientation based on DPad input
    self.player.position = CGPointMake(self.player.position.x + playerVelocity.x * timeSinceLast * kPlayerMovementSpeed,
                                       self.player.position.y + playerVelocity.y * timeSinceLast * kPlayerMovementSpeed);
    
    if ( playerVelocity.x != 0.0f )
    {
        self.player.xScale = (playerVelocity.x > 0.0f) ? -1.0f : 1.0f;
    }
    
    // Ensure correct animation is playing
    self.playerAnimationID = (playerVelocity.x != 0.0f) ? 1 : 0;
    
    [self resolveAnimationWithID:self.playerAnimationID];
    
    // Move "camera" so the player is in the middle of the screen
    self.world.position = CGPointMake(-self.player.position.x + CGRectGetMidX(self.frame),
                                      -self.player.position.y + CGRectGetMidY(self.frame));
}


- (void) didSimulatePhysics
{
    self.player.zRotation = 0.0f;
    
    // Sync shadow with player sprite
    self.playerShadow.position = CGPointMake(self.player.position.x, self.player.position.y - 7.0f);
}


- (void) resolveAnimationWithID:(NSUInteger)animationID
{
    NSString *animationKey = nil;
    NSArray *animationFrames = nil;
    
    switch (animationID)
    {
        case 0:
            // Idle
            animationKey = @"anim_idle";
            animationFrames = self.playerIdleAnimationFrames;
            break;
            
        default:
            // Walk
            animationKey = @"anim_walk";
            animationFrames = self.playerWalkAnimationFrames;
            break;
    }
    
    SKAction *animAction = [self.player actionForKey:animationKey];
    
    // If this animation is already running or there are no frames we exit
    if ( animAction || animationFrames.count < 1 )
    {
        return;
    }
    
    animAction = [SKAction animateWithTextures:animationFrames timePerFrame:5.0f/60.0f resize:YES restore:NO];
    
    if ( animationID == 1 )
    {
        // Append sound for walking
        animAction = [SKAction group:@[animAction, [SKAction playSoundFileNamed:@"step.wav" waitForCompletion:NO]]];
    }
    
    [self.player runAction:animAction withKey:animationKey];
}


- (void) resolveExit
{
    // Disables DPad
    self.isExitingLevel = YES;
    
    // Remove shadow
    [self.playerShadow removeFromParent];
    
    // Animations
    SKAction *moveAction = [SKAction moveTo:self.map.exitPoint duration:0.5f];
    SKAction *rotateAction = [SKAction rotateByAngle:(M_PI * 2) duration:0.5f];
    SKAction *fadeAction = [SKAction fadeAlphaTo:0.0f duration:0.5f];
    SKAction *scaleAction = [SKAction scaleXTo:0.0f y:0.0f duration:0.5f];
    SKAction *soundAction = [SKAction playSoundFileNamed:@"win.wav" waitForCompletion:NO];
    SKAction *blockAction = [SKAction runBlock:^{
        [self.view presentScene:[[MyScene alloc] initWithSize:self.size] transition:[SKTransition doorsCloseVerticalWithDuration:0.5f]];
    }];
    
    SKAction *exitAnimAction = [SKAction sequence:@[[SKAction group:@[moveAction, rotateAction, fadeAction, scaleAction, soundAction]], blockAction]];
    
    [self.player runAction:exitAnimAction];
}


- (void) didBeginContact:(SKPhysicsContact *)contact
{
    // 1
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // 2
    if ((firstBody.categoryBitMask & CollisionTypePlayer) != 0 && (secondBody.categoryBitMask & CollisionTypeExit) != 0)
    {
        // Player reached exit
        NSLog(@"Player reached exit");
        
        [self resolveExit];
    }
}

@end
