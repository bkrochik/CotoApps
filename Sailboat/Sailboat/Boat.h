//
//  Boat.h
//  Sailboat
//
//  Created by Brian Krochik on 13/10/12.
//  Copyright 2012 Brian Krochik. All rights reserved.
//

#import <GameKit/GameKit.h>

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "MyContactListener.h"

#define PTM_RATIO 32

@interface Boat  : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate> {
    b2World *_world;
    b2Body *_body;
    BOOL touchStart;
    MyContactListener *_contactListener;
}

@end
