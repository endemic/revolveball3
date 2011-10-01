//
//  LogoLayer.m
//  RevolveBall
//
//  Created by Nathan Demick on 4/19/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "LogoLayer.h"

@implementation LogoLayer

+ (id)scene
{
	// Create a generic scene object to attach the layer to
	CCScene *scene = [CCScene node];
	
	// Instantiate the layer
	LogoLayer *layer = [LogoLayer node];
	
	// Add to generic scene
	[scene addChild:layer];
	
	// Return scene
	return scene;
}

- (id)init
{
	if ((self = [super init]))
	{
		// Get window size
		windowSize = [CCDirector sharedDirector].winSize;
		
		// This string gets appended onto all image filenames based on whether the game is on iPad or not
		if ([GameSingleton sharedGameSingleton].isPad)
		{
			hdSuffix = @"-hd";
			fontMultiplier = 2;
		}
		else
		{
			hdSuffix = @"";
			fontMultiplier = 1;
		}
		
		CCSprite *logo = [CCSprite spriteWithFile:[NSString stringWithFormat:@"Default%@.png", hdSuffix]];
		[logo setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[self addChild:logo];
		
		// schedule the transition method
		[self scheduleUpdate];
	}
	return self;
}

- (void)update:(ccTime)dt
{
	// Unschedule this method since it's only supposed to run once
	[self unscheduleUpdate];
	
	CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[TitleLayer scene]];
	[[CCDirector sharedDirector] replaceScene:transition];
}

- (void)dealloc
{
	[super dealloc];
}

@end
