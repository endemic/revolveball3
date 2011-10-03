//
//  GameScene.h
//  Ballgame
//
//  Created by Nathan Demick on 10/15/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "MyContactListener.h"

#import <vector>	// Easy data structure to store Box2D bodies
#import "math.h"

#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

#import "LevelSelectLayer.h"
#import "CreditsLayer.h"

@interface GameLayer : CCLayer 
{
	// Box2D
	b2World *world;
	MyContactListener *contactListener;
	
	// Player
	CCSprite *ball;
	
	// Map
	CCTMXTiledMap *map;
	CCTMXLayer *border;
	
	// Vectors of Box2D bodies that can be toggled off/on in a level
	std::vector<b2Body *> toggleBlockGroup;
	std::vector<b2Body *> toggleSwitchGroup;
	
	// Flag for whether or not the toggle block switch can be thrown
	BOOL toggleSwitchTimeout;
	
	// Vars for rotational touch controls
	float previousAngle, currentAngle, touchEndedAngle;
	
	// For time limit
	int secondsLeft;
	CCLabelBMFont *timerLabel;
	
	// For countdown at start of level
	int countdownTime;
	
	// Determines whether or not user input is taken
	BOOL levelComplete;
	
	// Boolean that determines if player is on the "world select" level
	BOOL isHubLevel;
	
	// Pretty self-explanatory
	BOOL paused;
	CCSprite *pauseOverlay;
	
	// If player tilts device, show icon pointing correct orientation
	CCSprite *upIcon;
	
	// "pixel-to-meter" ratio of Box2D objects; doubles on iPad/iPhone 4 Retina Display
	int ptmRatio;
	
	// String to be appended to sprite filenames if required to use a high-rez file (e.g. iPhone 4 assests on iPad)
	NSString *hdSuffix;
	int fontMultiplier;
	
	// Store device window size here, so you don't have to ask the director in every method
	CGSize windowSize;
}

+ (id)scene;
- (void)winGame;	// Win/loss actions
- (void)loseGame;
- (void)loseTime:(int)seconds;	// Method to subtract from countdown timer & display a label w/ lost time
- (void)gainTime:(int)seconds;
- (void)blockHubEntrances;	// Used in hub level; checks player progress and inserts barriers to prevent access to higher levels
- (void)createParticleEmitterAt:(CGPoint)position;
@end
