//
//  UpgradeLayer.m
//  nonogrammadness
//
//  Created by Nathan Demick on 9/16/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

#import "UpgradeLayer.h"
#import "LevelSelectLayer.h"

#import "GameSingleton.h"
#import "SimpleAudioEngine.h"

@implementation UpgradeLayer

+ (CCScene *)scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	UpgradeLayer *layer = [UpgradeLayer node];
	
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
		CCSprite *bg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background-1%@.png", hdSuffix]];
		bg.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:bg z:0];
		
		// Create/add title
		CCSprite *title = [CCSprite spriteWithFile:[NSString stringWithFormat:@"thanks%@.png", hdSuffix]];
		title.position = ccp(windowSize.width / 2, windowSize.height - title.contentSize.height * 1.5);
		[self addChild:title z:1];
		
		// create and initialize a Label
//		CCLabelTTF *label = [CCLabelTTF labelWithString:@"I hope you enjoyed this lite version of Revolve Ball.\n\nGet the full version for:\n\t* 40 unique new levels\n\t* Game Center leaderboards" dimensions:CGSizeMake(windowSize.width - (20 * fontMultiplier), 175 * fontMultiplier) alignment:CCTextAlignmentLeft fontName:@"Helvetica" fontSize:14 * fontMultiplier];
//		label.color = ccc3(0, 0, 0);
		CCLabelBMFont *label = [CCLabelBMFont labelWithString:@"I hope you enjoyed this lite\nversion of Revolve Ball!\nGet the full version for 35\nmore levels and Game Center\nleaderboards!" fntFile:[NSString stringWithFormat:@"megalopolis-16%@.fnt", hdSuffix]];
		label.position = ccp(windowSize.width / 2, title.position.y - label.contentSize.height);
		[self addChild:label z:1];
		
		// Create "Upgrade" button
		CCMenuItemImage *upgradeButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"upgrade-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"upgrade-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Create "go to App Store?" alert
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Go to App Store?"
																 message:@""
																delegate:self
													   cancelButtonTitle:@"Cancel"
													   otherButtonTitles:@"Go", nil] autorelease];
			[alertView show];
		}];
		
		// Create "No thanks" button
		CCMenuItemImage *noThanksButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"no-thanks-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"no-thanks-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Go back to level select
			CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:0.5 scene:[LevelSelectLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenu *iTunesMenu = [CCMenu menuWithItems:upgradeButton, noThanksButton, nil];
		[iTunesMenu alignItemsVerticallyWithPadding:11];
		iTunesMenu.position = ccp(windowSize.width / 2, upgradeButton.contentSize.height * 2);
		[self addChild:iTunesMenu z:1];
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
			// they want to buy it - itms-apps://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=[APPID]&mt=8
			//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=386461624"]];
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
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
