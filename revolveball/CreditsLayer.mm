//
//  CreditsScene.m
//  RevolveBall
//
//  Created by Nathan Demick on 3/31/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "CreditsLayer.h"

@implementation CreditsLayer

+ (id)scene
{
	// Create a generic scene object to attach the layer to
	CCScene *scene = [CCScene node];
	
	// Instantiate the layer
	CreditsLayer *layer = [CreditsLayer node];
	
	// Add to generic scene
	[scene addChild:layer];
	
	// Return scene
	return scene;
}

- (id)init
{
	if ((self = [super init]))
	{
		// ask director the the window size
		CGSize windowSize = [CCDirector sharedDirector].winSize;
		
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
				
		// Add background to layer
		CCSprite *background = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background-0%@.png", hdSuffix]];
		[background setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[background.texture setAliasTexParameters];
		[self addChild:background z:0];
		
		// Create back button/menu
		CCMenuItemImage *continueButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"continue-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"continue-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play sound effect
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Transition to title screen
			CCTransitionFlipX *transition = [CCTransitionFlipX transitionWithDuration:0.5 scene:[TitleLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenu *menu = [CCMenu menuWithItems:continueButton, nil];
		menu.position = ccp(windowSize.width / 2, continueButton.contentSize.height * 2);
		[menu alignItemsVerticallyWithPadding:11];
		[self addChild:menu z:1];
		
		CCSprite *creditsText = [CCSprite spriteWithFile:[NSString stringWithFormat:@"credits%@.png", hdSuffix]];
		creditsText.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:creditsText z:1];
		
		// Play sound effect
		[[SimpleAudioEngine sharedEngine] playEffect:@"level-complete.caf"];
	}
	return self;
}

@end