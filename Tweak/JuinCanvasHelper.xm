#import "JuinCanvasHelper.h"

%group JuinCanvasHelper

%hook MPNowPlayingInfoCenter

- (void)setNowPlayingInfo:(id)arg1 {
	
	%orig;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateCanvas" object:nil];
    });

}

%end

%hook SPTCanvasContentLayerViewController

- (id)init {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCanvasOnRequest) name:@"updateCanvas" object:nil];

    return %orig;

}

%new
- (void)updateCanvasOnRequest {
	
	AudioServicesPlaySystemSound(1521);
	// UIView* playerView = [self valueForKey:@"_videoPlayerView"];
	[self addVideoPlayerView:[self valueForKey:@"_videoPlayerView"]];
	// if (!playerView) return;
	// SPTVideoDisplayView* displayView = [playerView valueForKey:@"_displayView"];
	// if (!displayView) return;
	// [displayView playerSource];

}

%end

%end

%ctor {

    %init(JuinCanvasHelper);

}