//
//  TitleScene.m
//  Ballgame
//
//  Created by Nathan Demick on 10/14/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//
#import "TitleLayer.h"

@implementation TitleLayer

+ (id)scene
{
	// Create a generic scene object to attach the layer to
	CCScene *scene = [CCScene node];
	
	// Instantiate the layer
	TitleLayer *layer = [TitleLayer node];
	
	// Add to generic scene
	[scene addChild:layer];
	
	// Return scene
	return scene;
}

- (id)init
{
	if ((self = [super init]))
	{
		[self setIsTouchEnabled:YES];
		
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
		
		CCSprite *background = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background-1%@.png", hdSuffix]];
		background.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:background];
		
		
		CCSprite *logo = [CCSprite spriteWithFile:[NSString stringWithFormat:@"logo%@.png", hdSuffix]];
		[logo setPosition:ccp(windowSize.width / 2, windowSize.height - logo.contentSize.height / 1.5)];
		[self addChild:logo z:1];
		
		// Add button which takes us to game scene
		CCMenuItem *startButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"start-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"start-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Load "hub" level
			[GameSingleton sharedGameSingleton].currentWorld = 0;
			[GameSingleton sharedGameSingleton].currentLevel = 0;
			
			CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[GameLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		CCMenu *titleMenu = [CCMenu menuWithItems:startButton, nil];
		titleMenu.position = ccp(windowSize.width / 2, windowSize.height / 8);
		[self addChild:titleMenu z:1];
		
		// Add copyright text
		CCLabelBMFont *copyright = [CCLabelBMFont labelWithString:@"(c)2011 Ganbaru Games" fntFile:[NSString stringWithFormat:@"munro-small-20%@.fnt", hdSuffix]];
		copyright.position = ccp(windowSize.width / 2, copyright.contentSize.height);
		[self addChild:copyright z:1];
				
		[self preloadAudio];
		
		//[self performSelectorInBackground:@selector(preloadAudio) withObject:nil];
		
		// Try to authenticate local player; API check is built in
		[[GameSingleton sharedGameSingleton] authenticateLocalPlayer];
	}
	return self;
}

- (void)preloadAudio
{
	// Info about running this method in background: http://stackoverflow.com/questions/2441856/iphone-sdk-leaking-memory-with-performselectorinbackground
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Set audio mixer rate to lower level
	[CDSoundEngine setMixerSampleRate:CD_SAMPLE_RATE_MID];
	
	// Preload some SFX
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"button-press.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"spike-hit.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"wall-hit.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"wall-break.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"peg-hit.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"time-pickup.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"toggle.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"boost.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"level-complete.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"level-fail.caf"];
	
	// Preload music - eventually do this based on the "world" that is selected
	[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"level-select.mp3"];
	[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"gameplay.mp3"];
	
	// Set BGM volume
	//NSLog(@"Current background music volume: %f", [[SimpleAudioEngine sharedEngine] backgroundMusicVolume]);
	[[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:0.75];
	
	//[pool release];
}
@end