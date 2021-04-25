#import "Juin.h"

MediaControlsTimeControl* timeSlider = nil;
MRUNowPlayingTimeControlsView* newTimeSlider = nil;
CSCoverSheetView* coversheetView = nil;

static CPDistributedMessagingCenter* center = nil;

@interface JuinServer : NSObject
@property(nonatomic, strong)NSString* receivedURL;
@end

@implementation JuinServer

+ (void)load {

	[self sharedInstance];

}

+ (id)sharedInstance {

	static dispatch_once_t once = 0;
	__strong static id sharedInstance = nil;
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;

}

- (id)init {

	if ((self = [super init])) {
		CPDistributedMessagingCenter* messagingCenter = [CPDistributedMessagingCenter centerNamed:@"love.litten.juinserver"];
		rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
		[messagingCenter runServerOnCurrentThread];

		[messagingCenter registerForMessageName:@"getCanvasURL" target:self selector:@selector(returnCanvasURL:withUserInfo:)];
	}

	return self;

}

- (NSString *)returnCanvasURL:(NSString *)name withUserInfo:(NSDictionary *)userInfo {

	NSString* canvasURL = userInfo[@"url"];
	self.receivedURL = canvasURL;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"juinUpdateCanvasPlayer" object:nil];

	return canvasURL;

}

@end

%group JuinCanvas

%hook SPTVideoPlayerSource

- (void)loadPlayerItem:(id)arg1 { // get canvas url from player item

	%orig;

	NSString* canvasURL = [NSString stringWithFormat:@"%@", [arg1 _URL]];

	if (canvasURL) {
		NSDictionary* userInfo = @{@"url":canvasURL};
		[center sendMessageName:@"getCanvasURL" userInfo:userInfo];
	}

}

%end

%hook CSCoverSheetViewController

- (void)viewDidLoad { // add notification obvserver

	%orig;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCanvasPlayer) name:@"juinUpdateCanvasPlayer" object:nil];

}

- (void)viewWillAppear:(BOOL)animated { // update canvas player with received url when lockscreen appears

	%orig;

	if (!playing && !paused) return;
	[self updateCanvasPlayer];

}

- (void)viewWillDisappear:(BOOL)animated { // pause canvas when lockscreen disappears

	%orig;

	if (!playing && !paused) return;
	[canvasPlayer pause];

}

%new
- (void)updateCanvasPlayer { // set canvas player

	if (!playing && !paused) return;
	NSURL* url = [NSURL URLWithString:[[JuinServer sharedInstance] receivedURL]];

	if (!url) {
		[canvasPlayerLayer removeFromSuperlayer];
		[canvasPlayer pause];
		canvasPlayer = nil;
		canvasPlayerItem = nil;
		canvasPlayerLooper = nil;
		canvasPlayerLayer = nil;
		return;
	}
	
	[canvasPlayerLayer removeFromSuperlayer];
	[canvasPlayer pause];
	canvasPlayer = nil;
	canvasPlayerItem = nil;
	canvasPlayerLooper = nil;
	canvasPlayerLayer = nil;


	canvasPlayerItem = [AVPlayerItem playerItemWithURL:url];

    canvasPlayer = [AVQueuePlayer playerWithPlayerItem:canvasPlayerItem];
    [canvasPlayer setMuted:YES];
	[canvasPlayer setPreventsDisplaySleepDuringVideoPlayback:NO];
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

	canvasPlayerLooper = [AVPlayerLooper playerLooperWithPlayer:canvasPlayer templateItem:canvasPlayerItem];

    canvasPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:canvasPlayer];
    [canvasPlayerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [canvasPlayerLayer setFrame:[[[self view] layer] bounds]];
    [[[self view] layer] insertSublayer:canvasPlayerLayer atIndex:0];

	[canvasPlayer play];

}

%end

%hook SBLockScreenManager

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 completion:(id)arg3 { // pause canvas player when locked

    %orig;

	if (!playing && !paused) return;
    [canvasPlayer pause];

}

%end

%hook SBBacklightController

- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1 { // resume canvas when screen turned on

	%orig;

	if (!playing && !paused) return;
    if (![[%c(SBLockScreenManager) sharedInstance] isLockScreenVisible]) return;
	[canvasPlayer play];

}

%end

%end

%group Juin

%hook CSCoverSheetView

%property(nonatomic, retain)UIView* juinView;

- (id)initWithFrame:(CGRect)frame { // get coversheetview instance

	id orig = %orig;
	coversheetView = self;

	return orig;

}

- (void)didMoveToWindow { // add juin

	%orig;

	if (firstTimeLoaded) return;
	firstTimeLoaded = YES;

	// load cirlularspui-book font
	NSData* inData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/JuinPrefs.bundle/CircularSpUI-Book.otf"]];
    CFErrorRef error;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
    CGFontRef font = CGFontCreateWithDataProvider(provider);
    if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
        CFStringRef errorDescription = CFErrorCopyDescription(error);
        CFRelease(errorDescription);
    }
    CFRelease(font);
    CFRelease(provider);

	// load cirlularspui-bold font
	if ([styleValue intValue] == 0) {
		NSData* inData2 = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/JuinPrefs.bundle/CircularSpUI-Bold.otf"]];
		CFErrorRef error2;
		CGDataProviderRef provider2 = CGDataProviderCreateWithCFData((CFDataRef)inData2);
		CGFontRef font2 = CGFontCreateWithDataProvider(provider2);
		if (!CTFontManagerRegisterGraphicsFont(font2, &error2)) {
			CFStringRef errorDescription = CFErrorCopyDescription(error2);
			CFRelease(errorDescription);
		}
		CFRelease(font2);
		CFRelease(provider2);
	} else if ([styleValue intValue] == 1) {
		NSData* inData2 = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/JuinPrefs.bundle/CircularSpUIm40-Bold.otf"]];
		CFErrorRef error2;
		CGDataProviderRef provider2 = CGDataProviderCreateWithCFData((CFDataRef)inData2);
		CGFontRef font2 = CGFontCreateWithDataProvider(provider2);
		if (!CTFontManagerRegisterGraphicsFont(font2, &error2)) {
			CFStringRef errorDescription = CFErrorCopyDescription(error2);
			CFRelease(errorDescription);
		}
		CFRelease(font2);
		CFRelease(provider2);
	}


	// juin view
	self.juinView = [[UIView alloc] initWithFrame:[self bounds]];
	[[self juinView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[[self juinView] setHidden:YES];
	[self addSubview:[self juinView]];


	// background artwork
	if (backgroundArtworkSwitch) {
		backgroundArtwork = [[UIImageView alloc] initWithFrame:[[self juinView] bounds]];
		[backgroundArtwork setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
		[backgroundArtwork setContentMode:UIViewContentModeScaleAspectFill];
		[backgroundArtwork setHidden:YES];
		[[self juinView] addSubview:backgroundArtwork];

		if (addBlurSwitch) {
			if ([blurModeValue intValue] == 0)
				blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
			else if ([blurModeValue intValue] == 1)
				blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			else if ([blurModeValue intValue] == 2)
				blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
			blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
			[blurView setFrame:[backgroundArtwork bounds]];
			[blurView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
			[blurView setAlpha:[blurAmountValue doubleValue]];
			[backgroundArtwork addSubview:blurView];
		}
	}


	// gradient
	gradient = [CAGradientLayer layer];
	[gradient setFrame:[[self juinView] bounds]];
	[gradient setColors:@[(id)[[UIColor clearColor] CGColor], (id)[[UIColor blackColor] CGColor]]];
	[[[self juinView] layer] addSublayer:gradient];


	if ([styleValue intValue] == 0) {
		// source button
		sourceLabel = [UILabel new];
		if (showDeviceNameSwitch) [sourceLabel setText:[NSString stringWithFormat:@"%@", [[UIDevice currentDevice] name]]];
		else [sourceLabel setText:@""];
		[sourceLabel setTextColor:[UIColor whiteColor]];
		[sourceLabel setFont:[UIFont fontWithName:@"CircularSpUI-Book" size:10]];
		[sourceLabel setTextAlignment:NSTextAlignmentCenter];
		[[self juinView] addSubview:sourceLabel];

		[sourceLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[sourceLabel.widthAnchor constraintEqualToConstant:self.juinView.bounds.size.width].active = YES;
		[sourceLabel.heightAnchor constraintEqualToConstant:24].active = YES;
		[sourceLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
		[sourceLabel.centerYAnchor constraintEqualToAnchor:self.bottomAnchor constant:-24 - [newOffsetValue intValue]].active = YES;


		// play/pause button
		playPauseButton = [UIButton new];
		[playPauseButton addTarget:self action:@selector(pausePlaySong) forControlEvents:UIControlEventTouchUpInside];
		[playPauseButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/paused-old.png"] forState:UIControlStateNormal];
		[[self juinView] addSubview:playPauseButton];

		[playPauseButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[playPauseButton.widthAnchor constraintEqualToConstant:72].active = YES;
		[playPauseButton.heightAnchor constraintEqualToConstant:72].active = YES;
		[playPauseButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
		[playPauseButton.centerYAnchor constraintEqualToAnchor:sourceLabel.topAnchor constant:-50].active = YES;


		// rewind button
		rewindButton = [UIButton new];
		[rewindButton addTarget:self action:@selector(rewindSong) forControlEvents:UIControlEventTouchUpInside];
		[rewindButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/rewind-old.png"] forState:UIControlStateNormal];
		[rewindButton setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
		[[self juinView] addSubview:rewindButton];

		[rewindButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[rewindButton.widthAnchor constraintEqualToConstant:34].active = YES;
		[rewindButton.heightAnchor constraintEqualToConstant:34].active = YES;
		[rewindButton.centerXAnchor constraintEqualToAnchor:playPauseButton.leftAnchor constant:-60].active = YES;
		[rewindButton.centerYAnchor constraintEqualToAnchor:sourceLabel.topAnchor constant:-50].active = YES;


		// skip button
		skipButton = [UIButton new];
		[skipButton addTarget:self action:@selector(skipSong) forControlEvents:UIControlEventTouchUpInside];
		[skipButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/skip-old.png"] forState:UIControlStateNormal];
		[skipButton setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
		[[self juinView] addSubview:skipButton];

		[skipButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[skipButton.widthAnchor constraintEqualToConstant:34].active = YES;
		[skipButton.heightAnchor constraintEqualToConstant:34].active = YES;
		[skipButton.centerXAnchor constraintEqualToAnchor:playPauseButton.rightAnchor constant:60].active = YES;
		[skipButton.centerYAnchor constraintEqualToAnchor:sourceLabel.topAnchor constant:-50].active = YES;


		// artist label
		artistLabel = [MarqueeLabel new];
		[artistLabel setText:@"Far Places"];
		[artistLabel setTextColor:[UIColor colorWithRed: 0.60 green: 0.60 blue: 0.60 alpha: 1.00]];
		[artistLabel setFont:[UIFont fontWithName:@"CircularSpUI-Bold" size:22]];
		[artistLabel setTextAlignment:NSTextAlignmentCenter];
		[[self juinView] addSubview:artistLabel];

		[artistLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[artistLabel.widthAnchor constraintEqualToConstant:279].active = YES;
		[artistLabel.heightAnchor constraintEqualToConstant:31].active = YES;
		[artistLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
		[artistLabel.centerYAnchor constraintEqualToAnchor:playPauseButton.topAnchor constant:-60].active = YES;


		// song label
		songLabel = [MarqueeLabel new];
		[songLabel setText:@"In My Head"];
		[songLabel setTextColor:[UIColor whiteColor]];
		[songLabel setFont:[UIFont fontWithName:@"CircularSpUI-Bold" size:36]];
		[songLabel setTextAlignment:NSTextAlignmentCenter];
		[[self juinView] addSubview:songLabel];

		[songLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[songLabel.widthAnchor constraintEqualToConstant:279].active = YES;
		[songLabel.heightAnchor constraintEqualToConstant:51].active = YES;
		[songLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
		[songLabel.centerYAnchor constraintEqualToAnchor:artistLabel.topAnchor constant:-24].active = YES;
	} else if ([styleValue intValue] == 1) {
		// source button
		sourceLabel = [UILabel new];
		if (showDeviceNameSwitch) [sourceLabel setText:[NSString stringWithFormat:@"%@", [[UIDevice currentDevice] name]]];
		else [sourceLabel setText:@""];
		[sourceLabel setTextColor:[UIColor whiteColor]];
		[sourceLabel setFont:[UIFont fontWithName:@"CircularSpUI-Book" size:10]];
		[sourceLabel setTextAlignment:NSTextAlignmentLeft];
		[[self juinView] addSubview:sourceLabel];

		[sourceLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[sourceLabel.widthAnchor constraintEqualToConstant:self.juinView.bounds.size.width].active = YES;
		[sourceLabel.heightAnchor constraintEqualToConstant:24].active = YES;
		[sourceLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:26].active = YES;
		[sourceLabel.centerYAnchor constraintEqualToAnchor:self.bottomAnchor constant:-80 - [newOffsetValue intValue]].active = YES;


		// play/pause button
		playPauseButton = [UIButton new];
		[playPauseButton addTarget:self action:@selector(pausePlaySong) forControlEvents:UIControlEventTouchUpInside];
		[playPauseButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/paused-new.png"] forState:UIControlStateNormal];
		[[self juinView] addSubview:playPauseButton];

		[playPauseButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[playPauseButton.widthAnchor constraintEqualToConstant:64].active = YES;
		[playPauseButton.heightAnchor constraintEqualToConstant:64].active = YES;
		[playPauseButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
		[playPauseButton.centerYAnchor constraintEqualToAnchor:sourceLabel.topAnchor constant:-60].active = YES;


		// rewind button
		rewindButton = [UIButton new];
		[rewindButton addTarget:self action:@selector(rewindSong) forControlEvents:UIControlEventTouchUpInside];
		[rewindButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/rewind-new.png"] forState:UIControlStateNormal];
		[[self juinView] addSubview:rewindButton];

		[rewindButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[rewindButton.widthAnchor constraintEqualToConstant:36].active = YES;
		[rewindButton.heightAnchor constraintEqualToConstant:36].active = YES;
		[rewindButton.centerXAnchor constraintEqualToAnchor:playPauseButton.leftAnchor constant:-55].active = YES;
		[rewindButton.centerYAnchor constraintEqualToAnchor:sourceLabel.topAnchor constant:-60].active = YES;


		// skip button
		skipButton = [UIButton new];
		[skipButton addTarget:self action:@selector(skipSong) forControlEvents:UIControlEventTouchUpInside];
		[skipButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/skip-new.png"] forState:UIControlStateNormal];
		[[self juinView] addSubview:skipButton];

		[skipButton setTranslatesAutoresizingMaskIntoConstraints:NO];
		[skipButton.widthAnchor constraintEqualToConstant:36].active = YES;
		[skipButton.heightAnchor constraintEqualToConstant:36].active = YES;
		[skipButton.centerXAnchor constraintEqualToAnchor:playPauseButton.rightAnchor constant:55].active = YES;
		[skipButton.centerYAnchor constraintEqualToAnchor:sourceLabel.topAnchor constant:-60].active = YES;


		// artist label
		if (!artistLabel) artistLabel = [MarqueeLabel new];
		[artistLabel setText:@"Far Places"];
		[artistLabel setTextColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7]];
		[artistLabel setFont:[UIFont fontWithName:@"CircularSpUI-Book" size:16]];
		[artistLabel setTextAlignment:NSTextAlignmentLeft];
		[[self juinView] addSubview:artistLabel];

		[artistLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[artistLabel.widthAnchor constraintEqualToConstant:self.juinView.bounds.size.width].active = YES;
		[artistLabel.heightAnchor constraintEqualToConstant:31].active = YES;
		[artistLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:27].active = YES;
		[artistLabel.centerYAnchor constraintEqualToAnchor:playPauseButton.topAnchor constant:-65].active = YES;


		// song label
		songLabel = [MarqueeLabel new];
		[songLabel setText:@"In My Head"];
		[songLabel setTextColor:[UIColor whiteColor]];
		[songLabel setFont:[UIFont fontWithName:@"CircularSpUIm40-Bold" size:24]];
		[songLabel setTextAlignment:NSTextAlignmentLeft];
		[[self juinView] addSubview:songLabel];

		[songLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		[songLabel.widthAnchor constraintEqualToConstant:self.juinView.bounds.size.width].active = YES;
		[songLabel.heightAnchor constraintEqualToConstant:51].active = YES;
		[songLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:26].active = YES;
		[songLabel.centerYAnchor constraintEqualToAnchor:artistLabel.topAnchor constant:-12].active = YES;
	}


	// gesture view
	if ([styleValue intValue] == 0)
		gestureView = [[UIView alloc] initWithFrame:CGRectMake(self.juinView.bounds.origin.x, self.juinView.bounds.origin.y, self.juinView.bounds.size.width, self.juinView.bounds.size.height / 1.3 - [newOffsetValue intValue])];
	else if ([styleValue intValue] == 1)
		gestureView = [[UIView alloc] initWithFrame:CGRectMake(self.juinView.bounds.origin.x, self.juinView.bounds.origin.y, self.juinView.bounds.size.width, self.juinView.bounds.size.height / 1.5 - [newOffsetValue intValue])];
	[gestureView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[gestureView setBackgroundColor:[UIColor clearColor]];
	[[self juinView] addSubview:gestureView];

	
	// tap gesture
	tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideJuinView)];
	[tap setNumberOfTapsRequired:1];
	[tap setNumberOfTouchesRequired:1];
	[gestureView addGestureRecognizer:tap];


	// swipe gestures
	if (leftSwipeSwitch) {
		leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
		[leftSwipe setDirection:UISwipeGestureRecognizerDirectionLeft];
		[gestureView addGestureRecognizer:leftSwipe];
	}

	if (rightSwipeSwitch) {
		rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
		[rightSwipe setDirection:UISwipeGestureRecognizerDirectionRight];
		[gestureView addGestureRecognizer:rightSwipe];
	}

}

- (void)layoutSubviews { // add time slider

	%orig;

	if ([styleValue intValue] == 0) {
		// ios < 14.2
		[timeSlider setTranslatesAutoresizingMaskIntoConstraints:NO];
		[timeSlider.widthAnchor constraintEqualToConstant:self.juinView.bounds.size.width -32].active = YES;
		[timeSlider.heightAnchor constraintEqualToConstant:49].active = YES;
		[[self juinView] addSubview:timeSlider];
		[timeSlider.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
		[timeSlider.centerYAnchor constraintEqualToAnchor:playPauseButton.topAnchor constant:-24].active = YES;

		// ios >= 14.2 (position managed in the MRUNowPlayingTimeControlsView hook)
		[[self juinView] addSubview:newTimeSlider];
	}
	else if ([styleValue intValue] == 1) {
		// ios < 14.2
		[timeSlider setTranslatesAutoresizingMaskIntoConstraints:NO];
		[timeSlider.widthAnchor constraintEqualToConstant:self.juinView.bounds.size.width -50].active = YES;
		[timeSlider.heightAnchor constraintEqualToConstant:49].active = YES;
		[[self juinView] addSubview:timeSlider];
		[timeSlider.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
		[timeSlider.centerYAnchor constraintEqualToAnchor:playPauseButton.topAnchor constant:-35].active = YES;

		// ios >= 14.2 (position managed in the MRUNowPlayingTimeControlsView hook)
		[[self juinView] addSubview:newTimeSlider];
	}

}

%new
- (void)rewindSong { // rewind song

	[[%c(SBMediaController) sharedInstance] changeTrack:-1 eventSource:0];

}

%new
- (void)skipSong { // skip song

	[[%c(SBMediaController) sharedInstance] changeTrack:1 eventSource:0];

}

%new
- (void)pausePlaySong { // pause/play song

	[[%c(SBMediaController) sharedInstance] togglePlayPauseForEventSource:0];

}

%new
- (void)hideJuinView { // hide juin

	if ([[self juinView] isHidden]) return;
	if (!playing && !paused) return;

	[UIView transitionWithView:[self juinView] duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
		[[self juinView] setHidden:YES];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"juinUnhideElements" object:nil];
	} completion:nil];

}

%new
- (void)handleSwipe:(UISwipeGestureRecognizer *)sender { // rewind/skip song based on swipe direction

	if (sender.direction == UISwipeGestureRecognizerDirectionLeft)
		[self skipSong];
	else if (sender.direction == UISwipeGestureRecognizerDirectionRight)
		[self rewindSong];

}

%end

%hook NCNotificationListView

- (void)touchesBegan:(id)arg1 withEvent:(id)arg2 { // unhide juin on tap

	%orig;

	if (![[coversheetView juinView] isHidden]) return;
	if (!playing && !paused) return;

	[UIView transitionWithView:[coversheetView juinView] duration:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
		[[coversheetView juinView] setHidden:NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"juinHideElements" object:nil];
	} completion:nil];

}

%end

%hook MediaControlsTimeControl

- (void)layoutSubviews { // get a time slider instance

	%orig;

	MRPlatterViewController* controller = (MRPlatterViewController *)[self _viewControllerForAncestor];
  	if ([controller respondsToSelector:@selector(delegate)] && [[controller delegate] isKindOfClass:%c(CSMediaControlsViewController)])
    	timeSlider = self;

}

%end

%hook MRUNowPlayingTimeControlsView

- (void)layoutSubviews { // get a time slider instance

	%orig;

	MRUNowPlayingViewController* controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
	if ([controller respondsToSelector:@selector(delegate)] && ![controller.delegate isKindOfClass:%c(MRUControlCenterViewController)])
		newTimeSlider = self;

}

- (void)setFrame:(CGRect)frame { // set position of the new time slider

	if ([styleValue intValue] == 0) {
		MRUNowPlayingViewController* controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
		if ([controller respondsToSelector:@selector(delegate)] && [controller.delegate isKindOfClass:%c(MRUControlCenterViewController)])
			%orig;
		else
			%orig(CGRectMake(coversheetView.frame.size.width / 2 - frame.size.width / 2, artistLabel.frame.origin.y + 28, frame.size.width, frame.size.height));
	} else if ([styleValue intValue ] == 1) {
		MRUNowPlayingViewController* controller = (MRUNowPlayingViewController *)[self _viewControllerForAncestor];
		if ([controller respondsToSelector:@selector(delegate)] && [controller.delegate isKindOfClass:%c(MRUControlCenterViewController)])
			%orig;
		else
			%orig(CGRectMake(coversheetView.frame.size.width / 2 - frame.size.width / 2, artistLabel.frame.origin.y + 21, frame.size.width, frame.size.height));
	}

}

%end

%hook CSAdjunctItemView

- (void)_updateSizeToMimic { // hide original player

	%orig;

	[self.heightAnchor constraintEqualToConstant:0].active = true;
	[self setHidden:YES];

}

%end

%hook CSNotificationAdjunctListViewController

- (void)viewDidLoad { // make the time slider bright by forcing dark mode on the original player

	%orig;

    [self setOverrideUserInterfaceStyle:2];

}

%end

%end

%group JuinHiding

%hook CSQuickActionsButton

- (id)initWithFrame:(CGRect)frame { // add notification observer

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveFadeNotification:) name:@"juinHideElements" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveFadeNotification:) name:@"juinUnhideElements" object:nil];

	return %orig;

}

%new
- (void)receiveFadeNotification:(NSNotification *)notification { // hide or unhide quick action buttons

	if ([notification.name isEqual:@"juinHideElements"]) {
		[UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:0.0];
		} completion:nil];
	} else if ([notification.name isEqual:@"juinUnhideElements"]) {
		[UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self setAlpha:1.0];
		} completion:nil];
	}

}

%end

%hook CSTeachableMomentsContainerView

- (void)_layoutCallToActionLabel { // hide unlock text on homebar devices when playing
	
	%orig;

	SBUILegibilityLabel* label = MSHookIvar<SBUILegibilityLabel *>(self, "_callToActionLabel");

	if ([[coversheetView juinView] isHidden]) {
		[label setHidden:NO];
		return;
	}

	[label setHidden:YES];	

}

%end

%hook SBUICallToActionLabel

- (void)didMoveToWindow { // hide unlock text on home button devices when playing

	%orig;

	if ([[coversheetView juinView] isHidden]) {
		[self setHidden:NO];
		return;
	}

	[self setHidden:YES];

}

- (void)_updateLabelTextWithLanguage:(id)arg1 { // hide unlock text on home button devices when playing

	%orig;

	if ([[coversheetView juinView] isHidden]) {
		[self setHidden:NO];
		return;
	}

	[self setHidden:YES];

}

%end

%end

%group JuinData

%hook SBMediaController

- (void)setNowPlayingInfo:(id)arg1 { // set now playing info

    %orig;

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        if (information) {
            NSDictionary* dict = (__bridge NSDictionary *)information;

            if (dict) {
				// set artwork
                if (dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData]) {
					[UIView transitionWithView:backgroundArtwork duration:0.15 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
						[backgroundArtwork setImage:[UIImage imageWithData:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]]];
					} completion:nil];
				}

				// set song title
				if (dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle]) [songLabel setText:[NSString stringWithFormat:@"%@ ", [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoTitle]]];
				else [songLabel setText:@"N/A"];
				
				// set artist
				if (dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist]) [artistLabel setText:[NSString stringWithFormat:@"%@ ", [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtist]]];
				else [artistLabel setText:@"N/A"];
				
				// unhide juin
				if (backgroundArtworkSwitch) [backgroundArtwork setHidden:NO];
                [[coversheetView juinView] setHidden:NO];

				[[NSNotificationCenter defaultCenter] postNotificationName:@"juinHideElements" object:nil];
            }
        } else { // hide juin if not playing
			if (backgroundArtworkSwitch) [backgroundArtwork setHidden:YES];
            [[coversheetView juinView] setHidden:YES];
			if (canvasSwitch) {
				[canvasPlayerLayer removeFromSuperlayer];
				[canvasPlayer pause];
			} 

			[[NSNotificationCenter defaultCenter] postNotificationName:@"juinUnhideElements" object:nil];
        }
  	});
    
}

- (void)_mediaRemoteNowPlayingApplicationIsPlayingDidChange:(id)arg1 { // get play/pause state change

    %orig;

	if ([styleValue intValue] == 0) {
		if ([self isPlaying])
			[playPauseButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/playing-old.png"] forState:UIControlStateNormal];
		else
			[playPauseButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/paused-old.png"] forState:UIControlStateNormal];
	} else if ([styleValue intValue] == 1) {
		if ([self isPlaying])
			[playPauseButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/playing-new.png"] forState:UIControlStateNormal];
		else
			[playPauseButton setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/JuinPrefs.bundle/paused-new.png"] forState:UIControlStateNormal];
	}

}

- (BOOL)isPlaying { // notice when playing

	playing = %orig;

	return playing;

}

- (BOOL)isPaused { // notice when paused

	paused = %orig;

	return paused;

}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 { // reload data after a respring

    %orig;

    [[%c(SBMediaController) sharedInstance] setNowPlayingInfo:0];
    
}

%end

%end

%ctor {

	preferences = [[HBPreferences alloc] initWithIdentifier:@"love.litten.juinpreferences"];

	[preferences registerBool:&enabled default:nil forKey:@"Enabled"];
	if (!enabled) return;

	// style
	[preferences registerObject:&styleValue default:@"0" forKey:@"style"];

	// background artwork
	[preferences registerBool:&canvasSwitch default:NO forKey:@"canvas"];
	[preferences registerBool:&backgroundArtworkSwitch default:YES forKey:@"backgroundArtwork"];
	if (backgroundArtworkSwitch) {
		[preferences registerBool:&addBlurSwitch default:NO forKey:@"addBlur"];
		[preferences registerObject:&blurModeValue default:@"2" forKey:@"blurMode"];
		[preferences registerObject:&blurAmountValue default:@"1.0" forKey:@"blurAmount"];
	}

	// gestures
	[preferences registerBool:&leftSwipeSwitch default:YES forKey:@"leftSwipe"];
	[preferences registerBool:&rightSwipeSwitch default:YES forKey:@"rightSwipe"];

	// miscellaneous
	[preferences registerObject:&newOffsetValue default:@"0" forKey:@"newOffset"];
	[preferences registerBool:&showDeviceNameSwitch default:YES forKey:@"showDeviceName"];
	
	%init(Juin);
	%init(JuinData);
	%init(JuinHiding);
	if (canvasSwitch) {
		%init(JuinCanvas);
		center = [CPDistributedMessagingCenter centerNamed:@"love.litten.juinserver"];
		rocketbootstrap_distributedmessagingcenter_apply(center);
		[JuinServer load];
	}

}