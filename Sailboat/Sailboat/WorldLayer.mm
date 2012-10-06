//
//  HelloWorldLayer.mm
//  Sailboat
//
//  Created by Brian Krochik on 04/10/12.
//  Copyright Brian Krochik 2012. All rights reserved.
//

// Import the interfaces
#import "WorldLayer.h"
// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"
// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "PhysicsSprite.h"
#import "GB2ShapeCache.h"

enum {
	kTagParentNode = 1,
};

@interface WorldLayer()
-(void) initPhysics;
-(void) createMenu;
@end

@implementation WorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	WorldLayer *layer = [WorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
		
		// enable events
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
		CGSize s = [CCDirector sharedDirector].winSize;
		
		// init physics
		[self initPhysics];
        
        _wave=[Terrain nodeWithTerrainType:1:world];
        //Generate Terrain
        [self addChild:_wave z:1];
        //_wave2 = [Terrain nodeWithTerrainType:2:world];
        //[self addChild:_wave2 z:1];
        
		[self scheduleUpdate];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
	
	[super dealloc];
}	

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
	// Reset Button
	CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [WorldLayer scene]];
	}];
	
	// Achievement Menu Item using blocks
	CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id sender) {
		
		
		GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
		achivementViewController.achievementDelegate = self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:achivementViewController animated:YES];
		
		[achivementViewController release];
	}];
	
	// Leaderboard Menu Item using blocks
	CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
		
		
		GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
		leaderboardViewController.leaderboardDelegate = self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:leaderboardViewController animated:YES];
		
		[leaderboardViewController release];
	}];
	
	CCMenu *menu = [CCMenu menuWithItems:itemAchievement, itemLeaderboard, reset, nil];
	
	[menu alignItemsVertically];
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	[menu setPosition:ccp( size.width/2, size.height/2)];
	
	
	[self addChild: menu z:-1];	
}

-(void) initPhysics
{

	CGSize s = [CCDirector sharedDirector].winSizeInPixels;
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);		
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;		
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	//groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	//groundBody->CreateFixture(&groundBox,0);
}

-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	world->DrawDebugData();
	
	kmGLPopMatrix();
}

-(void) update: (ccTime) dt
{
    world->Step(dt/CC_CONTENT_SCALE_FACTOR(), 10, 10);
    for(b2Body *b = world->GetBodyList(); b; b=b->GetNext()) {
        if (b->GetUserData() !=(void*)-1) {
            CCSprite *spData = (CCSprite *)b->GetUserData();
            spData.position = ccp(b->GetPosition().x * PTM_RATIO,
                                  b->GetPosition().y * PTM_RATIO);
            spData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
        }
        
    }
    
    //move waves
    float PIXELS_PER_SECOND = 100;
    offset += PIXELS_PER_SECOND * dt;
    [_wave setOffsetX:offset];
    self.position = CGPointMake(-offset*self.scale, 0);
    
    //[_wave2 setOffsetX:offsetWave2];
}
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		location = [[CCDirector sharedDirector] convertToGL: location];
        [self createBall:location];
	}
}

-(void) createBall:(CGPoint)p
{
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CCSprite *_newBall;
    _newBall = [CCSprite spriteWithFile:@"egg.png" rect:CGRectMake(0, 0, 43, 49)];
    _newBall.position = ccp(100, 100);
    [self addChild:_newBall  z:0 tag:2];
    
    // Create ball body and shape new
    b2BodyDef newBallBodyDef;
    newBallBodyDef.type = b2_dynamicBody;
    newBallBodyDef.position.Set((p.x+offset)/PTM_RATIO,p.y/PTM_RATIO);
    newBallBodyDef.userData = _newBall;
    b2Body *body = world->CreateBody(&newBallBodyDef);
    
    [[GB2ShapeCache sharedShapeCache]   addShapesWithFile:@"egg.plist"];
    [[GB2ShapeCache sharedShapeCache] addFixturesToBody:body forShapeName:@"egg"];
    [_newBall setAnchorPoint: [[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"egg"]];
}

#pragma mark GameKit delegate
-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

@end
