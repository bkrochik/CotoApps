//
//  MiniGameCutBird.mm
//  Sailboat
//
//  Created by Federico Carossino on 10/10/12.
//  Copyright 2012 Brian Krochik. All rights reserved.
//

#import "MiniGameCutBird.h"
// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "PhysicsSprite.h"
#import "GB2ShapeCache.h"
// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"
#import <QuartzCore/QuartzCore.h>


@interface MiniGameCutBird()
-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
@end

@implementation MiniGameCutBird

struct fixtureUserData {
    int tag;
};

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MiniGameCutBird *layer = [MiniGameCutBird node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
    if( (self=[super init])) {
        CGSize winSize = [CCDirector sharedDirector].winSizeInPixels;
        //Background
        NSString * bgImg;
        bgImg=@"coast.jpeg";
        CCSprite * bg = [CCSprite spriteWithFile:bgImg];
        bg.position = ccp(0,200);
        bg.scale=CC_CONTENT_SCALE_FACTOR();
        [self addChild:bg z:0];
        
		// enable events
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
        [self initPhysics];
        
        //Set the score to zero.
        score = 0;
        life = 3;
        CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:@"streak.png"];
        //Create and add the life label as a child.
        scoreLabel = [CCLabelTTF labelWithString:@"Puntos 0" fontName:@"Marker Felt" fontSize:24];
        
        //Create and add the score label as a child.
        if(CC_CONTENT_SCALE_FACTOR()==1.0f){
            scoreLabel.position = ccp(240, (winSize.height-20));
        }else{
            scoreLabel.position = ccp(winSize.width-(190*CC_CONTENT_SCALE_FACTOR()), winSize.height-(248*CC_CONTENT_SCALE_FACTOR()));
        }
        
        [self addChild:scoreLabel z:1];
        
        //Create and add the life label as a child.
        lifeLabel = [CCLabelTTF labelWithString:@"Vidas 3" fontName:@"Marker Felt" fontSize:24];
        
        if(CC_CONTENT_SCALE_FACTOR()==1.0f){
            lifeLabel.position = ccp(50, (winSize.height-20));
        }else{
            lifeLabel.position = ccp(winSize.width-(300*CC_CONTENT_SCALE_FACTOR()),winSize.height-(248*CC_CONTENT_SCALE_FACTOR()));
        }
        [self addChild:lifeLabel z:1];
    }
    
    
    b2PolygonShape polygonShape;
    polygonShape.SetAsBox(1, 1);
    
    
    // Create contact listener
    //_contactListener = new MyContactListener();
    //world->SetContactListener(_contactListener);
    
    
    //Add fly
    [self createFly];
	
    
    //[self schedule:@selector(tick:)];
    
	return self;
}

-(void) initPhysics
{
    CGSize winSize = [CCDirector sharedDirector].winSizeInPixels;
    
	// Create a world
    b2Vec2 gravity = b2Vec2(0.0f, -30.0f);
    world = new b2World(gravity);
    
    // Create edges around the entire screen
    b2BodyDef groundBodyDef;
    groundBodyDef.type=b2_staticBody;
    groundBodyDef.position.Set(0,0);
    groundBodyDef.userData=(void*)-1;
    b2Body *groundBody = world->CreateBody(&groundBodyDef);
    
    b2EdgeShape groundEdge;
    b2FixtureDef boxShapeDef;
    b2FixtureDef boxShapeDefFloor;
    
    fixtureUserData *fixDef = new fixtureUserData();
    fixDef->tag=-1;
    boxShapeDefFloor.shape = &groundEdge;
    boxShapeDefFloor.userData=fixDef;
    
    fixtureUserData *fixDefAll = new fixtureUserData();
    fixDefAll->tag=1000;
    boxShapeDef.shape = &groundEdge;
    boxShapeDef.userData=fixDefAll;
    
    groundEdge.Set(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RATIO,0));
    groundBody->CreateFixture(&boxShapeDefFloor);
    groundEdge.Set(b2Vec2(0,0), b2Vec2(0, winSize.height/PTM_RATIO));
    groundBody->CreateFixture(&boxShapeDef);
    groundEdge.Set(b2Vec2(0, winSize.height/PTM_RATIO),
                   b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO));
    groundBody->CreateFixture(&boxShapeDef);
    groundEdge.Set(b2Vec2(winSize.width/PTM_RATIO,
                          winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, 0));
    groundBody->CreateFixture(&boxShapeDef);
}

-  ( void ) createFly {
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"fly.plist"];
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"fly.png"];
    NSMutableArray *flyBirdFrames = [NSMutableArray array];
    for (int i = 1; i<=3; ++i) {
        [flyBirdFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"fly_move_%d.png", i]]];
    }
    
    CCAnimation *flybird = [CCAnimation animationWithFrames:flyBirdFrames delay:0.2f];
    CGSize winSize = [CCDirector sharedDirector].winSizeInPixels;
    CCSprite *bird = [CCSprite spriteWithSpriteFrameName:@"fly_move_1.png"];
    bird.position = ccp(0, winSize.height/2);
    CCAction *flyAction = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:flybird restoreOriginalFrame:NO]];
    CCAction *moveAction = [CCMoveTo actionWithDuration:2.0 position:ccp(winSize.width-20, winSize.height/3)];
    CCAction *moveActionBack = [CCMoveTo actionWithDuration:4.0 position:ccp(0, winSize.height -20)];
    
    id flipX = [CCFlipX actionWithFlipX:YES];
    id flipXX = [CCFlipX actionWithFlipX:NO];
    
    [bird runAction:flyAction];
    [bird runAction: [CCRepeatForever actionWithAction:[CCSequence actions:moveAction,flipX,moveActionBack,flipXX,nil]]];
    [spriteSheet addChild:bird];
    
    [self addChild:spriteSheet];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches){
        CGPoint location = [touch locationInView:[touch view]];
        location = [[CCDirector sharedDirector] convertToGL:location];
        _startPoint = location;
        _endPoint = location;
        CCLOG(@"Slice Entered at world coordinates:(%f,%f)",_startPoint, _endPoint);
    }
}

// Add this method
- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches){
        CGPoint location = [touch locationInView:[touch view]];
        location = [[CCDirector sharedDirector] convertToGL:location];
        _endPoint = location;
//        if (ccpLengthSQ(ccpSub(_startPoint, _endPoint)) > 25)
//        {
//            world->RayCast(_raycastCallback,
//                           b2Vec2(_startPoint.x / PTM_RATIO, _startPoint.y / PTM_RATIO),
//                           b2Vec2(_endPoint.x / PTM_RATIO, _endPoint.y / PTM_RATIO));
//            
//            world->RayCast(_raycastCallback,
//                           b2Vec2(_endPoint.x / PTM_RATIO, _endPoint.y / PTM_RATIO),
//                           b2Vec2(_startPoint.x / PTM_RATIO, _startPoint.y / PTM_RATIO));
//            _startPoint = _endPoint;
//        }
    }
}

//-(void)checkAndSliceObjects
//{
//    double curTime = CACurrentMediaTime();
//    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
//    {
//        if (b->GetUserData() != NULL) {
//            PolygonSprite *sprite = (PolygonSprite*)b->GetUserData();
//            
//            if (sprite.sliceEntered && curTime > sprite.sliceEntryTime)
//            {
//                sprite.sliceEntered = NO;
//            }
//            else if (sprite.sliceEntered && sprite.sliceExited)
//            {
//                [self splitPolygonSprite:sprite];
//            }
//        }
//    }
//}


@end
