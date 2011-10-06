//
//  LevelSelectScene.m
//  Revolve Ball
//
//  Created by Nathan Demick on 12/2/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "LevelSelectLayer.h"

@implementation LevelSelectLayer

+ (id)scene
{
	// Create a generic scene object to attach the layer to
	CCScene *scene = [CCScene node];
	
	// Instantiate the layer
	LevelSelectLayer *layer = [LevelSelectLayer node];
	
	// Add to generic scene
	[scene addChild:layer];
	
	// Return scene
	return scene;
}

- (id)init
{
	if ((self = [super init]))
	{
		CCLOG(@"Trying to init the level select layer!");
		
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
		
		// Start playing music if it's not already playing
		if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying])
		{
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"2.mp3"];
		}
		
#if kLiteVersion
		levelsPerWorld = 5;
#else
		levelsPerWorld = 10;
#endif
		
		// Add background to layer
		CCSprite *background = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background-%i%@.png", [GameSingleton sharedGameSingleton].currentWorld, hdSuffix]];
		background.position = ccp(windowSize.width / 2, windowSize.height / 2);
		[self addChild:background z:0];
		
		// Add "back" and "leaderboard" buttons
		CCMenuItemImage *backButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"back-hub-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"back-hub-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Load "hub" level
			[GameSingleton sharedGameSingleton].currentWorld = 0;
			[GameSingleton sharedGameSingleton].currentLevel = 0;
			
			CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[GameLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		
		CCMenuItemImage *leaderboardButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"leaderboards-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"leaderboards-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Determine the currently selected world
			NSString *leaderboardCategory = [NSString stringWithFormat:@"com.ganbarugames.revolveball.world_%i", [GameSingleton sharedGameSingleton].currentWorld];
			
			// Show leaderboard
			[[GameSingleton sharedGameSingleton] showLeaderboardForCategory:leaderboardCategory];
		}];
		
		// Hide the leaderboards button if no Game Center
		if (![[GameSingleton sharedGameSingleton] hasGameCenter])
		{
			leaderboardButton.visible = NO;
		}
		
		CCMenu *topMenu = [CCMenu menuWithItems:backButton, leaderboardButton, nil];
		topMenu.position = ccp(windowSize.width / 2, windowSize.height - backButton.contentSize.height);
		[topMenu alignItemsHorizontallyWithPadding:backButton.contentSize.width / 1.5];
		[self addChild:topMenu z:2];
		
		// Set up the previous/next buttons
		prevButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"prev-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"prev-button%@.png", hdSuffix] disabledImage:[NSString stringWithFormat:@"prev-button%@.png", hdSuffix] block:^(id sender) {
			[GameSingleton sharedGameSingleton].currentLevel--;
			
			// Disable the previous button if we're at the end of the line
			if ([GameSingleton sharedGameSingleton].currentLevel == 1)
			{
				prevButton.isEnabled = NO;
			}
			
			// Enable the next button if it had been disabled previously
			if (nextButton.isEnabled == NO)
			{
				nextButton.isEnabled = YES;
			}
			
			// Update level info labels
			[self displayLevelInfo];
			
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
		}];
		
		nextButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"next-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"next-button%@.png", hdSuffix] disabledImage:[NSString stringWithFormat:@"next-button%@.png", hdSuffix] block:^(id sender) {
			[GameSingleton sharedGameSingleton].currentLevel++;
			
			// Disable the next button if we're at the end of the line
			if ([GameSingleton sharedGameSingleton].currentLevel == levelsPerWorld)
			{
				nextButton.isEnabled = NO;
			}
			
			// Enable the prev button if it had been disabled previously
			if (prevButton.isEnabled == NO)
			{
				prevButton.isEnabled = YES;
			}
			
			// Update level info labels
			[self displayLevelInfo];
			
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
		}];	
		
		CCMenu *prevNextMenu = [CCMenu menuWithItems:prevButton, nextButton, nil];
		[prevNextMenu alignItemsHorizontallyWithPadding:220 * fontMultiplier];
		prevNextMenu.position = ccp(windowSize.width / 2, windowSize.height / 1.75);
		[self addChild:prevNextMenu z:2];
		
		// Add "play" button
		CCMenuItemImage *playButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"start-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"start-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Load current level stored in singleton variables
			CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[GameLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
			
			// Stop the BGM
			[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
		}];
		CCMenu *playButtonMenu = [CCMenu menuWithItems:playButton, nil];
		playButtonMenu.position = ccp(windowSize.width / 2, windowSize.height / 10);
		[self addChild:playButtonMenu z:2];
		
		// Add large "world title" text
		NSString *worldTitleString;
		switch ([GameSingleton sharedGameSingleton].currentWorld) 
		{
			case 1: worldTitleString = @"Clouds"; break;
			case 2: worldTitleString = @"Forest"; break;
			case 3: worldTitleString = @"Mountains"; break;
			case 4: worldTitleString = @"Caves"; break;
//			case 1: worldTitleString = @"World 1"; break;
//			case 2: worldTitleString = @"World 2"; break;
//			case 3: worldTitleString = @"World 3"; break;
//			case 4: worldTitleString = @"World 4"; break;
		}
		
		CCLabelBMFont *worldTitle = [CCLabelBMFont labelWithString:worldTitleString fntFile:[NSString stringWithFormat:@"megalopolis-50%@.fnt", hdSuffix]];
		worldTitle.position = ccp(windowSize.width / 2, windowSize.height / 1.3);
		[self addChild:worldTitle z:2];
		
		// Add instructional text
		CCLabelBMFont *instructions = [CCLabelBMFont labelWithString:@"Select a level" fntFile:[NSString stringWithFormat:@"megalopolis-24%@.fnt", hdSuffix]];
		[instructions setPosition:ccp(windowSize.width / 2, worldTitle.position.y - instructions.contentSize.height * 1.2)];
		[self addChild:instructions z:2];
		
		// Array of map objects
		maps = [[NSMutableArray arrayWithCapacity:levelsPerWorld] retain];
		
		// Load TMX maps into array
		for (int i = 0; i < levelsPerWorld; i++)
		{
			// Create string that is equal to map filename
			NSString *mapFile = [NSString stringWithFormat:@"%i-%i.tmx", [GameSingleton sharedGameSingleton].currentWorld, i + 1];
			
			CCTMXTiledMap *map = [CCTMXTiledMap tiledMapWithTMXFile:mapFile];
			map.position = ccp(windowSize.width / 2, windowSize.height / 1.75);
			map.scale = 0.10 * fontMultiplier;		// Make it really small!
			map.anchorPoint = ccp(0.5, 0.5);		// Try to set rotation point in the center of the map
			
			// Create map obj so we can get its' name + time limit
			[maps addObject:map];
		}
		
		// Add descriptive labels that show level info, such as title, best time, etc.
		levelTitle = [CCLabelBMFont labelWithString:@"Level Name" fntFile:[NSString stringWithFormat:@"megalopolis-24%@.fnt", hdSuffix]];
		[levelTitle setPosition:ccp(windowSize.width / 2, windowSize.height / 3)];
		[self addChild:levelTitle z:2];
		
		// Add level completion status indicator
		checkmark = [CCSprite spriteWithFile:[NSString stringWithFormat:@"checkmark-small%@.png", hdSuffix]];
		checkmark.position = ccp(levelTitle.position.x + levelTitle.contentSize.width / 2 + checkmark.contentSize.width / 2, levelTitle.position.y + checkmark.contentSize.height / 3);
		checkmark.opacity = 0;	// Hide initially
		[self addChild:checkmark z:2];
		
		levelBestTime = [CCLabelBMFont labelWithString:@"Best Time: --:--" fntFile:[NSString stringWithFormat:@"megalopolis-24%@.fnt", hdSuffix]];
		// Set the position based on the label above it
		[levelBestTime setPosition:ccp(windowSize.width / 2, levelTitle.position.y - levelBestTime.contentSize.height)];
		[self addChild:levelBestTime z:2];
		
		levelTimeLimit = [CCLabelBMFont labelWithString:@"Limit: --:--" fntFile:[NSString stringWithFormat:@"megalopolis-24%@.fnt", hdSuffix]];
		// Set the position based on the label above it
		[levelTimeLimit setPosition:ccp(windowSize.width / 2, levelBestTime.position.y - levelTimeLimit.contentSize.height)];
		[self addChild:levelTimeLimit z:2];
		
		// Update level info labels that we just created
		[self displayLevelInfo];
	}
	return self;
}



/* Updates labels that show best time/level title/etc. */
- (void)displayLevelInfo
{
	// Loop through all maps and remove them from display if possible
	for (int i = 0; i < [maps count]; i++)
	{
		CCTMXTiledMap *map = [maps objectAtIndex:i];
		if (map.parent == self)
		{
			[self removeChild:map cleanup:YES];
		}
	}
	
	// Create map obj so we can get its' name + time limit
	CCTMXTiledMap *map = [maps objectAtIndex:[GameSingleton sharedGameSingleton].currentLevel - 1];
	[map runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:14.0 angle:360]]];
	[self addChild:map z:1];	// Have the map rotate behind other objects
	
	int minutes, seconds;
	int currentLevelIndex = (([GameSingleton sharedGameSingleton].currentWorld - 1) * 10) + ([GameSingleton sharedGameSingleton].currentLevel - 1);
	
	// Get data structure that holds completion times for levels
	NSMutableArray *levelData = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelData"]];
	
	// Populate "best time" field
	int bestTimeInSeconds = [[[levelData objectAtIndex:currentLevelIndex] objectForKey:@"bestTime"] intValue];
	minutes = floor(bestTimeInSeconds / 60);
	seconds = bestTimeInSeconds % 60;
	
	// Set the map name field
	if ([map propertyNamed:@"name"])
	{
		[levelTitle setString:[map propertyNamed:@"name"]];
	}
	else
	{
		[levelTitle setString:[NSString stringWithFormat:@"Level %i", [GameSingleton sharedGameSingleton].currentLevel]];
	}
	
	// If the level is complete, display the best time... otherwise, just show "--:--"
	if ([[[levelData objectAtIndex:currentLevelIndex] objectForKey:@"complete"] boolValue])
	{
		[levelBestTime setString:[NSString stringWithFormat:@"Best Time: %02d:%02d", minutes, seconds]];
		
		// Also show the "completed" indicator
		checkmark.position = ccp(levelTitle.position.x + levelTitle.contentSize.width / 2 + checkmark.contentSize.width / 2, levelTitle.position.y + checkmark.contentSize.height / 3);
		checkmark.opacity = 255;
	}
	else
	{
		[levelBestTime setString:@"Best Time: --:--"];
		
		// Hide the "completed" indicator
		checkmark.opacity = 0;
	}
	
	// Populate time limit field
	if ([map propertyNamed:@"time"])
	{
		int timeLimitInSeconds = [[map propertyNamed:@"time"] intValue];
		minutes = floor(timeLimitInSeconds / 60);
		seconds = timeLimitInSeconds % 60;
		
		[levelTimeLimit setString:[NSString stringWithFormat:@"Limit: %02d:%02d", minutes, seconds]];
	}
}

- (void)dealloc
{
//	[levelIcons release];
	[maps release];
	[super dealloc];
}
@end