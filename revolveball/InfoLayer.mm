//
//  InfoScene.m
//  nonogrammadness
//
//  Created by Nathan Demick on 8/31/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "InfoLayer.h"
#import "TitleLayer.h"

#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

@implementation InfoLayer

+ (CCScene *)scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	InfoLayer *layer = [InfoLayer node];
	
	// add layer as a child to scene
	[scene addChild:layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
- (id)init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
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
		
		// Create/add background
		CCSprite *bg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background-0%@.png", hdSuffix]];
		bg.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:bg z:0];
		
		// Create/add title
		CCSprite *title = [CCSprite spriteWithFile:[NSString stringWithFormat:@"about%@.png", hdSuffix]];
		title.position = ccp(windowSize.width / 2, windowSize.height - title.contentSize.height * 1.5);
		[self addChild:title z:1];
		
		// Create "credits" label
		CCLabelBMFont *label = [CCLabelBMFont labelWithString:@"Designed and programmed\n         by Nathan Demick" fntFile:[NSString stringWithFormat:@"megalopolis-16%@.fnt", hdSuffix]];
		label.position = ccp(windowSize.width / 2, title.position.y - title.contentSize.height * 1.5);
		[self addChild:label z:1];
		
		// Add buttons to modal
		CCMenuItemImage *dataResetButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"reset-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"reset-button-selected%@.png", hdSuffix] block:^(id sender) {

			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Create "go to App Store?" alert
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Reset data?"
																 message:@"Your saved times will be lost!"
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"OK", nil] autorelease];
			[alertView setTag:0];
			[alertView show];
		}];
		
		// Create "rate on App Store" button
		CCMenuItemImage *rateButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"feedback-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"feedback-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Create "go to App Store?" alert
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Rate on App Store?"
																 message:@"I appreciate your feedback. Thanks for playing Revolve Ball!"
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"Rate", nil] autorelease];
			[alertView setTag:1];
			[alertView show];
		}];
		
		// Create "more games" button
		CCMenuItemImage *moreGamesButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"more-games-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"more-games-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Create "go to App Store?" alert
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Go to App Store?"
																 message:@"Check my other games!"
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"Go", nil] autorelease];
			[alertView setTag:2];
			[alertView show];
		}];
		
		CCMenu *iTunesMenu = [CCMenu menuWithItems:rateButton, moreGamesButton, dataResetButton, nil];
		[iTunesMenu alignItemsVerticallyWithPadding:15];
		iTunesMenu.position = ccp(windowSize.width / 2, rateButton.contentSize.height * 3);
		[self addChild:iTunesMenu z:1];
		
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
	}
	return self;
}

/**
 * Handle clicking of the alert view
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// Reset saved data
	if (alertView.tag == 0)
	{
		switch (buttonIndex) 
		{
			case 0:
				// Do nothing - dismiss
				break;
			case 1:
			{
				// Reset level times/completion status w/ defaults
				NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]];
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				
				[defaults setObject:[d objectForKey:@"levelData"] forKey:@"levelData"];
				
				// Reset game completion status
				[defaults setBool:NO forKey:@"completedGame"];
				
				// Reset "show instructions" toggle
				[defaults setBool:YES forKey:@"showInstructions"];
				
				// Sync defaults
				[defaults synchronize];
			}
				break;
			default:
				break;
		}
	}
	// "Rate" alert
	else if (alertView.tag == 1)
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
#if kLiteVersion
				// they want to rate it - lite
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=468133493"]];
#else
				// they want to rate it - full									  itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=409351780"]];
#endif
#endif
				break;
			default:
				break;
		}
	}
	// "More games" alert
	else if (alertView.tag == 2)
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
				// they want to see more games
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.com/apps/ganbarugames"]];
#endif
				break;
			default:
				break;
		}
	}
}

// on "dealloc" you need to release all your retained objects
- (void)dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
