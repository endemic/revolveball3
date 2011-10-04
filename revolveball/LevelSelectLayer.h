//
//  LevelSelectScene.h
//  Revolve Ball
//
//  Created by Nathan Demick on 12/2/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "cocos2d.h"
#import "GameConfig.h"
#import "GameLayer.h"
#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

@interface LevelSelectLayer : CCLayer 
{
	// A collection of icons that represent levels
	NSMutableArray *levelIcons;
	
	// Shows data about each level
	CCLabelBMFont *levelTitle, *levelTimeLimit, *levelBestTime;
	
	// Rotating ball icon which represents current level selection
	CCSprite *ball;
	
	// Testing out showing a rotating map of the level
	CCTMXTiledMap *map;
	
	// String to be appended to sprite filenames if required to use a high-rez file (e.g. iPhone 4 assests on iPad)
	NSString *hdSuffix;
	int fontMultiplier;
	
	// Store device window size here, so you don't have to ask the director in every method
	CGSize windowSize;
}

+ (id)scene;

- (void)moveLevelSelectCursor:(int)destination;
- (void)drawBridges;
- (void)displayLevelInfo;

@end

