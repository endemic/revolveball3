//
//  LogoLayer.h
//  RevolveBall
//
//  Created by Nathan Demick on 4/19/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#import "GameSingleton.h"
#import "TitleLayer.h"

@interface LogoLayer : CCLayer 
{
	// String to be appended to sprite filenames if required to use a high-rez file (e.g. iPhone 4 assests on iPad)
	NSString *hdSuffix;
	int fontMultiplier;
	
	// Store device window size here, so you don't have to ask the director in every method
	CGSize windowSize;
}

+ (id)scene;
- (void)update:(ccTime)dt;

@end
