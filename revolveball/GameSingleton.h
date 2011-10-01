//
//  GameSingleton.h
//  Revolve Ball
//
//  Created by Nathan Demick on 9/29/11.
//  Copyright 2011 Ganbaru Games. All rights reserved.
//

// Serializes certain game variables on exit then restores them on game load
// Taken from http://stackoverflow.com/questions/2670815/game-state-singleton-cocos2d-initwithencoder-always-returns-null

#import "cocos2d.h"
#import "SynthesizeSingleton.h"
#import <GameKit/GameKit.h>

@interface GameSingleton : NSObject <NSCoding, GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate> 
{
	// Boolean that's set to "true" if game is running on iPad!
	BOOL isPad;
	
	// Boolean that's set to "true" if Retina display (iPhone4)
	BOOL isRetina;
	
	// Stores the user-selected level
	int currentWorld, currentLevel;
	
	// Game Center properties
	BOOL hasGameCenter;
	
	// Store unsent Game Center data
	NSMutableArray *unsentScores;
	NSMutableArray *unsentAchievements;
	
	// Store saved Game Center achievement progress
	NSMutableDictionary *achievementsDictionary;
	
	// Used to attach Game Center overlays
	UIViewController *myViewController;
}

@property BOOL isPad;
@property BOOL isRetina;

@property int currentWorld;
@property int currentLevel;

@property BOOL hasGameCenter;
@property (nonatomic, retain) NSMutableArray *unsentScores;
@property (nonatomic, retain) NSMutableArray *unsentAchievements;
@property (nonatomic, retain) NSMutableDictionary *achievementsDictionary;

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(GameSingleton);

// Game Center methods
- (BOOL)isGameCenterAPIAvailable;
- (void)authenticateLocalPlayer;

// Leaderboards
- (void)reportScore:(int64_t)score forCategory:(NSString *)category;
- (void)showLeaderboardForCategory:(NSString *)category;
- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController;

// Achievements
- (GKAchievement *)getAchievementForIdentifier:(NSString *)identifier;
- (void)reportAchievementIdentifier:(NSString *)identifier percentComplete:(float)percent;
- (void)reportAchievementIdentifier:(NSString *)identifier incrementPercentComplete:(float)percent;
- (void)showAchievements;
- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController;

// Serialization methods
+ (void)loadState;
+ (void)saveState;

@end
