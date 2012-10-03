//
//  GameOverLayer.mm
//  Ejemplo01
//
//  Created by Brian Krochik on 02/10/12.
//
//

// Import the interfaces
#import "GameOverLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

@implementation GameOverLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameOverLayer *layer = [GameOverLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
    if( (self=[super init])) {
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
		// enable events
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;

        //Create and add the score label as a child.
        statusLabel = [CCLabelTTF labelWithString:@"Game Over" fontName:@"Marker Felt" fontSize:40];
        statusLabel.position = ccp(150, (winSize.height-150));
        statusLabel.color = ccc3(255,0,0);
        [self addChild:statusLabel z:1];
        
        // Create a button (aka "menu item"), have it execute the "buttonOneAction" method when tapped
        CCMenuItemFont *scoreBtn = [CCMenuItemFont itemFromString:@"Puntajes" target:self selector:@selector(scoreAction:)];
        CCMenuItemFont *resetBtn = [CCMenuItemFont itemFromString:@"Restart" target:self selector:@selector(resetAction:)];
        
        // Specify font details
        [CCMenuItemFont setFontSize:32];
        [CCMenuItemFont setFontName:@"Helvetica"];

        
        // Pretend that buttonOne and buttonTwo are already created
        CCMenu *myMenu = [CCMenu menuWithItems:scoreBtn,resetBtn, nil];
        [myMenu setPosition:ccp(150, (winSize.height-250))];
        [self addChild:myMenu z:1];
        
        [myMenu alignItemsVertically];
        [myMenu alignItemsVerticallyWithPadding:10];	// 10px of padding around each button
    } 
    
	return self;
}
- (void)scoreAction:(id)sender
{
	// Get a reference to the button that was tapped
	CCMenuItemFont *button = (CCMenuItemFont *)sender;
	
	// Have the button spin around!
	[button runAction:[CCRotateBy actionWithDuration:1 angle:360]];
}
- (void)resetAction:(id)sender
{
	// Get a reference to the button that was tapped
	CCMenuItemFont *button = (CCMenuItemFont *)sender;
	
	// Have the button spin around!
	[button runAction:[CCRotateBy actionWithDuration:1 angle:360]];
    
    [[CCDirector sharedDirector] replaceScene:
     [CCTransitionFlipY transitionWithDuration:1.8f scene:[HelloWorldLayer scene]]];
}
-(void) dealloc
{
	delete world;
	world = NULL;
    
	delete m_debugDraw;
	m_debugDraw = NULL;
	
    [restartLabel release];
    restartLabel = nil;
    
	[super dealloc];
}

@end
