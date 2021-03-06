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
		
		// Create logo
		CCSprite *logo = [CCSprite spriteWithFile:[NSString stringWithFormat:@"logo%@.png", hdSuffix]];
		[logo setPosition:ccp(windowSize.width / 2, windowSize.height - logo.contentSize.height / 1.5)];
		[self addChild:logo z:1];
		
		// Create "lite" logo addition
#if kLiteVersion
		CCSprite *lite = [CCSprite spriteWithFile:[NSString stringWithFormat:@"lite-label%@.png", hdSuffix]];
		[lite setPosition:ccp(windowSize.width / 2 - lite.contentSize.width * 1.2, logo.position.y - lite.contentSize.height * 2.3)];
		[self addChild:lite z:1];
#endif
		
		// Create the "ball" that will drop in on the logo
		CCSprite *ball = [CCSprite spriteWithFile:[NSString stringWithFormat:@"logo-ball%@.png", hdSuffix]];
		ball.position = ccp(logo.position.x + 90 * fontMultiplier, windowSize.height + ball.contentSize.height);
		[self addChild:ball z:1];
		
		// Hide initially, so the sprite doesn't appear during the scene transition
		ball.opacity = 0;
		
		// Wait until the rotation transition has happened, then fade in quickly and drop into place
		// When the drop animation is finished, rotate the ball indefinitely
		id wait = [CCDelayTime actionWithDuration:1.0];
		id show = [CCFadeIn actionWithDuration:0.1];
		id move = [CCMoveTo actionWithDuration:1.0 position:ccp(logo.position.x + 90 * fontMultiplier, logo.position.y - 35 * fontMultiplier)];
		id ease = [CCEaseBounceOut actionWithAction:move];
		id callback = [CCCallBlockN actionWithBlock:^(CCNode *node) {
			id spin = [CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:2.0 angle:360.0]];
			[(CCSprite *)node runAction:spin];
			
#if kLiteVersion
			[GameSingleton sharedGameSingleton].hasGameCenter = NO;
#else
			// Authenticate with Game Center
			[[GameSingleton sharedGameSingleton] authenticateLocalPlayer];
#endif
		}];
		
		[ball runAction:[CCSequence actions:wait, show, ease, callback, nil]];
		
		// Add button which takes us to game scene
		CCMenuItem *startButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"start-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"start-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Load "hub" level
			[GameSingleton sharedGameSingleton].currentWorld = 0;
			[GameSingleton sharedGameSingleton].currentLevel = 0;
			
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			if ([defaults boolForKey:@"showInstructions"] == YES)
			{
				// Show instructions if they haven't been shown before
				CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[InstructionsLayer scene]];
				[[CCDirector sharedDirector] replaceScene:transition];
			}
			else
			{
				// Otherwise, go to the hub level
				CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[GameLayer scene]];
				[[CCDirector sharedDirector] replaceScene:transition];	
			}
		}];
		
#if kLiteVersion
		// Add "upgrade" button to the menu
		CCMenuItemImage *upgradeButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"upgrade-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"upgrade-button-selected%@.png", hdSuffix] block:^(id sender){
			// Play sound effect
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Create "go to App Store?" alert
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Go to App Store?"
																 message:@"The full version has 35 more levels to complete, along with Game Center leaderboards!"
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"Go", nil] autorelease];
			[alertView show];
		}];
		
		CCMenu *titleMenu = [CCMenu menuWithItems:startButton, upgradeButton, nil];
		titleMenu.position = ccp(windowSize.width / 2, startButton.contentSize.height * 3);
		[titleMenu alignItemsVerticallyWithPadding:11];
		[self addChild:titleMenu z:1];
#else
		CCMenu *titleMenu = [CCMenu menuWithItems:startButton, nil];
		titleMenu.position = ccp(windowSize.width / 2, startButton.contentSize.height * 2);
		[titleMenu alignItemsVerticallyWithPadding:11];
		[self addChild:titleMenu z:1];	
#endif
		
		// Add "info" button
		CCMenuItemImage *infoButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"info-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"info-button%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Transition to info scene
			CCTransitionFlipX *transition = [CCTransitionFlipX transitionWithDuration:0.5 scene:[InfoLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenu *infoMenu = [CCMenu menuWithItems:infoButton, nil];
		infoMenu.position = ccp(windowSize.width - infoButton.contentSize.width / 1.5, infoButton.contentSize.height / 1.5);
		[self addChild:infoMenu z:1];
		
		// Add copyright text
		CCLabelBMFont *copyright = [CCLabelBMFont labelWithString:@"©2011 Ganbaru Games" fntFile:[NSString stringWithFormat:@"megalopolis-16%@.fnt", hdSuffix]];
		copyright.position = ccp(windowSize.width / 2, copyright.contentSize.height);
		[self addChild:copyright z:1];
				
		// Play random music track
		if ([[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying] == NO)
		{
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"1.mp3"];
		}
	}
	return self;
}

/**
 * Handle clicking of the alert view
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) 
	{
		case 0:
			// Do nothing - dismiss
			break;
		case 1:
#if TARGET_IPHONE_SIMULATOR
			CCLOG(@"App Store is not supported on the iOS simulator. Unable to open App Store page.");
#else
			// they want to buy it
			//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=386461624"]];
			[self openReferralURL:[NSURL URLWithString:@"http://click.linksynergy.com/fs-bin/click?id=0VdnAOV054A&offerid=146261.409351780&type=2&subid=0"]];
#endif
			break;
		default:
			break;
	}
}

// Process a LinkShare/TradeDoubler/DGM URL to something iPhone can handle
- (void)openReferralURL:(NSURL *)referralURL 
{
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:referralURL] delegate:self startImmediately:YES];
    [conn release];
}

// Save the most recent URL in case multiple redirects occur
// "iTunesURL" is an NSURL property in your class declaration
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response 
{
    iTunesURL = [response URL];
    return request;
}

// No more redirects; use the last URL saved
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    [[UIApplication sharedApplication] openURL:iTunesURL];
}

// on "dealloc" you need to release all your retained objects
- (void)dealloc
{
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end