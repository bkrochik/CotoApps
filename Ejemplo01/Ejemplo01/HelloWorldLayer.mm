//
//  HelloWorldLayer.mm
//  Ejemplo01
//
//  Created by Brian Krochik on 01/10/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#ifdef __CC_PLATFORM_IOS
#define PARTICLE_FIRE_NAME @"fire.pvr"
#elif defined(__CC_PLATFORM_MAC)
#define PARTICLE_FIRE_NAME @"fire.png"
#endif

// Import the interfaces
#import "HelloWorldLayer.h"
// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "PhysicsSprite.h"
#import "GB2ShapeCache.h"
#import <QuartzCore/QuartzCore.h>

enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()
-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
-(void) createMenu;
@end

@implementation HelloWorldLayer

struct fixtureUserData {
    int tag;
};

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
    if( (self=[super init])) {
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        //Background
        CCSprite * bg = [CCSprite spriteWithFile:@"kitchen.jpeg"];
        bg.position = ccp(0, 200);
        [self addChild:bg z:0];
        
		// enable events
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
        [self initPhysics];
        
        //Set the score to zero.
        score = 0;
        life = 3;
        
        //Create and add the score label as a child.
        scoreLabel = [CCLabelTTF labelWithString:@"Puntos 0" fontName:@"Marker Felt" fontSize:24];
        scoreLabel.position = ccp(240, (winSize.height-20));
        [self addChild:scoreLabel z:1];
        
        //Create and add the life label as a child.
        lifeLabel = [CCLabelTTF labelWithString:@"Vidas 3" fontName:@"Marker Felt" fontSize:24];
        lifeLabel.position = ccp(50, (winSize.height-20));
        [self addChild:lifeLabel z:1];
    }
    
    
    // Create sprite and add it to the layer
    _pan = [CCSprite spriteWithFile:@"pan.png" rect:CGRectMake(0, 0, 200, 142)];
    _pan.position = ccp(0, 0);
    [self addChild:_pan  z:0 tag:1];
    
    
    
    // Create pan body and shape
    b2BodyDef panBodyDef;
    panBodyDef.type = b2_staticBody;
    panBodyDef.position.Set(100/PTM_RATIO, 20/PTM_RATIO);
    panBodyDef.userData = _pan;
    _body = world->CreateBody(&panBodyDef);
    
    b2PolygonShape polygonShape;
    polygonShape.SetAsBox(1, 1);
    
    [[GB2ShapeCache sharedShapeCache]   addShapesWithFile:@"pan.plist"];
    [[GB2ShapeCache sharedShapeCache] addFixturesToBody:_body forShapeName:@"pan"];
    [_pan setAnchorPoint: [[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"pan"]];
    
    [self schedule:@selector(addBall) interval:2];
    
    // Create contact listener
    _contactListener = new MyContactListener();
    world->SetContactListener(_contactListener);
    
    
    //Add fly
    [self createFly];
	
    
    [self schedule:@selector(tick:)];
    
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	_pan=NULL;
    
	delete m_debugDraw;
	m_debugDraw = NULL;
	
	[super dealloc];
}

- (void)addPoint
{
    score = score + 1; //I think: score++; will also work.
    [scoreLabel setString:[NSString stringWithFormat:@"Puntos %d", score]];
}
- (void)loseLife
{
    if(life==1){
        [[CCDirector sharedDirector] replaceScene:
         [CCTransitionFlipX transitionWithDuration:1.8f scene:[GameOverLayer scene]]];
        return;
    }
    
    life = life - 1; //I think: score++; will also work.
    [lifeLabel setString:[NSString stringWithFormat:@"Vidas %d", life]];
}
-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
	// Reset Button
	CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
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
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
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

-(void) addBall
{
    //Random position
    int maxBalls;
    if (score>30){
        maxBalls= score/10;
    }else{
        maxBalls=3;
    }
    int tot = rand() % maxBalls;
    int i=0;
    for (i = 0; i < tot; i++)
    {
        double time = 0.5 *i;
        id delay = [CCDelayTime actionWithDuration: time];
        id callbackAction = [CCCallFunc actionWithTarget: self selector: @selector(createBall)];
        id sequence = [CCSequence actions: delay, callbackAction, nil];
        [self runAction: sequence];
    }
}

-(void) createBall
{
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CCSprite *_newBall;
    _newBall = [CCSprite spriteWithFile:@"egg.png" rect:CGRectMake(0, 0, 43, 49)];
    _newBall.position = ccp(100, 100);
    [self addChild:_newBall  z:0 tag:2];
    
    //Random position
    int maxValue = (int)winSize.width;
    int r = rand() % maxValue;
    //Random Height
    int maxHeight = 3;
    int h = (rand() % maxHeight);
    
    // Create ball body and shape new
    b2BodyDef newBallBodyDef;
    newBallBodyDef.type = b2_dynamicBody;;
    newBallBodyDef.position.Set(r/PTM_RATIO, (winSize.height-30-(h*10))/PTM_RATIO);
    newBallBodyDef.userData = _newBall;
    b2Body *body = world->CreateBody(&newBallBodyDef);
        
    [[GB2ShapeCache sharedShapeCache]   addShapesWithFile:@"egg.plist"];
    [[GB2ShapeCache sharedShapeCache] addFixturesToBody:body forShapeName:@"egg"];
    [_newBall setAnchorPoint: [[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"egg"]];
    
    //Random rotation
    int maxDegree = 7;
    int degree = rand() % maxDegree;
    int maxforce;
    if (score>4){
        maxforce= score/4;
    }else{
        maxforce=2;
    }
    
    int myForce = rand() % maxforce;
    short int direction = -1 * CC_RADIANS_TO_DEGREES(degree);
    b2Vec2 force = b2Vec2(direction, myForce);
    body->ApplyAngularImpulse(3);
    body->ApplyLinearImpulse(force, body->GetWorldCenter());
}

-  ( void ) createFly {
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"fly.plist"];
    
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:@"fly.png"];
    
    NSMutableArray *flyBirdFrames = [NSMutableArray array];
    
    for (int i = 1; i<=3; ++i) {
        
        [flyBirdFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"fly_move_%d.png", i]]];
        
    }
    
    CCAnimation *flybird = [CCAnimation animationWithFrames:flyBirdFrames delay:0.1f];
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    CCSprite *bird = [CCSprite spriteWithSpriteFrameName:@"fly_move_1.png"];
    
    bird.position = ccp(0, winSize.height/2);
    
    CCAction *flyAction = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:flybird restoreOriginalFrame:NO]];
    
    CCAction *moveAction = [CCMoveTo actionWithDuration:8.0 position:ccp(winSize.width-20, winSize.height/3)];
    
    CCAction *moveActionBack = [CCMoveTo actionWithDuration:4.0 position:ccp(0, winSize.height -20)];
    
    [bird runAction:flyAction];
    
    [bird runAction: [CCRepeatForever actionWithAction:[CCSequence actions:moveAction,moveActionBack,nil]]];
    
    [spriteSheet addChild:bird];
    
    [self addChild:spriteSheet];
    
}

-(void) update: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
}

- (void)tick:(ccTime) dt {
    
    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    for(pos = _contactListener->_contacts.begin(); pos != _contactListener->_contacts.end(); ++pos) {
        
        MyContact contact = *pos;
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        
        b2Vec2 posA=bodyA->GetPosition();
        b2Vec2 posB=bodyB->GetPosition();
        
        if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL && bodyA->GetUserData() != (void*)-1 && bodyB->GetUserData() != (void*)-1 ) {
            
            CCSprite *spriteA = (CCSprite *) bodyA->GetUserData();
            CCSprite *spriteB = (CCSprite *) bodyB->GetUserData();
            
            if (spriteA.tag==1 && spriteB.tag==2) {
                int pos =posB.y - posA.y;
                
                if(pos >= 2){
                    //Explosion
                    [self createExplosionX:posB];
                    spriteB.tag=100;
                    bodyB->SetUserData(spriteB);
                    toDestroy.push_back(bodyB);
                }
            }
        }else{
            for (b2Fixture* f = bodyA->GetFixtureList(); f; f = f->GetNext())
            {
                int pos =posB.y - posA.y;
                fixtureUserData *fixData=(fixtureUserData*)f->GetUserData();
                if((fixData->tag==-1) && (pos<=1)){
                    CCSprite *spriteB = (CCSprite *) bodyB->GetUserData();
                    if(spriteB.tag!=1)
                        toDestroy.push_back(bodyB);
                }
            }
        }
    }
    
    std::vector<b2Body *>::iterator pos2;
    for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
        b2Body *body = *pos2;
        if(body!=NULL){
            if (body->GetUserData() != NULL) {
                CCSprite *sprite = (CCSprite *) body->GetUserData();
                if(sprite.tag==100)
                    [self addPoint];
                else
                    [self loseLife];
                [self removeChild:sprite cleanup:YES];
                sprite=NULL;
            }
        }
        world->DestroyBody(body);
        *pos2=NULL;
        break;
    }
    
    world->Step(dt, 10, 10);
    for(b2Body *b = world->GetBodyList(); b; b=b->GetNext()) {
        if (b->GetUserData() !=(void*)-1) {
            CCSprite *spData = (CCSprite *)b->GetUserData();
            spData.position = ccp(b->GetPosition().x * PTM_RATIO,
                                  b->GetPosition().y * PTM_RATIO);
            if(spData.tag==2){
                spData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
            }
        }
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGSize winSize = [CCDirector sharedDirector].winSize;
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		location = [[CCDirector sharedDirector] convertToGL: location];
        if (location.x <= winSize.width-40 && location.x >= 30) {
            _body->SetTransform(b2Vec2((location.x-50)/PTM_RATIO,0), 0);
        }

	}
}

-(void) createExplosionX:(b2Vec2) point
{
    emitter_ = [CCParticleFire node];
	[self addChild:emitter_ z:10];
    
    emitter_.position = ccp(point.x * PTM_RATIO,point.y*PTM_RATIO);
    
	emitter_.texture = [[CCTextureCache sharedTextureCache] addImage:@"fire.pvr"];
    
    //set size of particle animation
    emitter_.scale = 1.0;
    
    //set length of particle animation
    [emitter_ setLife:0.7f];
    
    [emitter_ setDuration:0.1f];
    
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
