//
//  Terrain.h
//  Sailboat
//
//  Created by Brian Krochik on 04/10/12.
//  Copyright (c) 2012 Brian Krochik. All rights reserved.
//

#ifndef Sailboat_Terrain_h
#define Sailboat_Terrain_h

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

@class Terrain;

#define kMaxWaveKeyPoints 1000
#define kWaveSegmentWidth 5
#define kMaxWaveVertices 4000
#define kMaxBorderVertices 800
#define kQuadSize sizeof(quad_t)

@interface Terrain : CCNode {
    int _offsetX;
    int _fromKeyPointI;
    int _toKeyPointI;
    
    CGPoint _waveKeyPoints[kMaxWaveKeyPoints];
    CCSprite *_stripes;
    CCTexture2D *brushTexture;
    int _nWaveVertices;
    CGPoint _waveVertices[kMaxWaveVertices];
    CGPoint _waveTexCoords[kMaxWaveVertices];
    int _nBorderVertices;
    CGPoint _borderVertices[kMaxBorderVertices];
  
    int _terrainType;
	GLESDebugDraw *m_debugDraw;		// strong ref
    
    b2World *_world;
    b2Body *_body;
    GLESDebugDraw * _debugDraw;
}

@property (retain) CCSprite * stripes;
    - (void) setOffsetX:(float)newOffsetX;
@end

#endif
