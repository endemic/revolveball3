//
//  TitleScene.h
//  Ballgame
//
//  Created by Nathan Demick on 10/14/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "cocos2d.h"
#import "GameLayer.h"
#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

@interface TitleLayer : CCLayer 
{
	// String to be appended to sprite filenames if required to use a high-rez file (e.g. iPhone 4 assests on iPad)
	NSString *hdSuffix;
	int fontMultiplier;
	
	// Store device window size here, so you don't have to ask the director in every method
	CGSize windowSize;
}

+ (id)scene;
- (void)preloadAudio;

@end
