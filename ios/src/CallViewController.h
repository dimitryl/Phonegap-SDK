//
//  CallViewController.h
//  sdk-helper
//
//  Created by Charles Thierry on 7/19/13.

/**
 * This class is an adaptation of the CallViewController presented in the Helper application of the WeemoSDK.
 */

#import "WeemoData.h"
#import "WeemoCall.h"
@protocol WeemoCallWindowDelegate <NSObject>
- (void)cwHangup:(id)sender;
@end


@interface CallViewController : UIViewController
{
	BOOL fitVideo;
	NSTimer *hider;
}
@property (weak, nonatomic) IBOutlet UIButton *b_hangup;
@property (weak, nonatomic) IBOutlet UIButton *b_profile;
@property (weak, nonatomic) IBOutlet UIButton *b_toggleVideo;
@property (weak, nonatomic) IBOutlet UIButton *b_toggleAudio;
@property (weak, nonatomic) IBOutlet UIButton *b_switchVideo;

@property (weak, nonatomic) IBOutlet UIView *v_callMenu;
@property (weak, nonatomic) IBOutlet UIView *v_videoIn;
@property (weak, nonatomic) IBOutlet UIView *v_videoOut;

@property (nonatomic)BOOL canComeBack;
@property (weak, nonatomic) WeemoCall *call;

@property (nonatomic, weak) id<WeemoCallWindowDelegate> cwDelegate;

/**
 * The user tapped on the "Hangup" button
 */
- (IBAction)hangup:(id)sender;
/**
 * The user tapped on the "HD" button
 */
- (IBAction)profile:(id)sender;
/**
 * The user tapped on the "Enable Video"
 */
- (IBAction)toggleVideo:(id)sender;

/**
 * The user tapped on the "Switch" button
 */
- (IBAction)switchVideo:(id)sender;

/**
 * The user tapped on "Enable Mic." button
 */
- (IBAction)toggleAudio:(id)sender;


- (void)resizeVideoIn:(BOOL)animated;


- (void)updateIdleStatus;


@end
