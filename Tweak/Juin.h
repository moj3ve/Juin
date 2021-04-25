#import <UIKit/UIKit.h>
#import <MediaRemote/MediaRemote.h>
#import <CoreText/CoreText.h>
#import <AVFoundation/AVFoundation.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
@import RocketBootstrap
#import "MarqueeLabel.h"
#import <Cephei/HBPreferences.h>

HBPreferences* preferences = nil;

BOOL enabled = NO;

BOOL firstTimeLoaded = NO;
BOOL playing = NO;
BOOL paused = NO;
UIImageView* backgroundArtwork = nil;
UIVisualEffectView* blurView = nil;
UIBlurEffect* blur = nil;
UIImage* currentArtwork = nil;
UIView* backgroundGradient = nil;
CAGradientLayer* gradient = nil;
UILabel* sourceLabel = nil;
UIButton* playPauseButton = nil;
UIButton* rewindButton = nil;
UIButton* skipButton = nil;
UILabel* artistLabel = nil;
UILabel* songLabel = nil;
UIView* gestureView = nil;
UITapGestureRecognizer* tap = nil;
UISwipeGestureRecognizer* leftSwipe = nil;
UISwipeGestureRecognizer* rightSwipe = nil;
AVQueuePlayer* canvasPlayer = nil;
AVPlayerItem* canvasPlayerItem = nil;
AVPlayerLooper* canvasPlayerLooper = nil;
AVPlayerLayer* canvasPlayerLayer = nil;

// style
NSString* styleValue = @"0";

// background
BOOL canvasSwitch = NO;
BOOL backgroundArtworkSwitch = YES;
BOOL addBlurSwitch = NO;
NSString* blurModeValue = @"2";
NSString* blurAmountValue = @"1.0";

// gestures
BOOL leftSwipeSwitch = YES;
BOOL rightSwipeSwitch = YES;

// miscellaneous
NSString* newOffsetValue = @"0";
BOOL showDeviceNameSwitch = YES;

@interface CSCoverSheetViewController : UIViewController
- (void)updateCanvasPlayer;
- (void)hideJuinViewNotification;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
- (BOOL)isLockScreenVisible;
@end

@interface SPTVideoPlayerSource : NSObject
@end

@interface AVPlayerItem (Juin)
- (id)_URL;
@end

@interface CSCoverSheetView : UIView
@property(nonatomic, retain)UIView* juinView;
- (void)rewindSong;
- (void)skipSong;
- (void)pausePlaySong;
- (void)hideJuinView;
- (void)handleSwipe:(UISwipeGestureRecognizer *)sender;
@end

@interface MediaControlsTimeControl : UIControl
- (id)_viewControllerForAncestor;
@end

@interface MRPlatterViewController : UIViewController
@property(assign, nonatomic)id delegate;
@end

@interface MRUNowPlayingTimeControlsView : UIView
- (id)_viewControllerForAncestor;
@end

@interface MRUNowPlayingViewController : UIViewController
@property(assign, nonatomic)id delegate;
@end

@interface CSMediaControlsViewController : UIViewController
@end

@interface CSAdjunctItemView : UIView
@end

@interface NCNotificationListView : UIView
@end

@interface CSNotificationAdjunctListViewController : UIViewController
@end

@interface CSQuickActionsButton : UIControl
- (void)receiveFadeNotification:(NSNotification *)notification;
@end

@interface CSPageControl : UIPageControl
- (void)receiveFadeNotification:(NSNotification *)notification;
@end

@interface SBUILegibilityLabel : UILabel
@end

@interface SBUICallToActionLabel : UILabel
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (void)setNowPlayingInfo:(id)arg1;
- (BOOL)isPlaying;
- (BOOL)isPaused;
- (BOOL)changeTrack:(int)arg1 eventSource:(long long)arg2;
- (BOOL)togglePlayPauseForEventSource:(long long)arg1;
@end