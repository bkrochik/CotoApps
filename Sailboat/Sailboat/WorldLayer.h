//
//  HelloWorldLayer.h
//  Sailboat
//
//  Created by Brian Krochik on 04/10/12.
//  Copyright Brian Krochik 2012. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
//Terrain effects
#import "Terrain.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

// HelloWorldLayer
@interface WorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    Terrain * _wave;
    Terrain * _wave2;
	CCTexture2D *spriteTexture_;	// weak ref
	b2World* world;					// strong ref
	GLESDebugDraw *m_debugDraw;		// strong ref
    float offset;
}

// returns a CCScene that contains as the only child
+(CCScene *) scene;

@end
