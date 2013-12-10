//
//  CallViewController.m
//  sdk-helper
//
//  Created by Charles Thierry on 7/19/13.
//  Copyright (c) 2013 Weemo SAS. All rights reserved.
//

#import "CallViewController.h"
#import "Weemo.h"
#import <QuartzCore/QuartzCore.h>

@interface CallViewController ()

@end

@implementation CallViewController
@synthesize b_hangup;
@synthesize b_profile;
@synthesize b_toggleVideo;
@synthesize b_toggleAudio;
@synthesize call;
@synthesize v_videoIn;
@synthesize v_videoOut;
@synthesize canComeBack;
@synthesize cwDelegate;

#pragma mark - Controller life cycle
- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self setCall:[[Weemo instance] activeCall]];
		fitVideo = NO;
	}
	return self;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[[[Weemo instance]activeCall] setViewVideoIn:[self v_videoIn]];
//	[[[Weemo instance]activeCall] setViewVideoOut:[self v_videoOut]];
	[b_hangup  setImage:[UIImage imageNamed:[self canComeBack]?@"call_return":@"call_hangup"] forState:UIControlStateNormal];
	[self resizeView:[self interfaceOrientation]];
	[self resetHideTimer];
	[[self v_videoOut]setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)tO duration:(NSTimeInterval)duration
{
	NSLog(@"%s", __FUNCTION__);
	[self resizeView:tO];
}

- (void)resizeView:(UIInterfaceOrientation)tO
{
	[self resizeVideoIn:NO];
	[self resizeVideoOut:NO];
}

- (void)resizeVideoOut:(BOOL)animated
{
	if ([[[Weemo instance]activeCall]getVideoOutProfile].height <= 0 && [[[Weemo instance]activeCall]getVideoOutProfile].width <= 0) return;
	float maxDim = fminf([[[Weemo instance]activeCall]getVideoOutProfile].width,
						 [[[Weemo instance]activeCall]getVideoOutProfile].height);
	
	float width = 160. * [[[Weemo instance]activeCall]getVideoOutProfile].width / maxDim ;
	float height = 160. * [[[Weemo instance]activeCall]getVideoOutProfile].height / maxDim;
	if (animated)
	{
		[UIView animateWithDuration:.3 animations:^{
			[[self v_videoOut]setFrame:CGRectMake(self.view.frame.size.width - width,
												  self.view.frame.size.height - height,
												  width, height)];
		}];
	} else {
		[[self v_videoOut]setFrame:CGRectMake(self.view.frame.size.width - width,
											  self.view.frame.size.height - height,
											  width, height)];
	}
//	NSLog(@"%s VideoOut Frame: %@", __FUNCTION__,
//		  CGRectCreateDictionaryRepresentation([[self v_videoOut] frame]));
	
}

- (void)resizeVideoIn:(BOOL)animated
{
	if ([[self call]getVideoInProfile].height <= 0 && [[self call]getVideoInProfile].width <= 0) return;
	float hRat = [[self call]getVideoInProfile].height / [[self view]frame].size.height;
	float wRat = [[self call]getVideoInProfile].width / [[self view]frame].size.width;
	if (fitVideo)
	{
		//we resize so that the biggest of the Rat is set to 1
		float width = [[self call] getVideoInProfile].width / ((hRat > wRat)?hRat:wRat);
		float height = [[self call] getVideoInProfile].height / ((hRat > wRat)?hRat:wRat);
		if (animated)
		{
			[UIView animateWithDuration:.3 animations:^{
				[[self v_videoIn]setFrame:CGRectMake(self.view.frame.size.width/2. - width /2.,
													 self.view.frame.size.height/2. - height /2.,
													 width, height)];
			}];
		} else {
			[[self v_videoIn]setFrame:CGRectMake(self.view.frame.size.width/2. - width /2.,
												 self.view.frame.size.height/2. - height /2.,
												 width, height)];
		}
	} else {
		float width = [[self call] getVideoInProfile].width / ((hRat < wRat)?hRat:wRat);
		float height = [[self call] getVideoInProfile].height / ((hRat < wRat)?hRat:wRat);
		if (animated)
		{
			[UIView animateWithDuration:.3 animations:^{
				[[self v_videoIn]setFrame:CGRectMake(self.view.frame.size.width/2. - width /2.,
													 self.view.frame.size.height/2. - height /2.,
													 width, height)];
			}];
		} else {
			[[self v_videoIn]setFrame:CGRectMake(self.view.frame.size.width/2. - width /2.,
												 self.view.frame.size.height/2. - height /2.,
												 width, height)];
		}
	}
	NSLog(@"%s VideoOut Frame: %@\n    Self frame %@", __FUNCTION__,
		  CGRectCreateDictionaryRepresentation([[self v_videoIn] frame]), CGRectCreateDictionaryRepresentation([[self view] frame]));
}

- (BOOL)toogleVideoFill
{
	fitVideo = !fitVideo;
	NSLog(@"%s", __FUNCTION__);
	dispatch_async(dispatch_get_main_queue(), ^{
		[self resizeVideoIn:YES];
	});
	return fitVideo;
}

#pragma mark - Actions

- (IBAction)hangup:(id)sender
{
	
	[[self cwDelegate] cwHangup:self];
}

- (IBAction)profile:(id)sender
{
	[[[Weemo instance]activeCall] toggleVideoProfile];
}

- (IBAction)toggleVideo:(id)sender
{

	if ([[[Weemo instance]activeCall] isSendingVideo])
	{
		[[[Weemo instance]activeCall] videoStop];
	} else {
		[[[Weemo instance]activeCall] videoStart];
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		[self resizeVideoIn:YES];
//		[self resizeVideoOut:YES];
		[[self v_videoOut]setHidden:YES];
	});
}

- (IBAction)switchVideo:(id)sender
{
	[[[Weemo instance]activeCall] toggleVideoSource];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self resizeVideoIn:YES];
	});
}

- (IBAction)toggleAudio:(id)sender
{
	if ([[[Weemo instance]activeCall] isSendingAudio])
	{
		[[[Weemo instance]activeCall] audioStop];
	} else {
		[[[Weemo instance]activeCall] audioStart];
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		[self resizeVideoIn:YES];
	});
}

- (void)updateIdleStatus
{
	if ([[[Weemo instance]activeCall] isSendingVideo] || [[[Weemo instance]activeCall] isReceivingVideo])
	{
		[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	} else {
		[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	}
}


- (void)resetHideTimer
{
	[hider invalidate];
	hider = [NSTimer scheduledTimerWithTimeInterval:3. target:self selector:@selector(hideTheMenu:) userInfo:nil repeats:NO];
}

- (void)hideTheMenu:(NSTimer *)timer
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:.3 animations:^{
			[[self v_callMenu] setAlpha:0.];
		}];
	});
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touched = [touches anyObject];
	if ([touched view] != [self v_videoIn])
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[[self v_callMenu] setAlpha:1.];
			[self resetHideTimer];
		});
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touched = [touches anyObject];
	if ([touched view] == [self v_videoIn])
	{
		[self toogleVideoFill];
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self v_callMenu] setAlpha:1.];
		[self resetHideTimer];
	});
}

- (void)setCwDelegate:(id<WeemoCallWindowDelegate>)cwd
{
	cwDelegate = cwd;
	if (cwd == nil)
	{
		[call setViewVideoIn:nil];
		[call setViewVideoOut:nil];
	}
}
@end
