//
//  InstructionsLayer.mm
//  revolveball
//
//  Created by Nathan Demick on 10/6/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "InstructionsLayer.h"

@implementation InstructionsLayer
+ (id)scene
{
	// Create a generic scene object to attach the layer to
	CCScene *scene = [CCScene node];
	
	// Instantiate the layer
	InstructionsLayer *layer = [InstructionsLayer node];
	
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
		
		// Create "instructions" sprite
		CCSprite *instructions = [CCSprite spriteWithFile:[NSString stringWithFormat:@"instructions%@.png", hdSuffix]];
		instructions.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:instructions z:1];
		
		// Create "continue" button
		CCMenuItem *continueButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"continue-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"continue-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setBool:NO forKey:@"showInstructions"];
			[defaults synchronize];
			
			CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[GameLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenu *titleMenu = [CCMenu menuWithItems:continueButton, nil];
		titleMenu.position = ccp(windowSize.width / 2, continueButton.contentSize.height * 1.5);
		[self addChild:titleMenu z:1];	
	}
	return self;
}
@end
