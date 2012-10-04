//
//  HelloWorldLayer.h
//  Ejemplo01
//
//  Created by Brian Krochik on 01/10/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "MyContactListener.h"
#import "GameOverLayer.h"
#import "GLES-Render.h"
#include <stdlib.h>
#import <Foundation/Foundation.h>

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32.0f

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
	CCTexture2D *spriteTexture_;	// weak ref
	b2World* world;					// strong ref
	GLESDebugDraw *m_debugDraw;		// strong ref
    MyContactListener *_contactListener;
    b2Body *_body;
    CCSprite *_pan;
    int score;
    int life;
    CCLabelTTF *scoreLabel;
    CCLabelTTF *lifeLabel;
    CCParticleSystem	*emitter_;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
