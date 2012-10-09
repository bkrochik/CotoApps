#import "Terrain.h"
#import "WorldLayer.h"

@implementation Terrain
@synthesize stripes = _stripes;

- (void) generateTerrain{
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    float minDX = 160;
    float minDY = 60;
    int rangeDX = 80;
    int rangeDY = 40;
    
    switch (_terrainType) {
        case 1:
            rangeDX = 80;
            rangeDY = 1;
            minDY = 80;
            minDX = 130;
            break;
        case 2:
            rangeDX = 30;
            rangeDY = 20;
            minDY = 100;
            minDX = 200;
            break;
        default:
            break;
    }
    
    float x = -minDX;
    float y = winSize.height/2-minDY;

    float dy, ny;
    float sign = 1; // +1 - going up, -1 - going  down
    float paddingTop = 20;
    float paddingBottom = 20;
    
    for (int i=0; i<kMaxWaveKeyPoints; i++) {
        _waveKeyPoints[i] = CGPointMake(x, y);
        if (i == 0) {
            x = 0;
            y = winSize.height/2;
        } else {
            x += rand()%rangeDX+minDX;
            while(true) {
                dy = rand()%rangeDY+minDY;
                ny = y + dy*sign;
                if(ny < winSize.height-paddingTop && ny > paddingBottom) {
                    break;
                }
            }
            y = ny;
        }
        sign *= -1;
    }
    
}

- (void) resetBox2DBody {
    if(_body) {
        _world->DestroyBody(_body);
    }
    
    b2BodyDef bd;
    bd.position.Set(0, 0);

    _body = _world->CreateBody(&bd);
 
    b2EdgeShape shape;
    
    b2Vec2 p1, p2;
    for (int i=0; i<_nBorderVertices-1; i++) {
        p1 = b2Vec2(_borderVertices[i].x/PTM_RATIO,_borderVertices[i].y/PTM_RATIO);
        p2 = b2Vec2(_borderVertices[i+1].x/PTM_RATIO,_borderVertices[i+1].y/PTM_RATIO);

        // Create fixtures for the four borders (the border shape is re-used)
        shape.Set(p1, p2);
        _body->CreateFixture(&shape, 0);
    }
}
-(void)setupDebugDraw{
    m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	_world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);
	
}

- (void) resetTerrainVertices {
    
    CGSize winSize = [CCDirector sharedDirector].winSizeInPixels;
    
    static int prevFromKeyPointI = -1;
    static int prevToKeyPointI = -1;
    
    // key points interval for drawing
    while (_waveKeyPoints[_fromKeyPointI+1].x < _offsetX-winSize.width/4/self.scale) {
        _fromKeyPointI++;
    }
    while (_waveKeyPoints[_toKeyPointI].x < _offsetX+winSize.width*9/4/self.scale) {
        _toKeyPointI++;
    }
    if (prevFromKeyPointI != _fromKeyPointI || prevToKeyPointI != _toKeyPointI) {
        
        // vertices for visible area
        _nWaveVertices = 0;
        _nBorderVertices = 0;
        CGPoint p0, p1, pt0, pt1;
        p0 = _waveKeyPoints[_fromKeyPointI];
        for (int i=_fromKeyPointI+1; i<_toKeyPointI+1; i++) {
            p1 = _waveKeyPoints[i];
            
            // triangle strip between p0 and p1
            int hSegments = floorf((p1.x-p0.x)/kWaveSegmentWidth);
            float dx = (p1.x - p0.x) / hSegments;
            float da = M_PI / hSegments;
            float ymid = (p0.y + p1.y) / 2;
            float ampl = (p0.y - p1.y) / 2;
            pt0 = p0;
            _borderVertices[_nBorderVertices++] = pt0;
            for (int j=1; j<hSegments+1; j++) {
                pt1.x = p0.x + j*dx;
                pt1.y = ymid + ampl * cosf(da*j);
                _borderVertices[_nBorderVertices++] = pt1;
                
                _waveVertices[_nWaveVertices] = CGPointMake(pt0.x, 0);
                _waveTexCoords[_nWaveVertices++] = CGPointMake(pt0.x/512, 1.0f);
                _waveVertices[_nWaveVertices] = CGPointMake(pt1.x, 0);
                _waveTexCoords[_nWaveVertices++] = CGPointMake(pt1.x/512, 1.0f);
                
                _waveVertices[_nWaveVertices] = CGPointMake(pt0.x, pt0.y);
                _waveTexCoords[_nWaveVertices++] = CGPointMake(pt0.x/512, 0);
                _waveVertices[_nWaveVertices] = CGPointMake(pt1.x, pt1.y);
                _waveTexCoords[_nWaveVertices++] = CGPointMake(pt1.x/512, 0);
                
                pt0 = pt1;
            }
            
            p0 = p1;
        }
        
        prevFromKeyPointI = _fromKeyPointI;
        prevToKeyPointI = _toKeyPointI;
        
        switch (_terrainType) {
            case 1:
                [self resetBox2DBody];
                break;
            default:
                break;
        }
    }
    
}

- (id)initWithTerrainType:(int)terrainType:(b2World *)world
{
    _world = world;
    _terrainType=terrainType;
    
    if ((self = [super init])) {
        //Scale
        switch (terrainType) {
            case 1:
                self.scale = 1;
                break;
            case 2:
                self.scale=0.25;
                break;
            default:
                break;
        }
        
        [self setupDebugDraw];
        [self generateTerrain];
        
        //Reset waves
        [self resetTerrainVertices];
        
    }
    return self;
}

+ (id)nodeWithTerrainType:(int)terrainType:(b2World *)world{
    return  [[[self alloc] initWithTerrainType:terrainType:world] autorelease];
}

- (void) draw {
    [super draw];
    brushTexture = [[CCTextureCache sharedTextureCache] addImage:@"Default.png"];
    [brushTexture setAliasTexParameters];
    ccDrawTexturePoly(_waveVertices, _nWaveVertices, false,brushTexture.name);
 
    kmGLPushMatrix();

   // _world->DrawDebugData();

    kmGLPopMatrix();

}

- (void) setOffsetX:(float)newOffsetX {
    _offsetX = newOffsetX;
    //self.position = CGPointMake(-_offsetX*self.scale, 0);
    //reset waves
    [self resetTerrainVertices];
}

- (void)dealloc {
    [_stripes release];
    _stripes = NULL;
    [super dealloc];
    
    delete m_debugDraw;
	m_debugDraw = NULL;
}
@end
