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
	// Shows data about each level
	CCLabelBMFont *levelTitle, *levelTimeLimit, *levelBestTime;
	
	// Array of TMX map objects
	NSMutableArray *maps;
	
	CCMenuItemImage *prevButton, *nextButton;
	
	// Indicator to show level completion status
	CCSprite *checkmark;
	
	// Number of total levels in the "world"
	int levelsPerWorld;
	
	// String to be appended to sprite filenames if required to use a high-rez file (e.g. iPhone 4 assests on iPad)
	NSString *hdSuffix;
	int fontMultiplier;
	
	// Store device window size here, so you don't have to ask the director in every method
	CGSize windowSize;
}

+ (id)scene;

- (void)displayLevelInfo;

@end

