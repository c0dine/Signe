#include "BGNumberCanvas.h"
#include "Signe.h"
#include "SigneManager.h"
#import <AudioToolbox/AudioToolbox.h>

static NSDictionary *prefs;
static BOOL activationStyle = 0;

@interface UISystemGestureView : UIView

@property (nonatomic, retain) BGNumberCanvas *BGCanvas;
- (void)insertCanvas;
@property (nonatomic, assign) BOOL injected;
@end

@interface FBSystemGestureView : UISystemGestureView
@end


@interface bac 
-(BOOL)_handleVolumeDecreaseUp;
-(BOOL)_handleVolumeIncreaseUp;
@end
@interface volb
-(bac *)buttonActions;
@end
@interface UIApplication (Signe)
-(volb *)volumeHardwareButton;
@end

%hook UISystemGestureView 

// iOS 13+ Support

/* ([[[[UIApplication sharedApplication] volumeHardwareButton] buttonActions] _handleVolumeIncreaseUp] && [[[[UIApplication sharedApplication] volumeHardwareButton] buttonActions] _handleVolumeDecreaseUp]) */

%property (nonatomic, retain) BGNumberCanvas *BGCanvas;
%property (nonatomic, assign) BOOL injected;  

- (void)layoutSubviews
{
    %orig;
    if (!self.injected) 
    {
		self.BGCanvas = [[BGNumberCanvas alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		self.BGCanvas.hidden = YES;
		[self addSubview:self.BGCanvas];
    	[self.BGCanvas setValue:@YES forKey:@"deliversTouchesForGesturesToSuperview"];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activateSigne) name:@"ActivateSigne" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deactivateSigne) name:@"DeactivateSigne" object:nil];
		self.injected = YES;
    }
}

%new
- (void)activateSigne
{	
	[self.BGCanvas clear];
    [self.BGCanvas setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];
	self.BGCanvas.hidden = NO;
	//
}

%new
- (void)deactivateSigne
{
    [self.BGCanvas setValue:@YES forKey:@"deliversTouchesForGesturesToSuperview"];
	self.BGCanvas.hidden = YES;
}


%end



%hook FBSystemGestureView 

// <= iOS 12 Support


%property (nonatomic, retain) BGNumberCanvas *BGCanvas;
%property (nonatomic, assign) BOOL injected; 

- (void)layoutSubviews
{
    %orig;
    if (!self.injected) 
    {
		self.BGCanvas = [[BGNumberCanvas alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		self.BGCanvas.hidden = YES;
		[self addSubview:self.BGCanvas];
    	[self.BGCanvas setValue:@YES forKey:@"deliversTouchesForGesturesToSuperview"];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activateSigne) name:@"ActivateSigne" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deactivateSigne) name:@"DeactivateSigne" object:nil];
		self.injected = YES;
    }
}

%new
- (void)activateSigne
{
    [self.BGCanvas setValue:@NO forKey:@"deliversTouchesForGesturesToSuperview"];
	self.BGCanvas.hidden = NO;
}

%new
- (void)deactivateSigne
{
    [self.BGCanvas setValue:@YES forKey:@"deliversTouchesForGesturesToSuperview"];
	self.BGCanvas.hidden = YES;
}


%end


@interface SpringBoard : UIApplication
-(BOOL)_handlePhysicalButtonEvent:(id)arg1;
- (void)activateTouchRecognizer;
@property (nonatomic, assign) BOOL signeActive;
@property (nonatomic, assign) BOOL volDownActive;
@property (nonatomic, retain) NSTimer *pressedTimer;
@end

%hook SpringBoard

%property (nonatomic, assign) BOOL signeActive;
%property (nonatomic, retain) NSTimer *pressedTimer;
%property (nonatomic, assign) BOOL volDownActive;

-(_Bool)_handlePhysicalButtonEvent:(UIPressesEvent *)arg1 
{
	int type = arg1.allPresses.allObjects[0].type; 
	int force = arg1.allPresses.allObjects[0].force;

	NSLog(@"Signe: %d - %d", type, force);

	// type = 101 -> Home button
	// type = 102 -> vol up
	// type = 103 -> vol down
	// type = 104 -> Power button
    

	// force = 0 -> button released
	// force = 1 -> button pressed
	if ([arg1.allPresses.allObjects count] <= 1) return %orig;
	if (arg1.allPresses.allObjects[0].type == 103 && force == 1 && arg1.allPresses.allObjects[1].type == 104 && arg1.allPresses.allObjects[1].force == 1) //Power PRESSED
	{
		[self activateTouchRecognizer];
		return NO;
	}

	/* 	if (type == 103 && force == 1) //Power PRESSED
	{
		if (self.pressedTimer == nil) self.pressedTimer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(activateTouchRecognizer) userInfo:nil repeats:NO];
	}

	if (type == 103 && force == 0) //Power RELEASED
	{
		if (self.pressedTimer != nil) {
			[self.pressedTimer invalidate];
			self.pressedTimer = nil;
		}
	} */

	return %orig;
}

%new 
-(void)volup{}

%new 
- (void)activateTouchRecognizer
{
	if (!self.signeActive || self.signeActive == nil) // If signe not active
	{
		self.signeActive = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ActivateSigne" object:nil];
		AudioServicesPlaySystemSound(1519);
	}
	else // If signe is active
	{
		self.signeActive = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DeactivateSigne" object:nil];
		AudioServicesPlaySystemSound(1519);
	}
}

%end



static void *observer = NULL;

static void reloadPrefs() 
{
    if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) 
    {
        CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

        if (keyList) 
        {
            prefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));

            if (!prefs) 
            {
                prefs = [NSDictionary new];
            }
            CFRelease(keyList);
        }
    } 
    else 
    {
        prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
    }
}


static BOOL boolValueForKey(NSString *key, BOOL defaultValue) 
{
    return (prefs && [prefs objectForKey:key]) ? [[prefs objectForKey:key] boolValue] : defaultValue;
}

static void preferencesChanged() 
{
    CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
    //reloadPrefs();

	[[SigneManager sharedManager] setBundleToOpen:@"com.atebits.Tweetie2" forKey:@"2"]; //twitter
	[[SigneManager sharedManager] setBundleToOpen:@"com.hammerandchisel.discord" forKey:@"3"]; //discord
	[[SigneManager sharedManager] setURLToOpen:@"https://patreon.com/kritantadev" forKey:@"5"]; //krit patreon
	[[SigneManager sharedManager] setURLToOpen:@"https://www.buymeacoff.ee/tr1fecta" forKey:@"6"]; //tr1 bmac
	[[SigneManager sharedManager] setBundleToOpen:@"com.christianselig.Apollo" forKey:@"9"]; //rebbit

	[[SigneManager sharedManager] setShouldDrawCharacters:YES];
	[[SigneManager sharedManager] setStrokeColor:[UIColor colorWithRed:0.28 green:0.80 blue:0.64 alpha:1.0]];
	[[SigneManager sharedManager] setStrokeSize:10];
}

#pragma mark ctor

%ctor 
{
    [SigneManager sharedManager];

    preferencesChanged();

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        (CFNotificationCallback)preferencesChanged,
        (CFStringRef)@"me.kritanta.signeprefs/Prefs",
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );

}