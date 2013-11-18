//
//  WeemoPlugin.m
//  WeemoPhonegap
//
//  Created by Charles Thierry on 10/31/13.
//
//

#import "WeemoPlugin.h"

@implementation WeemoPlugin

#pragma mark - JS -> ObjectiveC 
- (void)initialize:(CDVInvokedUrlCommand *)command
{
	cb_connect = [NSString stringWithString:command.callbackId];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[Weemo WeemoWithAppID:[command argumentAtIndex:0] andDelegate:self error:nil];
	});

}

- (void)authent:(CDVInvokedUrlCommand *)command
{
	cb_authent = [NSString stringWithString:command.callbackId];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[Weemo instance] authenticateWithToken:[command argumentAtIndex:0]
										andType:[[command argumentAtIndex:1] intValue]];
	});

}


- (void)setDisplayName:(CDVInvokedUrlCommand *)command
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[Weemo instance] setDisplayName:[command argumentAtIndex:0]];
	});
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
								 callbackId:command.callbackId];
}

- (void)getStatus:(CDVInvokedUrlCommand *)command
{
	cb_canCall = [NSString stringWithString:command.callbackId];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[Weemo instance] getStatus:[command argumentAtIndex:0]];
	});

}

- (void)createCall:(CDVInvokedUrlCommand *)command
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[Weemo instance] createCall:[command argumentAtIndex:0]];
	});

	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
								 callbackId:command.callbackId];
}

- (void)disconnect:(CDVInvokedUrlCommand *)command
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[Weemo instance] disconnect];
	});
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
								 callbackId:command.callbackId];
}

- (void)muteOut:(CDVInvokedUrlCommand *)command
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[[Weemo instance] activeCall]audioStop];
	});
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
								 callbackId:command.callbackId];
}

- (void)resume:(CDVInvokedUrlCommand *)command
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[[Weemo instance]activeCall]resume];
	});
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
								 callbackId:command.callbackId];
}

- (void)hangup:(CDVInvokedUrlCommand *)command
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[[Weemo instance]activeCall]hangup];
	});
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
								 callbackId:command.callbackId];
}

- (void)displayCallWindow:(CDVInvokedUrlCommand *)command
{
	cb_canComeBack = [NSString stringWithString:command.callbackId];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		canComeBack = [[command argumentAtIndex:1]intValue]==0?NO:YES;
		[self addCallView];
		[[[Weemo instance]activeCall]videoStart];
		NSLog(@"%s setCanComeBack %@ (%d %@)",__FUNCTION__, [[command argumentAtIndex:1]intValue]==0?@"NO":@"YES", [[command argumentAtIndex:1]intValue], cvc_active );
	});
	
}

- (void)setAudioRoute:(CDVInvokedUrlCommand *)command
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0L), ^{
		[[[Weemo instance] activeCall]toggleAudioRoute];
		[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[[[Weemo instance] activeCall]audioRoute]]
									 callbackId:command.callbackId];
	});
}


#pragma mark -
- (void)addCallView
{
	NSLog(@">>>> %s", __FUNCTION__);
	if (cvc_active) return;
	dispatch_async(dispatch_get_main_queue(), ^{
		cvc_active = [[CallViewController alloc]initWithNibName:@"CallViewController" bundle:[NSBundle mainBundle]];
		[cvc_active setCwDelegate:self];
		[[[[[UIApplication sharedApplication] delegate]window]rootViewController]addChildViewController:cvc_active];
		
		[cvc_active setCanComeBack:canComeBack];
//		if ([[cvc_active presentingViewController] isEqual:[[[[UIApplication sharedApplication] delegate]window]rootViewController]])
//			return;
		if ([[[cvc_active view] superview] isEqual:[[[[[UIApplication sharedApplication] delegate]window]rootViewController]view]] )
		{
			return;
		}
		[[cvc_active view]setFrame:CGRectMake(0., 0.,
											  [[[[[[UIApplication sharedApplication] delegate]window]rootViewController] view]bounds].size.width,
											  [[[[[[UIApplication sharedApplication] delegate]window]rootViewController] view]bounds].size.height)];
		[[[[[[UIApplication sharedApplication] delegate]window]rootViewController] view] addSubview:[cvc_active view]];
//		UINavigationController *navTemp = [[UINavigationController alloc]initWithRootViewController:cvc_active];
//		[navTemp setNavigationBarHidden:YES];
//		[[[[[UIApplication sharedApplication] delegate]window]rootViewController] presentViewController:navTemp animated:NO completion:^{}];
	});
}

- (void)removeCallView
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[cvc_active view]removeFromSuperview];
		[cvc_active removeFromParentViewController];
//		[[[[[UIApplication sharedApplication] delegate]window]rootViewController]dismissModalViewControllerAnimated:NO];
		[cvc_active setCwDelegate:nil];
		cvc_active = nil;
	});
}


#pragma mark - Weemo Delegation
- (void)weemoCallCreated:(WeemoCall *)call
{
	NSLog(@">>>> %s", __FUNCTION__);
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"Weemo.internal.callCreated(%d, \"%s\");", [call callid],
								   [[call contactID] UTF8String]] scheduledOnRunLoop:YES];
	[call setDelegate:self];
	dispatch_async(dispatch_get_main_queue(), ^{
//		[self addCallView];
	});
}

- (void)weemoCallEnded:(WeemoCall *)call
{
	NSLog(@">>>> %s", __FUNCTION__);
		[self removeCallView];
}

- (void)weemoContact:(NSString *)contactID canBeCalled:(BOOL)canBeCalled
{
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:canBeCalled?1:0] callbackId:cb_canCall];
}

- (void)weemoDidAuthenticate:(NSError *)error
{
	if (error)
	{
		[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
																  messageAsInt:[error code]]
									 callbackId:cb_authent];
	} else {
		[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
									 callbackId:cb_authent];
	}
	cb_authent = nil;
}

- (void)weemoDidConnect:(NSError *)error
{
	if (cb_connect)
	{
		if (error)
		{
			[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
																		 messageAsInt:[error code]]
										 callbackId:cb_connect];
		} else {
			[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
										 callbackId:cb_connect];
		}
	}
	cb_connect = nil;
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"Weemo.internal.connectionChanged(%d);", [error code]] scheduledOnRunLoop:YES];
}

- (void)weemoDidDisconnect:(NSError *)error
{
	if (cb_disconnect)
	{
		if (error)
		{
			[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
																		 messageAsInt:[error code]]
										 callbackId:cb_connect];
		} else {
			[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
										 callbackId:cb_connect];
		}
	}
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"Weemo.internal.connectionChanged(%d);", [error code]] scheduledOnRunLoop:YES];
	cb_disconnect = nil;
}

#pragma mark - WeemoCall delegation
- (void)weemoCall:(id)sender videoReceiving:(BOOL)isReceiving
{
	NSLog(@">>>> %s: %@", __FUNCTION__, isReceiving ?@"YES":@"NO");
	[cvc_active updateIdleStatus];
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"Weemo.internal.videoInChanged(%d, %s);", [sender callid], isReceiving?"true":"false"] scheduledOnRunLoop:YES];
	dispatch_async(dispatch_get_main_queue(), ^{
		[[cvc_active v_videoIn]setHidden:!isReceiving];
		[cvc_active resizeVideoIn];
	});
}

- (void)weemoCall:(id)sender videoSending:(BOOL)isSending
{
	NSLog(@">>>> %s: %@",__FUNCTION__,  isSending ? @"YES":@"NO");
	[cvc_active updateIdleStatus];
	dispatch_async(dispatch_get_main_queue(), ^{
		[[cvc_active b_toggleVideo]setSelected:isSending];
		[[cvc_active v_videoOut]setHidden:!isSending];
		[cvc_active resizeVideoIn];
	});
}

- (void)weemoCall:(id)sender videoProfile:(int)profile
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@">>>> %s: %d",__FUNCTION__,  profile);
		[[cvc_active b_profile]setSelected:(profile != 0)];
		[cvc_active resizeVideoIn];
	});
}

- (void)weemoCall:(id)sender videoSource:(int)source
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@">>>> %s: %@",__FUNCTION__,  (source == 0)?@"Front":@"Back");
		[[cvc_active b_switchVideo] setSelected:!(source == 0)];
		[cvc_active resizeVideoIn];
	});
}

- (void)weemoCall:(id)call audioSending:(BOOL)isSending
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@">>>> %s: %@",__FUNCTION__,  isSending?@"YES":@"NO");
		[[cvc_active b_toggleAudio]setSelected:!isSending];
	});
}

- (void)weemoCall:(id)sender callStatus:(int)status
{
	NSLog(@">>>> %s: 0x%X",__FUNCTION__,  status);
	[cvc_active updateIdleStatus];
	[[self commandDelegate]evalJs:[NSString stringWithFormat:@"Weemo.internal.callStatusChanged(%d, %d);", [[[Weemo instance]activeCall] callid], status] scheduledOnRunLoop:YES];
}

#pragma mark - CallWindow Delegation
- (void)cwHangup:(CallViewController *)sender
{
	if ([cvc_active canComeBack])
	{
		[self removeCallView];
		dispatch_async(dispatch_get_main_queue(), ^{
			[[[Weemo instance]activeCall]videoStop];
		});
	} else {
		[[[Weemo instance]activeCall]hangup];
	}
	[[self commandDelegate]sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
								 callbackId:cb_canComeBack];
}

@end
