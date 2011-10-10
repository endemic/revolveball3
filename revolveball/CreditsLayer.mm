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
		CCMenuItemImage *backButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"back-title-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"back-title-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play sound effect
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Transition to title screen
			CCTransitionFlipX *transition = [CCTransitionFlipX transitionWithDuration:0.5 scene:[TitleLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenu *topMenu = [CCMenu menuWithItems:backButton, nil];
		topMenu.position = ccp(backButton.contentSize.width / 1.5, windowSize.height - backButton.contentSize.height);
		[self addChild:topMenu z:1];
		
		// Create/add title
		CCSprite *title = [CCSprite spriteWithFile:[NSString stringWithFormat:@"thanks%@.png", hdSuffix]];
		title.position = ccp(windowSize.width / 2, windowSize.height - title.contentSize.height * 1.5);
		[self addChild:title z:1];
		
		// Thanks for playing!
		// You are a Revolve Ball 
		// expert! Try to get even 
		// faster times on your 
		// favorite levels.
		CCLabelBMFont *label = [CCLabelBMFont labelWithString:@"Thanks for playing!\nYou are a Revolve Ball\nexpert! Try to get even\nfaster times on your\nfavorite levels." fntFile:[NSString stringWithFormat:@"megalopolis-16%@.fnt", hdSuffix]];
		label.position = ccp(windowSize.width / 2, title.position.y - title.contentSize.height * 2);
		[self addChild:label z:1];
		
		// Play sound effect =]
		[[SimpleAudioEngine sharedEngine] playEffect:@"level-complete.caf"];
	}
	return self;
}

@end