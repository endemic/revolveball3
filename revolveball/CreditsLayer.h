//
//  CreditsScene.h
//  RevolveBall
//
//  Created by Nathan Demick on 3/31/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "TitleLayer.h"

#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

@interface CreditsLayer : CCLayer 
{
	// String to be appended to sprite filenames if required to use a high-rez file (e.g. iPhone 4 assests on iPad)
	NSString *hdSuffix;
	int fontMultiplier;
}

+ (id)scene;

@end

