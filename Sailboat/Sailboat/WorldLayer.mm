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
        width=s.width;
        height=s.height;
        
        //init vars
        pauseWave=true;
        gameOver=false;
        
        // Create contact listener
        _contactListener = new MyContactListener();
        
        //Create and add the life label as a child.
        score=0;
        scoreLabel = [CCLabelTTF labelWithString:@"Distancia: 0m" fontName:@"Marker Felt" fontSize:24];
        //Create and add the score label as a child.
        if(CC_CONTENT_SCALE_FACTOR()==1.0f){
            scoreLabel.position = ccp(s.width-(100*CC_CONTENT_SCALE_FACTOR()), (s.height-(20*CC_CONTENT_SCALE_FACTOR())));
        }else{
            scoreLabel.position = ccp(s.width-(48*CC_CONTENT_SCALE_FACTOR()), (s.height-(12*CC_CONTENT_SCALE_FACTOR())));
        }
        
        [self addChild:scoreLabel z:1];
        
		// init physics
		[self initPhysics];
        
        // Load the texture
        [self genBackground];
        
        _wave=[Terrain nodeWithTerrainType:1:world];
        //Generate Terrain
        [self addChild:_wave z:1];
        
         world->SetContactListener(_contactListener);
        _boat=[Boat nodeWithBoatType:1:world:_contactListener];
        
        //Generate Boat
        [self addChild:_boat z:1];
        
		[self scheduleUpdate];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
    _wave =NULL;
    _boat =NULL;
    
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

//Create an explosion
-(void) createExplosionX:(b2Vec2) point
{
    emitter_ = [CCParticleFire node];
	[self addChild:emitter_ z:10];
    
    emitter_.position = ccp(point.x ,point.y );
    
	emitter_.texture = [[CCTextureCache sharedTextureCache] addImage:@"fire.pvr"];
    
    //set size of particle animation
    emitter_.scale = 1.5;
    
    //set length of particle animation
    [emitter_ setLife:0.7f];
    
    [emitter_ setDuration:0.1f];
    
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    pauseWave=false;
    [_wave setPause:false];
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
            
            //if i get the boat i will check the status
            if(spData.tag==BOAT)
                [self checkStatus:b:offset];
        }
    }
    
    if(!pauseWave){
        
        /****** //TODO MOVE TO ANOTHER CLASS ******/
        float intensity=0.5;
        float hard=1;
        //Score hard
        if(score>40){
            hard=score/40;
            if(hard>2)
                hard=2;
        }
        
        //Moving Waves
        float PIXELS_PER_SECOND = (100*CC_CONTENT_SCALE_FACTOR())*(1+intensity*hard);
        offset += PIXELS_PER_SECOND * (dt/CC_CONTENT_SCALE_FACTOR());
        [_wave setOffsetX:offset];
        self.position = CGPointMake(-offset, 0);
        
        //Moving Background
        _background.position=ccp(offset+(width/2),height/1.5);

        //Moving score label
        if(CC_CONTENT_SCALE_FACTOR()==1.0f){
            scoreLabel.position = ccp(offset+width-(100*CC_CONTENT_SCALE_FACTOR()), (height-(20*CC_CONTENT_SCALE_FACTOR())));
        }else{
            scoreLabel.position = ccp(offset+width-(48*CC_CONTENT_SCALE_FACTOR()), (height-(12*CC_CONTENT_SCALE_FACTOR())));
        }
        
        //Updating Score
        score = offset/(50*CC_CONTENT_SCALE_FACTOR()); //I think: score++; will also work.
        [scoreLabel setString:[NSString stringWithFormat:@"Distancia: %dm", score]];
    }
}

//Check body status
- (void)checkStatus:(b2Body*) b:(int)off {
    float bodyAngle=CC_RADIANS_TO_DEGREES(b->GetAngle());
    if((abs(bodyAngle)>MAXANGLE && _contactListener->_contacts.size()>1) || (b->GetPosition().x*PTM_RATIO)<(off-90*CC_CONTENT_SCALE_FACTOR())){
        if(!gameOver){
            [self createExplosionX:b2Vec2(b->GetPosition().x*PTM_RATIO,b->GetPosition().y*PTM_RATIO)];
            [[CCDirector sharedDirector] replaceScene:
                [CCTransitionFlipX transitionWithDuration:2.0f scene:[GameOverLayer scene]]];
        }
        gameOver=true;
    }
}

- (void)genBackground {
    CGSize winSize = [CCDirector sharedDirector].winSize;

    [_background removeFromParentAndCleanup:YES];
    _background = [CCSprite spriteWithFile:@"background.jpeg"];
    _background.position = ccp(winSize.width/2, winSize.height/1.5);
    //ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
    //[_background.texture setTexParameters:&tp];
    
    [self addChild:_background];
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
