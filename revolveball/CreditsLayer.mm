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
		
		// < Back
		// Thanks for playing!
		// You are a Revolve Ball Master!
		// Try to get even faster times on your favorite levels.
		// Created by Nathan Demick
		// (more games)
		
		
		// Add background to layer
		CCSprite *background = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background-0%@.png", hdSuffix]];
		[background setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[background.texture setAliasTexParameters];
		[self addChild:background z:0];
		
		// Add "back" button
		CCMenuItemImage *backButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"back-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"back-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[TitleLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		CCMenu *backButtonMenu = [CCMenu menuWithItems:backButton, nil];
		[backButtonMenu setPosition:ccp(backButton.contentSize.width / 1.5, windowSize.height - backButton.contentSize.height)];
		[self addChild:backButtonMenu];
		
		// Add "more games" button
		CCMenuItemImage *moreGamesButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"more-games-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"more-games-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Go to iTunes
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.com/apps/ganbarugames"]];
		}];
		CCMenu *moreGamesButtonMenu = [CCMenu menuWithItems:moreGamesButton, nil];
		moreGamesButtonMenu.position = ccp(windowSize.width / 2, windowSize.height / 10);
		[self addChild:moreGamesButtonMenu];
		
		CCLabelBMFont *lineOne = [CCLabelBMFont labelWithString:@"Thanks" fntFile:[NSString stringWithFormat:@"yoster-32%@.fnt", hdSuffix]];
		CCLabelBMFont *lineTwo = [CCLabelBMFont labelWithString:@"for playing!" fntFile:[NSString stringWithFormat:@"yoster-32%@.fnt", hdSuffix]];
		CCLabelBMFont *lineThree = [CCLabelBMFont labelWithString:@"You are a Revolve Ball master!" fntFile:[NSString stringWithFormat:@"yoster-16%@.fnt", hdSuffix]];
		CCLabelBMFont *lineFour = [CCLabelBMFont labelWithString:@"Try to get even faster times" fntFile:[NSString stringWithFormat:@"yoster-16%@.fnt", hdSuffix]];
		CCLabelBMFont *lineFive = [CCLabelBMFont labelWithString:@"on your favorite levels." fntFile:[NSString stringWithFormat:@"yoster-16%@.fnt", hdSuffix]];
		CCLabelBMFont *lineSix = [CCLabelBMFont labelWithString:@"Game created by" fntFile:[NSString stringWithFormat:@"yoster-16%@.fnt", hdSuffix]];
		CCLabelBMFont *lineSeven = [CCLabelBMFont labelWithString:@"Nathan Demick" fntFile:[NSString stringWithFormat:@"yoster-16%@.fnt", hdSuffix]];
		
		[lineOne setPosition:ccp(windowSize.width / 2, windowSize.height / 1.3)];
		[lineTwo setPosition:ccp(windowSize.width / 2, lineOne.position.y - lineTwo.contentSize.height)];
		
		[lineThree setPosition:ccp(windowSize.width / 2, lineTwo.position.y - lineTwo.contentSize.height * 2)];
		[lineFour setPosition:ccp(windowSize.width / 2, lineThree.position.y - lineThree.contentSize.height)];
		[lineFive setPosition:ccp(windowSize.width / 2, lineFour.position.y - lineFour.contentSize.height)];
		
		[lineSix setPosition:ccp(windowSize.width / 2, lineFive.position.y - lineFive.contentSize.height * 2)];
		[lineSeven setPosition:ccp(windowSize.width / 2, lineSix.position.y - lineSix.contentSize.height)];
		
		
		[self addChild:lineOne];
		[self addChild:lineTwo];
		[self addChild:lineThree];
		[self addChild:lineFour];
		[self addChild:lineFive];
		[self addChild:lineSix];
		[self addChild:lineSeven];
		
		// Play sound effect =]
		[[SimpleAudioEngine sharedEngine] playEffect:@"level-complete.caf"];
	}
	return self;
}

@end