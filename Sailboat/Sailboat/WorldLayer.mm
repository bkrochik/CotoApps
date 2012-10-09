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
        
        // Load the texture
        //[self genBackground];
        
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
    self.position = CGPointMake(-offset, 0);
    
    //[_wave2 setOffsetX:offsetWave2];
}

-(CCSprite *)spriteWithColor:(ccColor4F)bgColor textureSize:(float)textureSize {
    
    // 1: Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    
    // 2: Call CCRenderTexture:begin
    [rt beginWithClear:bgColor.r g:bgColor.g b:bgColor.b a:bgColor.a];
    
    // 3: Draw into the texture
    // We'll add this later
    
    float gradientAlpha = 0.7;
    CGPoint vertices[4];
    ccColor4F colors[4];
    int nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0 };
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(0, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Color );
    
    // vertex
	glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, sizeof(CGPoint),vertices);
	// texCoods
	glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, sizeof(CGPoint),colors);
    
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);

    
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    noise.position = ccp(textureSize/2, textureSize/2);
    [noise visit];
    
    // 4: Call CCRenderTexture:end
    [rt end];
    
    // 5: Create a new Sprite from the texture
    return [CCSprite spriteWithTexture:rt.sprite.texture];
    
}
-(CCSprite *)stripedSpriteWithColor1:(ccColor4F)c1 color2:(ccColor4F)c2 textureSize:(float)textureSize  stripes:(int)nStripes {

    // 1: Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    
    // 2: Call CCRenderTexture:begin
    [rt beginWithClear:c1.r g:c1.g b:c1.b a:c1.a];
    
    // 3: Draw into the texture
    
    // Layer 1: Stripes
    CGPoint vertices[nStripes*6];
    int nVertices = 0;
    float x1 = -textureSize;
    float x2;
    float y1 = textureSize;
    float y2 = 0;
    float dx = textureSize / nStripes * 2;
    float stripeWidth = dx/2;
    for (int i=0; i<nStripes; i++) {
        x2 = x1 + textureSize;
        vertices[nVertices++] = CGPointMake(x1, y1);
        vertices[nVertices++] = CGPointMake(x1+stripeWidth, y1);
        vertices[nVertices++] = CGPointMake(x2, y2);
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = CGPointMake(x2+stripeWidth, y2);
        x1 += dx;
    }
    
    ccDrawColor4F(c2.r, c2.g, c2.b, c2.a);
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0,vertices);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);
    
    // layer 2: gradient
    
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Color );
    
    float gradientAlpha = 0.7;
    ccColor4F colors[4];
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0 };
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(0, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0,vertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0,colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    // layer 3: top highlight
    float borderWidth = textureSize/16;
    float borderAlpha = 0.3f;
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
    
    vertices[nVertices] = CGPointMake(0, borderWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(textureSize, borderWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0,vertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0,colors);
    
    glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Color );
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_TexCoords );
    
    // Layer 2: Noise
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    noise.position = ccp(textureSize/2, textureSize/2);
    [noise visit];
    
    // 4: Call CCRenderTexture:end
    [rt end];
    
    // 5: Create a new Sprite from the texture
    return [CCSprite spriteWithTexture:rt.sprite.texture];
    
}

- (ccColor4F)randomBrightColor {
    
    while (true) {
        float requiredBrightness = 192;
        ccColor4B randomColor =
        ccc4(arc4random() % 255,
             arc4random() % 255,
             arc4random() % 255,
             255);
        if (randomColor.r > requiredBrightness ||
            randomColor.g > requiredBrightness ||
            randomColor.b > requiredBrightness) {
            return ccc4FFromccc4B(randomColor);
        }
    }
    
}

- (void)genBackground {
    [_background removeFromParentAndCleanup:YES];
    
    ccColor4F bgColor = [self randomBrightColor];
    _background = [self spriteWithColor:bgColor textureSize:512];
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    _background.position = ccp(winSize.width/2, winSize.height/2);
    ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
    [_background.texture setTexParameters:&tp];
    
    [self addChild:_background];
    
    ccColor4F color3 = [self randomBrightColor];
    ccColor4F color4 = [self randomBrightColor];
    CCSprite *stripes = [self stripedSpriteWithColor1:color3 color2:color4 textureSize:512 stripes:4];
    ccTexParams tp2 = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
    [stripes.texture setTexParameters:&tp2];
    _wave.stripes = stripes;
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
