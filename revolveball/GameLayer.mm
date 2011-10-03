//
//  GameScene.mm
//  Ballgame
//
//  Created by Nathan Demick on 10/15/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "GameLayer.h"


// Constants for tile GIDs
#define kSquare 1
#define kLowerLeftTriangle 2
#define kLowerRightTriangle 3
#define kUpperLeftTriangle 4
#define kUpperRightTriangle 5
#define kGoal 6
#define kPlayerStart 7

#define kDownArrow 8
#define kLeftArrow 9
#define kRightArrow 10
#define kUpArrow 11

#define kDownSpikes 22
#define kLeftSpikes 23
#define kRightSpikes 24
#define kUpSpikes 25

#define kDownBoost 38
#define kLeftBoost 39
#define kRightBoost 40
#define kUpBoost 41

#define kBreakable 17

#define kToggleBlockGreenOff 18
#define kToggleBlockGreenOn 19
#define kToggleBlockRedOff 34
#define kToggleBlockRedOn 35
#define kToggleSwitchRed 20
#define kToggleSwitchGreen 21

#define kPeg 33
#define kClock 36
#define kBumper 100

#define kSkyLevelWarp 145
#define kForestLevelWarp 149
#define kMountainLevelWarp 153
#define kCaveLevelWarp 157

@implementation GameLayer

+ (id)scene
{
	// Create a generic scene object to attach the layer to
	CCScene *scene = [CCScene node];
	
	// Instantiate the layer
	GameLayer *layer = [GameLayer node];
	
	// Add to generic scene
	[scene addChild:layer];
	
	// Return scene
	return scene;
}

- (id)init
{
	if ((self = [super init]))
	{
		// Enable touches/accelerometer
		[self setIsTouchEnabled:YES];
		[self setIsAccelerometerEnabled:YES];		// Currently gravity is not set up to use accelerometer
		
		// Get window size
		windowSize = [CCDirector sharedDirector].winSize;
		
		// This string gets appended onto all image filenames based on whether the game is on iPad or not
		if ([GameSingleton sharedGameSingleton].isPad)
		{
			hdSuffix = @"-hd";
			fontMultiplier = 2;
			ptmRatio = 64;	// Set pixel-to-meter Box2D ratio
		}
		else
		{
			hdSuffix = @"";
			fontMultiplier = 1;
			ptmRatio = 32;	// Set pixel-to-meter Box2D ratio
		}
		
		// Determine if the player is on the "hub" level
		if ([GameSingleton sharedGameSingleton].currentWorld != 0 && [GameSingleton sharedGameSingleton].currentLevel != 0)
		{
			isHubLevel = YES;
		}
		else
		{
			isHubLevel = NO;
		}
		
		// Initialize values for rotational control
		previousAngle = currentAngle = 0;
		
		// Allow toggle switches to be pressed
		toggleSwitchTimeout = NO;
		
		// boolean for completing the level
		levelComplete = NO;
		paused = NO;
				
		// Create/add ball
		ball = [CCSprite spriteWithFile:[NSString stringWithFormat:@"ball%@.png", hdSuffix]];
		[ball setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[ball.texture setAliasTexParameters];
		[self addChild:ball z:2];
		
		// Add background to layer
		CCSprite *background = [CCSprite spriteWithFile:[NSString stringWithFormat:@"background-%i%@.png", [GameSingleton sharedGameSingleton].currentWorld, hdSuffix]];
		[background setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[background.texture setAliasTexParameters];
		[self addChild:background z:0];
		
		// Set up pause button
		CCMenuItem *pauseButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"pause-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"pause-button%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			if (paused)
			{
				// Schedule regular game loop
				[self schedule:@selector(update:)];
				
				// Schedule timer method for 1 second intervals
				[self schedule:@selector(timer:) interval:1];
				paused = NO;
				
				// Hide pause overlay
				id action = [CCEaseBounce actionWithAction:[CCMoveTo actionWithDuration:0.1 position:ccp(windowSize.width / 2, windowSize.height + pauseOverlay.contentSize.height / 2)]];
				[pauseOverlay runAction:action];
			}
			else 
			{
				// Unschedule the game loop & timer methods
				[self unschedule:@selector(update:)];
				[self unschedule:@selector(timer:)];
				paused = YES;
				
				// Show pause overlay
				id action = [CCEaseBounce actionWithAction:[CCMoveTo actionWithDuration:0.1 position:ccp(windowSize.width / 2, windowSize.height / 2)]];
				[pauseOverlay runAction:action];
			}
		}];
		CCMenu *pauseMenu = [CCMenu menuWithItems:pauseButton, nil];
		[pauseMenu setPosition:ccp(pauseButton.contentSize.width / 1.5, windowSize.height - pauseButton.contentSize.height / 1.5)];
		
		// Don't add the pause button if on the level select screen
		if (isHubLevel == NO)
		{
			[self addChild:pauseMenu z:4];
		}
		
		// Create pause overlay
		pauseOverlay = [CCSprite spriteWithFile:[NSString stringWithFormat:@"pause-overlay%@.png", hdSuffix]];
		[pauseOverlay setPosition:ccp(windowSize.width / 2, windowSize.height + pauseOverlay.contentSize.height / 2)];
		[pauseOverlay setVisible:NO];		// Hide initially
		[self addChild:pauseOverlay z:3];
		
		// Create "paused" label
		CCLabelBMFont *pauseText = [CCLabelBMFont labelWithString:@"PAUSED" fntFile:[NSString stringWithFormat:@"yoster-48%@.fnt", hdSuffix]];
		[pauseText setPosition:ccp(pauseOverlay.contentSize.width / 2, pauseOverlay.contentSize.height / 1.5)];
		[pauseOverlay addChild:pauseText];
		
		CCMenuItem *pauseResumeButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"resume-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"resume-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];

			// Schedule regular game loop
			[self schedule:@selector(update:)];
			
			// Schedule timer method for 1 second intervals
			[self schedule:@selector(timer:) interval:1];
			paused = NO;
			
			// Hide pause overlay
			id action = [CCEaseBounce actionWithAction:[CCMoveTo actionWithDuration:0.1 position:ccp(windowSize.width / 2, windowSize.height + pauseOverlay.contentSize.height / 2)]];
			[pauseOverlay runAction:action];
		}];
		
		CCMenuItem *pauseQuitButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"quit-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"quit-button-selected%@.png", hdSuffix] block:^(id sender) {
			// Play SFX
			[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
			
			// Hide the pause overlay as well as the map
			[pauseOverlay setVisible:NO];
			[map setVisible:NO];
			
			// Stop the background music, if playing
			[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
			
			// Load the level select screen
			CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[LevelSelectLayer scene]];
			[[CCDirector sharedDirector] replaceScene:transition];
		}];
		CCMenu *pauseOverlayMenu = [CCMenu menuWithItems:pauseResumeButton, pauseQuitButton, nil];
		[pauseOverlayMenu alignItemsVertically];
		[pauseOverlayMenu setPosition:ccp(pauseOverlay.contentSize.width / 2, pauseText.position.y - pauseText.contentSize.height * 2)];
		[pauseOverlay addChild:pauseOverlayMenu];
		
		
		// Create "this way up" icon
		upIcon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"this-way-up%@.png", hdSuffix]];
		[upIcon setPosition:ccp(windowSize.width / 2, windowSize.height / 1.3)];
		[upIcon setOpacity:0];
		[self addChild:upIcon z:2];
		
		// Create map obj and add to layer
		map = [CCTMXTiledMap tiledMapWithTMXFile:[NSString stringWithFormat:@"%i-%i%@.tmx", [GameSingleton sharedGameSingleton].currentWorld, [GameSingleton sharedGameSingleton].currentLevel, hdSuffix]];
		[map setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[self addChild:map z:1];
		
		// Hide map until "countdown" method fires
		[map setVisible:NO];
		
		// Set up timer
		if ([map propertyNamed:@"time"])
		{
			secondsLeft = [[map propertyNamed:@"time"] intValue];
		}
		else
		{
			secondsLeft = 180;
		}
		
		int minutes = floor(secondsLeft / 60);
		int seconds = secondsLeft % 60;
		
		timerLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%i:%02d", minutes, seconds] fntFile:[NSString stringWithFormat:@"yoster-16%@.fnt", hdSuffix]];
		[timerLabel setPosition:ccp(windowSize.width - timerLabel.contentSize.width, windowSize.height - timerLabel.contentSize.height)];
		[self addChild:timerLabel z:2];
		
		// If on world select hub...
		if (isHubLevel == YES)
		{
			// Hide the timer
			[timerLabel setVisible:NO];
			
			// Run a method which limits access to certain areas
			[self blockHubEntrances];
		}
		
		// Store the collidable tiles
		border = [[map layerNamed:@"Border"] retain];
		
		// Create Box2D world
		b2Vec2 gravity(sin(CC_DEGREES_TO_RADIANS(map.rotation)) * 15, -cos(CC_DEGREES_TO_RADIANS(map.rotation)) * 15);
		bool doSleep = false;
		world = new b2World(gravity, doSleep);

		// Initialize contact listener
		contactListener = new MyContactListener();
		world->SetContactListener(contactListener);
		
		b2Vec2 vertices[3];			// For making triangle-shaped physics objects
		int32 count = 3;
		CGPoint startPosition;		// Holds the starting position of the player
		
		bool sensorFlag;
		bool toggleBlockFlag;
		bool toggleSwitchFlag;
		bool destroyStartPosition;
		
		for (int x = 0; x < map.mapSize.width; x++)
			for (int y = 0; y < map.mapSize.height; y++)
			{
				if ([border tileGIDAt:ccp(x, y)])
				{
					//NSLog(@"Trying to interpret an object with GID %i at (%i, %i)", [border tileGIDAt:ccp(x, y)], x, y);
					
					// Body definition
					b2BodyDef bodyDefinition;
					bodyDefinition.position.Set(x + 0.5, map.mapSize.height - y - 0.5);		// Box2D uses inverse Y of TMX maps
					bodyDefinition.userData = [border tileAt:ccp(x, y)];		// Assign sprite to userData property
					
					b2Body *body = world->CreateBody(&bodyDefinition);
					
					// Shape
					b2PolygonShape polygonShape;
					
					// Default sensor flag to false
					sensorFlag = NO;
					toggleBlockFlag = NO;
					toggleSwitchFlag = NO;
					destroyStartPosition = NO;
					
					int tileGID = [border tileGIDAt:ccp(x, y)];
					switch (tileGID) 
					{
						case kSquare:
							polygonShape.SetAsBox(0.5f, 0.5f);		// Create 1x1 box shape
							break;
						case kLowerLeftTriangle:
							// Lower left triangle
							vertices[0].Set(-0.5f, -0.5f);
							vertices[1].Set(0.5f, -0.5f);
							vertices[2].Set(-0.5f, 0.5f);
							
							polygonShape.Set(vertices, count);
							break;
						case kLowerRightTriangle:
							// Lower right triangle
							vertices[0].Set(-0.5f, -0.5f);
							vertices[1].Set(0.5f, -0.5f);
							vertices[2].Set(0.5f, 0.5f);
							
							polygonShape.Set(vertices, count);
							break;
						case kUpperLeftTriangle:
							// Upper left triangle
							vertices[0].Set(-0.5f, 0.5f);
							vertices[1].Set(0.5f, -0.5f);
							vertices[2].Set(0.5f, 0.5f);
							
							polygonShape.Set(vertices, count);
							break;
						case kUpperRightTriangle:
							// Upper right triangle
							vertices[0].Set(-0.5f, -0.5f);
							vertices[1].Set(0.5f, 0.5f);
							vertices[2].Set(-0.5f, 0.5f);
							
							polygonShape.Set(vertices, count);
							break;
						case kGoal:
							// Goal block
							polygonShape.SetAsBox(0.5f, 0.5f);		// Create 1x1 box shape
							sensorFlag = YES;
							break;
						case kPlayerStart:
							polygonShape.SetAsBox(0.5f, 0.5f);		// Create 1x1 box shape
							
							// Player starting location
							startPosition = ccp(x, y);
							
							// Delete tile that showed start position
							[border removeTileAt:ccp(x, y)];
							
							// Flag this body to be destroyed immediately
							destroyStartPosition = YES;
							break;
						case kDownBoost:
						case kLeftBoost:
						case kRightBoost:
						case kUpBoost:
							polygonShape.SetAsBox(0.4f, 0.4f);		// Create smaller than 1x1 box shape, so player has to overlap the tile slightly
							sensorFlag = YES;
							break;
						case kDownSpikes:
						case kLeftSpikes:
						case kRightSpikes:
						case kUpSpikes:
							polygonShape.SetAsBox(0.5f, 0.5f);
							break;
						case kBreakable:
							polygonShape.SetAsBox(0.5f, 0.5f);
							break;
						case kBumper:
							// CURRENTLY UNIMPLEMENTED
							//polygonShape.SetAsBox(0.33f, 0.33f);
							//boxShapeDef.restitution = 1; // Make more bouncy?
							break;
						case kPeg:
							{
								b2Vec2 verts[] = 
								{
									b2Vec2(-0.17f, 0.17f),
									b2Vec2(-0.25f, 0.0f),
									b2Vec2(-0.17f, -0.17f),
									b2Vec2(0.0f, -0.25f),
									b2Vec2(0.17f, -0.17f),
									b2Vec2(0.25f, 0.0f),
									b2Vec2(0.17f, 0.17f),
									b2Vec2(0.0f, 0.25f)
								};
								
								polygonShape.Set(verts, 8);
								//polygonShape.SetAsBox(0.25f, 0.25f);
							}	
							break;
						case kClock:
							{
							polygonShape.SetAsBox(0.25f, 0.25f);
							sensorFlag = YES;
							}	
							break;
						case kToggleBlockGreenOn:
						case kToggleBlockRedOn:
						case kToggleBlockGreenOff:
						case kToggleBlockRedOff:
							toggleBlockFlag = YES;
							polygonShape.SetAsBox(0.5f, 0.5f);
							break;
						case kToggleSwitchRed:
						case kToggleSwitchGreen:
							sensorFlag = YES;
							toggleSwitchFlag = YES;
							polygonShape.SetAsBox(0.4f, 0.4f);	// Slightly smaller box to try to fake a circle - lazy!
						default:
							// Default is to create sensor that then triggers an NSLog that tells us we're missing something
							polygonShape.SetAsBox(0.5f, 0.5f);		// Create 1x1 box shape
							sensorFlag = YES;
							break;
					}
					
					// Fixture definition
					b2FixtureDef fixtureDefinition;
					fixtureDefinition.shape = &polygonShape;
					fixtureDefinition.isSensor = sensorFlag;
					
					body->CreateFixture(&fixtureDefinition);
					
					if (destroyStartPosition)
					{
						world->DestroyBody(body);
						destroyStartPosition = NO;
					}
					
					// Push toggle blocks into a vector
					if (toggleBlockFlag)
					{
						// Set the "off" blocks to be inactive at first!
						if (tileGID == kToggleBlockGreenOff || tileGID == kToggleBlockRedOff)
							body->SetActive(false);
						toggleBlockGroup.push_back(body);
					}
					
					// Push toggle switches into a vector
					if (toggleSwitchFlag)
						toggleSwitchGroup.push_back(body);
				}
			}
		
		// Create ball body & shape
		b2BodyDef ballBodyDef;
		ballBodyDef.type = b2_dynamicBody;
		//ballBodyDef.fixedRotation = true;	// Prevent rotation!
		
		// Set the starting position of the player
		ballBodyDef.position.Set(startPosition.x + 0.5, map.mapSize.height - startPosition.y - 0.5);		// Y values are inverted between TMX and Box2D
		
		ballBodyDef.userData = ball;		// Set to CCSprite
		b2Body *ballBody = world->CreateBody(&ballBodyDef);
		
		// Set player shape
		b2CircleShape circle;
		circle.m_radius = (((float)ptmRatio / 2) - 1) / ptmRatio;		// A 32px / 2 = 16px - 1px = 15px radius - a perfect 1m circle would get stuck in 1m gaps
		
		// Player fixture
		b2FixtureDef ballFixtureDefinition;
		ballFixtureDefinition.shape = &circle;
		ballFixtureDefinition.density = 1.0f;
		ballFixtureDefinition.friction = 0.2f;
		ballFixtureDefinition.restitution = 0.4f;
		ballBody->CreateFixture(&ballFixtureDefinition);
		
		// Set default map anchor point - Need to do this here once so the map actually appears around the ball
		float anchorX = ballBody->GetPosition().x / map.mapSize.width;
		float anchorY = ballBody->GetPosition().y / map.mapSize.height;
		[map setAnchorPoint:ccp(anchorX, anchorY)];
		
		// Schedule countdown timer
		countdownTime = 2;
		[self schedule:@selector(countdown:) interval:1.0];
	}
	return self;
}

- (void)countdown:(ccTime)dt
{
	if (![map visible])
		[map setVisible:YES];
	
	// If we're on the hub level
	if ([GameSingleton sharedGameSingleton].currentWorld == 0 && [GameSingleton sharedGameSingleton].currentLevel == 0)
	{
		NSString *text;
		if (countdownTime == 0)
			text = @"Select a world";
		else if (countdownTime == 1)
			text = @"Touch to rotate!";
		else 
			text = @"";
		//text = [NSString stringWithFormat:@"%i", countdownTime];
		
		CCLabelBMFont *label = [CCLabelBMFont labelWithString:text fntFile:[NSString stringWithFormat:@"yoster-24%@.fnt", hdSuffix]];
		[label setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[self addChild:label z:2];
		
		// Move and fade actions
		id moveAction = [CCMoveTo actionWithDuration:3 position:ccp(ball.position.x, ball.position.y + 64)];
		id fadeAction = [CCFadeOut actionWithDuration:1];
		id removeAction = [CCCallFuncN actionWithTarget:self selector:@selector(removeSpriteFromParent:)];
		
		[label runAction:[CCSequence actions:[CCSpawn actions:moveAction, fadeAction, nil], removeAction, nil]];
	}
	// Otherwise, do "normal" actions
	else 
	{
		NSString *text;
		if (countdownTime == 0)
			text = @"GO";
		else if (countdownTime == 1)
			text = @"READY";
		else 
			text = @"";
		//text = [NSString stringWithFormat:@"%i", countdownTime];
		
		CCLabelBMFont *label = [CCLabelBMFont labelWithString:text fntFile:[NSString stringWithFormat:@"yoster-48%@.fnt", hdSuffix]];
		[label setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
		[self addChild:label z:2];
		
		// Move and fade actions
		id moveAction = [CCMoveTo actionWithDuration:1 position:ccp(ball.position.x, ball.position.y + 64)];
		id fadeAction = [CCFadeOut actionWithDuration:1];
		id removeAction = [CCCallFuncN actionWithTarget:self selector:@selector(removeSpriteFromParent:)];
		
		[label runAction:[CCSequence actions:[CCSpawn actions:moveAction, fadeAction, nil], removeAction, nil]];
	}
	
	countdownTime--;
	
	if (countdownTime == -1)
	{
		// Unschedule self
		[self unschedule:@selector(countdown:)];
		
		// Schedule regular game loop
		[self schedule:@selector(update:)];
		
		// Schedule timer function for 1 second intervals
		[self schedule:@selector(timer:) interval:1];
		
		// Start playing BGM
		if ([GameSingleton sharedGameSingleton].currentWorld == 0 && [GameSingleton sharedGameSingleton].currentLevel == 0)
		{
			// Start playing music if it's not already playing
			if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying])
				[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"level-select.mp3"];
		}
		else
		{
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"gameplay.mp3"];
		}

	}
}

- (void)togglePause:(ccTime)dt
{
	static bool functionCalled = false;
	
	// Already been called once... re-schedule update loop, unschedule self!
	if (functionCalled)
	{
		[self unschedule:@selector(togglePause:)];
		[self schedule:@selector(update:)];
		[self schedule:@selector(toggleSwitchTimeoutCallback:) interval:1.0];
		functionCalled = false;
	}
	// First time called... unschedule update loop & play SFX
	else
	{
		[self schedule:@selector(togglePause:) interval:0.25];	// Call this method again in 0.5 seconds
		[self unschedule:@selector(update:)];			// Pause the fizziks
		[[SimpleAudioEngine sharedEngine] playEffect:@"toggle.caf"];
		functionCalled = true;
	}
}

- (void)toggleSwitchTimeoutCallback:(ccTime)dt
{
	// Flag to allow toggle switch to be thrown again
	toggleSwitchTimeout = false;
	[self unschedule:@selector(toggleSwitchTimeoutCallback:)];
}

- (void)update:(ccTime)dt
{
	// Get window size
//	CGSize windowSize = [CCDirector sharedDirector].windowSize;
	
	// Step through world collisions - (timeStep, velocityIterations, positionIterations)
	world->Step(dt, 10, 10);
	
	// Local convenience variable
	b2Body *ballBody;
	
	// Vector containing Box2D bodies to be destroyed
	std::vector<b2Body *> discardedItems;
	
	// Loop through all Box2D bodies in the world and find the ball object;
	// Update the map's anchor point + the player sprite's rotation based on that object
	for (b2Body *b = world->GetBodyList(); b; b = b->GetNext()) 
	{
		// Find the ball in the list of Box2D objects, and move the map's anchor position based on the ball's position within the map
		if ((CCSprite *)b->GetUserData() == ball)
		{
			// Get the CCSprite attached to Box2D obj
			CCSprite *ballSprite = (CCSprite *)b->GetUserData();
			ballSprite.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
			
			// Update map's anchor point based on ball position; position within width/height of map?
			float anchorX = b->GetPosition().x / map.mapSize.width;
			float anchorY = b->GetPosition().y / map.mapSize.height;

			[map setAnchorPoint:ccp(anchorX, anchorY)];
			
			// Set local variable equal to ball Box2D body in order to apply forces, etc. to it later
			ballBody = b;
		}
	}
	
	// Loop thru sprite contact queue
	if (!levelComplete)
	for (std::vector<ContactPoint>::iterator position = contactListener->contactQueue.begin(); position != contactListener->contactQueue.end(); ++position) 
	{
		ContactPoint contact = *position;
		
		// Find "other" object in the contact
		b2Body *b = contact.fixtureA->GetBody();
		
		if ((CCSprite *)b->GetUserData() == ball)
			b = contact.fixtureB->GetBody();
		
		// Get sprite associated w/ body
		CCSprite *s = (CCSprite *)b->GetUserData();
		
		// Process collisions with all other objects
		int tileGID = [border tileGIDAt:ccp(s.position.x / ptmRatio, map.mapSize.height - (s.position.y / ptmRatio) - 1)];	// Box2D and TMX y-coords are inverted
		switch (tileGID) 
		{
			case kSquare:
			case kUpperLeftTriangle:
			case kUpperRightTriangle:
			case kLowerLeftTriangle:
			case kLowerRightTriangle:
			case kToggleBlockRedOn:
			case kToggleBlockGreenOn:
			case kToggleBlockRedOff:
			case kToggleBlockGreenOff:
			case kLeftArrow:
			case kRightArrow:
			case kDownArrow:
			case kUpArrow:
			case kPeg:
				// Do nothing
				break;
			case kToggleSwitchRed:
			case kToggleSwitchGreen:
				if (!toggleSwitchTimeout)
				{
					toggleSwitchTimeout = true;
					
					// Switch the "active" states for each body in the "toggleGroup" vector
					for (std::vector<b2Body *>::iterator position = toggleBlockGroup.begin(); position != toggleBlockGroup.end(); ++position) 
					{
						b2Body *body = *position;
						CGPoint blockPosition = ccp(body->GetPosition().x - 0.5, map.mapSize.height - body->GetPosition().y - 0.5);

						if (body->IsActive())
						{
							// Turn active blocks off
							body->SetActive(false);
							if ([border tileGIDAt:blockPosition] == kToggleBlockRedOn)
								[border setTileGID:kToggleBlockRedOff at:blockPosition];
							else// if ([border tileGIDAt:blockPosition] == kToggleBlockGreenOn)
								[border setTileGID:kToggleBlockGreenOff at:blockPosition];
						}
						else
						{
							// Turn inactive blocks on
							body->SetActive(true);
							if ([border tileGIDAt:blockPosition] == kToggleBlockRedOff)
								[border setTileGID:kToggleBlockRedOn at:blockPosition];
							else// if ([border tileGIDAt:blockPosition] == kToggleBlockGreenOff)
								[border setTileGID:kToggleBlockGreenOn at:blockPosition];
						}
					}
					
					// Switch the colors for each switch
					for (std::vector<b2Body *>::iterator position = toggleSwitchGroup.begin(); position != toggleSwitchGroup.end(); ++position) 
					{
						b2Body *body = *position;
						CGPoint switchPosition = ccp(body->GetPosition().x - 0.5, map.mapSize.height - body->GetPosition().y - 0.5);
						
						// Find the current color for the switch
						if ([border tileGIDAt:switchPosition] == kToggleSwitchRed)
							[border setTileGID:kToggleSwitchGreen at:switchPosition];
						else
							[border setTileGID:kToggleSwitchRed at:switchPosition];
					}
	
					// Do pause effect
					[self togglePause:0];
				}
				break;
			case kBreakable:
				{
					// Breakable blocks are handled in the SFX contact queue, since they need a certain impulse to be destroyed
				}
				break;
			case kClock:
					// Remove the clock sensor
					discardedItems.push_back(b);
					
					[[SimpleAudioEngine sharedEngine] playEffect:@"time-pickup.caf"];
				
					// Add time to time limit
					[self gainTime:5];
				break;
			case kGoal:
				{
					[self winGame];
				}
				break;
			case kDownBoost:
				[[SimpleAudioEngine sharedEngine] playEffect:@"boost.caf"];
				ballBody->ApplyLinearImpulse(b2Vec2(0.0f, -15.0f), ballBody->GetPosition());
				break;
			case kLeftBoost:
				[[SimpleAudioEngine sharedEngine] playEffect:@"boost.caf"];
				ballBody->ApplyLinearImpulse(b2Vec2(-15.0f, 0.0f), ballBody->GetPosition());
				break;
			case kRightBoost:
				[[SimpleAudioEngine sharedEngine] playEffect:@"boost.caf"];
				ballBody->ApplyLinearImpulse(b2Vec2(15.0f, 0.0f), ballBody->GetPosition());
				break;
			case kUpBoost:
				[[SimpleAudioEngine sharedEngine] playEffect:@"boost.caf"];
				ballBody->ApplyLinearImpulse(b2Vec2(0.0f, 15.0f), ballBody->GetPosition());
				break;
			case kDownSpikes:
				// Subtract time from time limit
				[self loseTime:5];
				
				[[SimpleAudioEngine sharedEngine] playEffect:@"spike-hit.caf"];
				
				// Push ball in opposite direction
				ballBody->ApplyLinearImpulse(b2Vec2(0.0f, -4.0f), ballBody->GetPosition());
				break;
			case kLeftSpikes:
				// Subtract time from time limit
				[self loseTime:5];
				
				[[SimpleAudioEngine sharedEngine] playEffect:@"spike-hit.caf"];
				
				// Push ball in opposite direction
				ballBody->ApplyLinearImpulse(b2Vec2(-4.0f, 0.0f), ballBody->GetPosition());
				break;
			case kRightSpikes:
				// Subtract time from time limit
				[self loseTime:5];
				
				[[SimpleAudioEngine sharedEngine] playEffect:@"spike-hit.caf"];
				
				// Push ball in opposite direction
				ballBody->ApplyLinearImpulse(b2Vec2(4.0f, 0.0f), ballBody->GetPosition());
				break;
			case kUpSpikes:
				// Subtract time from time limit
				[self loseTime:5];
				
				[[SimpleAudioEngine sharedEngine] playEffect:@"spike-hit.caf"];
				
				// Push ball in opposite direction
				ballBody->ApplyLinearImpulse(b2Vec2(0.0f, 4.0f), ballBody->GetPosition());
				break;
			case kBumper:
				// Find the contact point and apply a linear inpulse at that point
				break;
			case kSkyLevelWarp:
				// This condition allows the physics simulation to continue, but starts the transition to 
				// the level select scene, which makes the "warp" feel more fluid
				if (!levelComplete)
				{
					levelComplete = YES;

					// Set world/level
					[GameSingleton sharedGameSingleton].currentWorld = 1;
					[GameSingleton sharedGameSingleton].currentLevel = 1;
					
					map.visible = NO;
					
					// Transition to level select scene
					[[CCDirector sharedDirector] replaceScene:[CCTransitionRotoZoom transitionWithDuration:1.0 scene:[LevelSelectLayer node]]];
				}
				break;
			case kForestLevelWarp:
				// This condition allows the physics simulation to continue, but starts the transition to 
				// the level select scene, which makes the "warp" feel more fluid
				if (!levelComplete)
				{
					levelComplete = YES;

					// Set world/level
					[GameSingleton sharedGameSingleton].currentWorld = 2;
					[GameSingleton sharedGameSingleton].currentLevel = 1;
					
					map.visible = NO;
					
					// Transition to level select scene
					[[CCDirector sharedDirector] replaceScene:[CCTransitionRotoZoom transitionWithDuration:1.0 scene:[LevelSelectLayer node]]];
				}
				break;
			case kMountainLevelWarp:
				// This condition allows the physics simulation to continue, but starts the transition to 
				// the level select scene, which makes the "warp" feel more fluid
				if (!levelComplete)
				{
					levelComplete = YES;

					// Set world/level
					[GameSingleton sharedGameSingleton].currentWorld = 3;
					[GameSingleton sharedGameSingleton].currentLevel = 1;
					
					map.visible = NO;
					
					// Transition to level select scene
					[[CCDirector sharedDirector] replaceScene:[CCTransitionRotoZoom transitionWithDuration:1.0 scene:[LevelSelectLayer node]]];
				}
				break;
			case kCaveLevelWarp:
				// This condition allows the physics simulation to continue, but starts the transition to 
				// the level select scene, which makes the "warp" feel more fluid
				if (!levelComplete)
				{
					levelComplete = YES;

					// Set world/level
					[GameSingleton sharedGameSingleton].currentWorld = 4;
					[GameSingleton sharedGameSingleton].currentLevel = 1;
					
					map.visible = NO;
					
					// Transition to level select scene
					[[CCDirector sharedDirector] replaceScene:[CCTransitionRotoZoom transitionWithDuration:1.0 scene:[LevelSelectLayer node]]];
				}
				break;
			default:
				//NSLog(@"Touching unrecognized tile GID: %i", tileGID);
				break;
		}
	}
	
	// Loop thru SFX contact queue
	if (!levelComplete)
	for (std::vector<ContactPoint>::iterator position = contactListener->sfxQueue.begin(); position != contactListener->sfxQueue.end(); ++position) 
	{
		ContactPoint contact = *position;
		
		// Find "other" object in the contact
		b2Body *b = contact.fixtureA->GetBody();
		
		if ((CCSprite *)b->GetUserData() == ball)
			b = contact.fixtureB->GetBody();
		
		// Get sprite associated w/ body
		CCSprite *s = (CCSprite *)b->GetUserData();
		
		// Process collisions with all other objects
		int tileGID = [border tileGIDAt:ccp(s.position.x / ptmRatio, map.mapSize.height - (s.position.y / ptmRatio) - 1)];	// Box2D and TMX y-coords are inverted
		switch (tileGID) 
		{
			case kSquare:
			case kUpperLeftTriangle:
			case kUpperRightTriangle:
			case kLowerLeftTriangle:
			case kLowerRightTriangle:
			case kToggleBlockRedOn:
			case kToggleBlockGreenOn:
				if (contact.impulse > 1.5)
					[[SimpleAudioEngine sharedEngine] playEffect:@"wall-hit.caf"];
				break;
			case kPeg:
				if (contact.impulse > 1.5)
					[[SimpleAudioEngine sharedEngine] playEffect:@"peg-hit.caf"];
				break;
			case kBreakable:
				if (std::find(discardedItems.begin(), discardedItems.end(), b) == discardedItems.end() && contact.impulse > 3.5)
				{
					//[self createParticleEmitterAt:ccp(s.position.x + 160 - ballBody->GetPosition().x * ptmRatio, s.position.y + 240 - ballBody->GetPosition().y * ptmRatio)];
					
					// Create a particle effect at the position of the destroyed block on the map
					[self createParticleEmitterAt:ccp(s.position.x + s.contentSize.width / 2, s.position.y + s.contentSize.height / 2)];
					
					// Schedule block for removal
					discardedItems.push_back(b);
					
					// Play SFX
					[[SimpleAudioEngine sharedEngine] playEffect:@"wall-break.caf"];
				}
				else if (contact.impulse > 1.5)
					[[SimpleAudioEngine sharedEngine] playEffect:@"wall-hit.caf"];
				break;
		}
	}
	
	// Clear the contact vector
	contactListener->contactQueue.clear();
	
	// Clear the SFX vector
	contactListener->sfxQueue.clear();
	
	// Remove any Box2D bodies (w/ attached CCSprites) in "discardedItems" vector
	std::vector<b2Body *>::iterator position;
	for (position = discardedItems.begin(); position != discardedItems.end(); ++position) 
	{
		b2Body *body = *position;     
		if (body->GetUserData() != NULL) 
		{
			// Remove sprite from map
			CCSprite *s = (CCSprite *)body->GetUserData();
			[border removeChild:s cleanup:YES];
		}
		world->DestroyBody(body);
	}
}

- (void)winGame
{
	// Boolean which sets contact listeners to be ignored
	levelComplete = YES;
	
	// Disable touches so player can't move anymore
	[self setIsTouchEnabled:NO];
	
	// Stop countdown timer
	[self unschedule:@selector(timer:)];
	
	// Play sound effect
	[[SimpleAudioEngine sharedEngine] playEffect:@"level-complete.caf"];
	
	// Stop the BGM
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	
	int currentWorldIndex = ([GameSingleton sharedGameSingleton].currentWorld - 1) * 10;
	int currentLevelIndex = currentWorldIndex + [GameSingleton sharedGameSingleton].currentLevel - 1;
	
	// Get best time from user defaults
	NSMutableArray *levelData = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelData"]];
	NSDictionary *d = [levelData objectAtIndex:currentLevelIndex];
	
	// Determine if current time is faster than saved
	int currentTime = [[map propertyNamed:@"time"] intValue] - secondsLeft;
	int bestSavedTime = [[d objectForKey:@"bestTime"] intValue];
	if (currentTime < bestSavedTime)
	{
		bestSavedTime = currentTime;	// for display below
		
		// Create a new dictionary to store in the "levelData" array
		NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:currentTime], @"bestTime", [NSNumber numberWithBool:YES], @"complete", nil];
		
		// levelData dictionary gets updated here w/ current time
		[levelData replaceObjectAtIndex:currentLevelIndex withObject:d];
		
		// Sync with NSUserDefaults
		[[NSUserDefaults standardUserDefaults] setObject:levelData forKey:@"levelData"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		int bestWorldTime = 0;
		BOOL sendScore = YES;
		// Determine if composite time for the entire world can be sent to Game Center
		for (int i = currentWorldIndex, j = currentWorldIndex + 10; i < j; i++)
		{
			d = [levelData objectAtIndex:i];
			if ([[d objectForKey:@"complete"] boolValue])
				bestWorldTime += [[d objectForKey:@"bestTime"] intValue];
			else
			{
				// NSLog(@"Level %i not marked as complete", i + 1);
				sendScore = NO;
				break;
			}
		}
		
		if (sendScore)
		{
			// Determine the currently selected world
			NSString *leaderboardCategory = [NSString stringWithFormat:@"com.ganbarugames.revolveball.world_%i", [GameSingleton sharedGameSingleton].currentWorld];
			
			// Send time to Game Center leaderboards
			[[GameSingleton sharedGameSingleton] reportScore:bestWorldTime forCategory:leaderboardCategory];
			
			// NSLog(@"Sending best world time of %i", bestWorldTime);
		}
	}
	
	// Add "Finish" label
	CCLabelBMFont *finishLabel = [CCLabelBMFont labelWithString:@"FINISH!" fntFile:[NSString stringWithFormat:@"yoster-48%@.fnt", hdSuffix]];
	[finishLabel setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
	[self addChild:finishLabel z:4];
	
	int minutes = floor(currentTime / 60);
	int seconds = currentTime % 60;

	// Add "your time" label
	CCLabelBMFont *yourTimeLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Current: %02d:%02d", minutes, seconds] fntFile:[NSString stringWithFormat:@"yoster-32%@.fnt", hdSuffix]];
	[yourTimeLabel setPosition:ccp(windowSize.width / 2, finishLabel.position.y - yourTimeLabel.contentSize.height * 1.5)];
	[self addChild:yourTimeLabel z:1];
	
	minutes = floor(bestSavedTime / 60);
	seconds = bestSavedTime % 60;
	
	// Add "best time" label
	CCLabelBMFont *bestTimeLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Best: %02d:%02d", minutes, seconds] fntFile:[NSString stringWithFormat:@"yoster-32%@.fnt", hdSuffix]];
	[bestTimeLabel setPosition:ccp(windowSize.width / 2, yourTimeLabel.position.y - bestTimeLabel.contentSize.height)];
	[self addChild:bestTimeLabel z:1];
	
	// Add button which takes us back to level select
	// TODO: Just have one button, "continue"
	CCMenuItem *nextButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"next-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"next-button-selected%@.png", hdSuffix] target:self selector:@selector(nextButtonAction:)];
	CCMenuItem *retryButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"retry-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"retry-button-selected%@.png", hdSuffix] target:self selector:@selector(retryButtonAction:)];
	CCMenu *menu = [CCMenu menuWithItems:nextButton, retryButton, nil];
	[menu alignItemsVertically];
	[menu setPosition:ccp(windowSize.width / 2, windowSize.height / 6)];
	[self addChild:menu z:1];
}

- (void)loseGame
{
	// Boolean which ignores contact listeners
	levelComplete = YES;
	
	// Disable touches so player can't move anymore
	[self setIsTouchEnabled:NO];
	
	// Stop timer
	[self unschedule:@selector(timer:)];
	
	// Set timer display to be 0:00, just in case it was otherwise negative
	[timerLabel setString:@"0:00"];
	
	// Play "you lose" sfx
	[[SimpleAudioEngine sharedEngine] playEffect:@"level-fail.caf"];
	
	// Stop the BGM
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	
	// Add "FAIL" label
	CCLabelBMFont *finishLabel = [CCLabelBMFont labelWithString:@"FAILURE!" fntFile:[NSString stringWithFormat:@"yoster-48%@.fnt", hdSuffix]];
	[finishLabel setPosition:ccp(windowSize.width / 2, windowSize.height / 2)];
	[self addChild:finishLabel z:4];
	
	// Add button which takes us back to level select
	// TODO: Change these buttons to "retry" and "quit"
	CCMenuItem *nextButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"wide-back-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"wide-back-button-selected%@.png", hdSuffix] target:self selector:@selector(backButtonAction:)];
	CCMenuItem *retryButton = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"retry-button%@.png", hdSuffix] selectedImage:[NSString stringWithFormat:@"retry-button-selected%@.png", hdSuffix] target:self selector:@selector(retryButtonAction:)];
	CCMenu *menu = [CCMenu menuWithItems:nextButton, retryButton, nil];
	[menu alignItemsVertically];
	[menu setPosition:ccp(windowSize.width / 2, windowSize.height / 6)];
	[self addChild:menu z:1];
}

/**
 Remove time from countdown timer and display label
 */
- (void)loseTime:(int)seconds
{	
	// Subtract time from "secondsLeft" time limit variable
	secondsLeft -= seconds;
	
	// Create a label that shows how much time you lost
	NSString *s = [NSString stringWithFormat:@"-%i seconds", seconds];
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:s fntFile:[NSString stringWithFormat:@"yoster-16%@.fnt", hdSuffix]];
	[label setPosition:ccp(ball.position.x, ball.position.y + 16)];
	[self addChild:label z:5];

	// Move and fade actions
	id moveAction = [CCMoveTo actionWithDuration:1 position:ccp(ball.position.x, ball.position.y + 64)];
	id fadeAction = [CCFadeOut actionWithDuration:1];
	id removeAction = [CCCallFuncN actionWithTarget:self selector:@selector(removeSpriteFromParent:)];
	
	//[deductedTimeLabel runAction:[CCSequence actions:[CCSpawn actions:moveAction, fadeAction, nil], removeAction, nil]];
	[label runAction:[CCSequence actions:[CCSpawn actions:moveAction, fadeAction, nil], removeAction, nil]];
	
	if (secondsLeft <= 0)
		[self loseGame];
}

/**
 Add time to countdown timer and display label
 */
- (void)gainTime:(int)seconds
{
	// Add time to "secondsLeft" time limit variable
	secondsLeft += seconds;
	
	// Create a label that shows how much time you got
	NSString *s = [NSString stringWithFormat:@"+%i seconds", seconds];
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:s fntFile:[NSString stringWithFormat:@"yoster-16%@.fnt", hdSuffix]];
	[label setPosition:ccp(ball.position.x, ball.position.y + 16)];
	[self addChild:label z:5];
	
	// Move and fade actions
	id moveAction = [CCMoveTo actionWithDuration:1 position:ccp(ball.position.x, ball.position.y + 64)];
	id fadeAction = [CCFadeOut actionWithDuration:1];
	id removeAction = [CCCallFuncN actionWithTarget:self selector:@selector(removeSpriteFromParent:)];
	
	[label runAction:[CCSequence actions:[CCSpawn actions:moveAction, fadeAction, nil], removeAction, nil]];
}

/**
 Update the game timer
 */
- (void)timer:(ccTime)dt
{
	secondsLeft--;
	
	if (secondsLeft <= 0)
		[self loseGame];
	
	int minutes = floor(secondsLeft / 60);
	int seconds = secondsLeft % 60;
	NSString *time = [NSString stringWithFormat:@"%i:%02d", minutes, seconds];
	
	[timerLabel setString:time];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	//b2Vec2 gravity(-acceleration.y * 15, acceleration.x * 15);
	//world->SetGravity(gravity);
	
	// (1,0) or (-1,0) means the player is holding the device sideways
	float tiltRatio = fabs(acceleration.x) - fabs(acceleration.y);
	
	if (tiltRatio > 0.3)
	{
		if (upIcon.opacity == 0)
			[upIcon runAction:[CCFadeIn actionWithDuration:0.25]];
	}
	else
	{
		if (upIcon.opacity == 255)
			[upIcon runAction:[CCFadeOut actionWithDuration:0.25]];
	}

	//NSLog(@"Accelerometer tilt ratio: %f", tiltRatio);
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	if (touch && !paused)
	{
		// Convert location
		CGPoint touchPoint = [touch locationInView:[touch view]];
		
		// Should one of these be 'previousAngle'?
		currentAngle = currentAngle = CC_RADIANS_TO_DEGREES(atan2(windowSize.width / 2 - touchPoint.x, windowSize.height / 2 - touchPoint.y));
		
		if (currentAngle < 0) currentAngle += 360;
	}
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	if (touch && !paused)
	{
		// Convert location
		CGPoint touchPoint = [touch locationInView:[touch view]];
		
		previousAngle = currentAngle;
		
		currentAngle = CC_RADIANS_TO_DEGREES(atan2(windowSize.width / 2 - touchPoint.x, windowSize.height / 2 - touchPoint.y));
		
		if (currentAngle < 0) currentAngle += 360;
		
		float difference = currentAngle - previousAngle;
		
		// Change rotation of map
		map.rotation -= difference;
		
		b2Vec2 gravity(sin(CC_DEGREES_TO_RADIANS(map.rotation)) * 15, -cos(CC_DEGREES_TO_RADIANS(map.rotation)) * 15);
		world->SetGravity(gravity);
	}
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	if (touch)
	{
		// Determine whether to do intertial rotation here
		/*
		// Get window size
		CGSize windowSize = [CCDirector sharedDirector].windowSize;

		// Convert location
		CGPoint touchPoint = [touch locationInView:[touch view]];

		previousAngle = currentAngle;

		currentAngle = CC_RADIANS_TO_DEGREES(atan2(windowSize.width / 2 - touchPoint.x, windowSize.height / 2 - touchPoint.y));

		if (currentAngle < 0) currentAngle += 360;

		float difference = currentAngle - previousAngle;
		*/
		// If map was rotating fast enough when the player lifted their finger, schedule a function that continues to rotate but slows down over time
		//[self schedule:@selector(inertialRotation:)];
	}
}

- (void)inertialRotation:(ccTime)dt
{
	// Current idea w/ inertial rotation is to modify the decelleration so that it takes place over a constant time; i.e. 1s
	// That way the effect doesn't become too disorienting
	// Plus the effect will only fire if the previousAngle vs. currentAngle value is above a certain amount
	
	float inertialDeccelleration = 0.1;
	
	//previousAngle = currentAngle;
	
	if (currentAngle > previousAngle)
		currentAngle -= inertialDeccelleration;
	else
		currentAngle += inertialDeccelleration;
	
	float difference = currentAngle - previousAngle;
	NSLog(@"Difference: %f, %f", currentAngle, previousAngle);
	
	// Change rotation of map
	map.rotation -= difference;
	
	b2Vec2 gravity(sin(CC_DEGREES_TO_RADIANS(map.rotation)) * 15, -cos(CC_DEGREES_TO_RADIANS(map.rotation)) * 15);
	world->SetGravity(gravity);
	
	if (abs(difference) <= inertialDeccelleration)
		[self unschedule:@selector(inertialRotation:)];
}

- (void)blockHubEntrances
{
	// Check player progress here - probably by checking to see if a particular level has a "best time"
	NSMutableArray *levelData = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelData"]];
	Boolean block = NO;
	Boolean showArrow = YES;
	
	// Check to see whether all levels are complete
	for (int i = 30; i < 40; i++)
	{
		NSDictionary *d = [levelData objectAtIndex:i];
		if (![[d objectForKey:@"complete"] boolValue])
			block = YES;
	}
	
	// This condition signifies that all levels are complete - show arrows pointing to all "worlds"
	if (block == NO)
	{
		[border setTileGID:kLeftArrow at:ccp(46, 50)];
		[border setTileGID:kDownArrow at:ccp(50, 54)];
		[border setTileGID:kRightArrow at:ccp(54, 50)];
		[border setTileGID:kUpArrow at:ccp(50, 46)];
		showArrow = NO;
	}
	
	block = NO;
	
	// Block Cave world
	for (int i = 20; i < 30; i++)
	{
		NSDictionary *d = [levelData objectAtIndex:i];
		if (![[d objectForKey:@"complete"] boolValue])
			block = YES;
	}
	
	// Block the entrance if player hasn't made it that far yet
	if (block)
	{
		[border setTileGID:kPeg at:ccp(49, 46)];
		[border setTileGID:kPeg at:ccp(50, 46)];
		[border setTileGID:kPeg at:ccp(51, 46)];
	}
	// Otherwise, show an arrow to indicate where the player should go next
	else if (showArrow)
	{
		[border setTileGID:kUpArrow at:ccp(50, 46)];
		showArrow = NO;
	}
	
	block = NO;
	
	// Block Mountain world
	for (int i = 10; i < 20; i++)
	{
		NSDictionary *d = [levelData objectAtIndex:i];
		if (![[d objectForKey:@"complete"] boolValue])
			block = YES;
	}
	
	if (block)
	{
		[border setTileGID:kPeg at:ccp(54, 49)];
		[border setTileGID:kPeg at:ccp(54, 50)];
		[border setTileGID:kPeg at:ccp(54, 51)];
	}
	// Otherwise, show an arrow to indicate where the player should go next
	else if (showArrow)
	{
		[border setTileGID:kRightArrow at:ccp(54, 50)];
		showArrow = NO;
	}
	
	block = NO;
	
	// Block Forest world
	for (int i = 0; i < 10; i++)
	{
		NSDictionary *d = [levelData objectAtIndex:i];
		if (![[d objectForKey:@"complete"] boolValue])
			block = YES;
	}
	
	if (block)
	{
		[border setTileGID:kPeg at:ccp(49, 54)];
		[border setTileGID:kPeg at:ccp(50, 54)];
		[border setTileGID:kPeg at:ccp(51, 54)];
	}
	// Otherwise, show an arrow to indicate where the player should go next
	else if (showArrow)
	{
		[border setTileGID:kDownArrow at:ccp(50, 54)];
		showArrow = NO;
	}
	
	// Finally, put an arrow pointing to the first world if no other progress has been made
	if (showArrow)
		[border setTileGID:kLeftArrow at:ccp(46, 50)];
}

- (void)retryButtonAction:(id)sender
{
	// Play SFX
	[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
	
	[pauseOverlay setVisible:NO];
	[map setVisible:NO];
	
	// Reload the same scene/level
	CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[GameLayer scene]];
	[[CCDirector sharedDirector] replaceScene:transition];
}

- (void)nextButtonAction:(id)sender
{
	// Play SFX
	[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
	
	[pauseOverlay setVisible:NO];
	[map setVisible:NO];
	
	// Increment level counter
	[GameSingleton sharedGameSingleton].currentLevel++;
	
	int levelsPerWorld = 10;
	int lastWorld = 4;
	CCTransitionRotoZoom *transition;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// If the player has finished the game
	if ([GameSingleton sharedGameSingleton].currentLevel > levelsPerWorld && [GameSingleton sharedGameSingleton].currentWorld == lastWorld && [defaults boolForKey:@"completedGame"] == NO)
	{
		// Set "completed game" boolean
		[defaults setBool:YES forKey:@"completedGame"];
		[defaults synchronize];
		
		// Transition to "credits" scene
		transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[CreditsLayer scene]];
	}
	// If player has just completed the 10th level in a world, take them back to the world select
	else if ([GameSingleton sharedGameSingleton].currentLevel > levelsPerWorld)
	{
		// This signifies the world select "level"
		[GameSingleton sharedGameSingleton].currentWorld = 0;
		[GameSingleton sharedGameSingleton].currentLevel = 0;
		
		transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[GameLayer scene]];
	}
	// Otherwise just go back to level select
	else
	{
		transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[LevelSelectLayer node]];
	}
	
	[[CCDirector sharedDirector] replaceScene:transition];
}

- (void)backButtonAction:(id)sender
{
	// Play SFX
	[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];
	
	[pauseOverlay setVisible:NO];
	[map setVisible:NO];
	
	// Stop the background music, if playing
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	
	// Load the level select screen
	CCTransitionRotoZoom *transition = [CCTransitionRotoZoom transitionWithDuration:1.0 scene:[LevelSelectLayer node]];
	[[CCDirector sharedDirector] replaceScene:transition];
}

- (void)pauseButtonAction:(id)sender
{
	// Play SFX
	[[SimpleAudioEngine sharedEngine] playEffect:@"button-press.caf"];

	if (paused)
	{
		// Schedule regular game loop
		[self schedule:@selector(update:)];
		
		// Schedule timer method for 1 second intervals
		[self schedule:@selector(timer:) interval:1];
		paused = NO;
		
		// Hide pause overlay
		id action = [CCEaseBounce actionWithAction:[CCMoveTo actionWithDuration:0.1 position:ccp(windowSize.width / 2, windowSize.height + pauseOverlay.contentSize.height / 2)]];
		[pauseOverlay runAction:action];
	}
	else 
	{
		// Unschedule the game loop & timer methods
		[self unschedule:@selector(update:)];
		[self unschedule:@selector(timer:)];
		paused = YES;
		
		// Show pause overlay
		[pauseOverlay setVisible:YES];
		id action = [CCEaseBounce actionWithAction:[CCMoveTo actionWithDuration:0.1 position:ccp(windowSize.width / 2, windowSize.height / 2)]];
		[pauseOverlay runAction:action];
	}
}

/**
 Init a particle emitter for destroyed blocks
 */
- (void)createParticleEmitterAt:(CGPoint)position
{
	// Create quad particle system (faster on 3rd gen & higher devices, only slightly slower on 1st/2nd gen)
	CCParticleSystemQuad *particleSystem = [[CCParticleSystemQuad alloc] initWithTotalParticles:4];
	
	// duration is for the emitter
	[particleSystem setDuration:0.10f];
	
	[particleSystem setEmitterMode:kCCParticleModeGravity];
	
	// Gravity Mode: gravity
	[particleSystem setGravity:ccp(sin(CC_DEGREES_TO_RADIANS(map.rotation)) * 15, -cos(CC_DEGREES_TO_RADIANS(map.rotation)) * 15)];
	
	// Gravity Mode: speed of particles
	[particleSystem setSpeed:60];
	[particleSystem setSpeedVar:0];
	
	// Gravity Mode: radial
	[particleSystem setRadialAccel:0];
	[particleSystem setRadialAccelVar:0];
	
	// Gravity Mode: tagential
	[particleSystem setTangentialAccel:0];
	[particleSystem setTangentialAccelVar:0];
	
	// angle
	[particleSystem setAngle:map.rotation - 90];
	[particleSystem setAngleVar:90];
	
	// emitter position
	[particleSystem setPosition:position];
	[particleSystem setPosVar:CGPointZero];
	
	// life is for particles particles - in seconds
	[particleSystem setLife:0.35f];
	[particleSystem setLifeVar:0];
	
	// size, in pixels
	[particleSystem setStartSize:16.0f];
	[particleSystem setStartSizeVar:0.0f];
	[particleSystem setEndSize:kCCParticleStartSizeEqualToEndSize];
	
	// emits per second
	[particleSystem setEmissionRate:[particleSystem totalParticles] / [particleSystem duration]];
	
	// color of particles
	ccColor4F startColor = {1.0f, 1.0f, 1.0f, 1.0f};
	ccColor4F endColor = {1.0f, 1.0f, 1.0f, 1.0f};
	[particleSystem setStartColor:startColor];
	[particleSystem setEndColor:endColor];
	
	// Set the texture!
	[particleSystem setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"world-%i-breakable-shard%@.png", [GameSingleton sharedGameSingleton].currentWorld, hdSuffix]]];
	
	// additive
	[particleSystem setBlendAdditive:NO];
	
	// Auto-remove the emitter when it is done!
	[particleSystem setAutoRemoveOnFinish:YES];
	
	// Add to layer
	[map addChild:particleSystem z:3];
	
	//NSLog(@"Tryin' to make a particle emitter at %f, %f with gravity %f, %f", position.x, position.y, sin(CC_DEGREES_TO_RADIANS(map.rotation)) * 15, -cos(CC_DEGREES_TO_RADIANS(map.rotation)) * 15);
}

- (void)removeSpriteFromParent:(CCNode *)sprite
{
	//[sprite.parent removeChild:sprite cleanup:YES];
	
	// Trying this from forum post http://www.cocos2d-iphone.org/forum/topic/981#post-5895
	// Apparently fixes a memory error?
	CCNode *parent = sprite.parent;
	[sprite retain];
	[parent removeChild:sprite cleanup:YES];
	[sprite autorelease];
}

- (void)dealloc
{
	delete world;
	delete contactListener;
	world = NULL;
	contactListener = NULL;
	[border release];
	[super dealloc];
}

@end