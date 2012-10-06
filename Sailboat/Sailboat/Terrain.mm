#import "Terrain.h"
#import "WorldLayer.h"

@implementation Terrain
@synthesize stripes = _stripes;

- (void) generateWaves{
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    float minDX = 160;
    float minDY = 60;
    int rangeDX = 80;
    int rangeDY = 40;
    float paddingTop = 20;
    float paddingBottom = 20;
    
    switch (_waveType) {
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

- (void) resetWaveVertices {
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    static int prevFromKeyPointI = -1;
    static int prevToKeyPointI = -1;
    
    // key points interval for drawing
    while (_waveKeyPoints[_fromKeyPointI+1].x < _offsetX-winSize.width/8/self.scale) {
        _fromKeyPointI++;
    }
    while (_waveKeyPoints[_toKeyPointI].x < _offsetX+winSize.width*9/8/self.scale) {
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
    }
    
}

- (id)init{
    if ((self = [super init])) {
        [self generateWaves];
        //Reset waves
        [self resetWaveVertices];
        //Scale
        self.scale = 0.50;
    }
    return self;
}
- (id)initWithWaveType:(int)waveType
{
    _waveType=waveType;
    if ((self = [super init])) {
        [self generateWaves];
        //Reset waves
        [self resetWaveVertices];
        //Scale
        switch (waveType) {
            case 1:
                self.scale = 0.60;
                break;
            case 2:
                self.scale=0.25;
                break;
            default:
                break;
        }
        
    }
    return self;
}

+ (id)nodeWithWaveType:(int)waveType{
    return  [[[self alloc] initWithWaveType:waveType] autorelease];
}

- (void) draw {
    //Wave 1
    for(int i = MAX(_fromKeyPointI, 1); i <= _toKeyPointI; ++i) {
        ccDrawColor4F(1.0, 1.0, 1.0, 1.0);
        
        CGPoint p0 = _waveKeyPoints[i-1];
        CGPoint p1 = _waveKeyPoints[i];
        int hSegments = floorf((p1.x-p0.x)/kWaveSegmentWidth);
        float dx = (p1.x - p0.x) / hSegments;
        float da = M_PI / hSegments;
        float ymid = (p0.y + p1.y) / 2;
        float ampl = (p0.y - p1.y) / 2;
        CGPoint pt0, pt1;
        pt0 = p0;
        for (int j = 0; j < hSegments+1; ++j) {
            
            pt1.x = p0.x + j*dx;
            pt1.y = ymid + ampl * cosf(da*j);
            
            ccDrawLine(pt0, pt1);
            
            pt0 = pt1;
            
        }
    }
    //glBindTexture(GL_TEXTURE_2D, _stripes.texture.name);
    
   /* ccDrawColor4F(1, 1, 1, 1);
    
    glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, kQuadSize, _waveVertices);
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, kQuadSize, _waveTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)_nWaveVertices);*/
    

}

- (void) setOffsetX:(float)newOffsetX {
    _offsetX = newOffsetX;
    self.position = CGPointMake(-_offsetX*self.scale, 0);
    //reset waves
    [self resetWaveVertices];
}

- (void)dealloc {
    [_stripes release];
    _stripes = NULL;
    [super dealloc];
}
@end
