//
//  Boat.m
//  Sailboat
//
//  Created by Brian Krochik on 13/10/12.
//  Copyright 2012 Brian Krochik. All rights reserved.
//

#import "Boat.h"
// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"
// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "PhysicsSprite.h"
#import "GB2ShapeCache.h"

@implementation Boat

- (id)initWithBoatType:(int)terrainType:(b2World *)world:(MyContactListener*)myContactListener
{
	if( (self=[super init])) {
        _world=world;
        _contactListener=myContactListener;
		// enable events
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
		CGSize s = [CCDirector sharedDirector].winSize;
	}
    
    CCSprite *_boat;
    _boat = [CCSprite spriteWithFile:@"ship.png" rect:CGRectMake(0, 0, 100/CC_CONTENT_SCALE_FACTOR(), 37/CC_CONTENT_SCALE_FACTOR())];
    _boat.position = ccp(0, 0);
    _boat.tag=BOAT;
    _boat.scale=CC_CONTENT_SCALE_FACTOR();
    [self addChild:_boat  z:0];
    
    // Create ball body and shape new
    b2BodyDef boatBodyDef;
    boatBodyDef.type = b2_dynamicBody;
    boatBodyDef.position.Set((200)/PTM_RATIO,200/PTM_RATIO);
    boatBodyDef.userData = _boat;
    _body = _world->CreateBody(&boatBodyDef);
    //body->SetLinearVelocity(b2Vec2(3.0f, 0.0f));
    
    [[GB2ShapeCache sharedShapeCache]   addShapesWithFile:@"ship.plist"];
    [[GB2ShapeCache sharedShapeCache] addFixturesToBody:_body forShapeName:@"ship"];
    [_boat setAnchorPoint: [[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"ship"]];
    
    [self scheduleUpdate];
    
	return self;
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    touchStart=true;
   
}
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchStart=false;
}

+ (id)nodeWithBoatType:(int)terrainType:(b2World *)world:(MyContactListener*)myContactListener{
    return  [[[self alloc] initWithBoatType:terrainType:world:myContactListener] autorelease];
}

- (void)dealloc {
    _body =NULL;
    [super dealloc];
}

-(void) update:(ccTime)delta
{   
    if(touchStart && _contactListener->_contacts.size()>1){
        float angle=_body->GetAngle();
        float speedY=sin(angle);
        float speedX=cos(angle);
        if(speedY>1)
            speedY=1;
        if(speedX>1)
            speedX=1;
        
        float vel=(2.5*CC_CONTENT_SCALE_FACTOR());
        
        b2Vec2 currentVelocity = _body->GetLinearVelocity();
        b2Vec2 newVelocity = b2Vec2((currentVelocity.x +vel)*speedX,(currentVelocity.y +vel)*speedY);
        if(currentVelocity.x<=(40*CC_CONTENT_SCALE_FACTOR()))
            _body->SetLinearVelocity( newVelocity );
    }
}
@end
