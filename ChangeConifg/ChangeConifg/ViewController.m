//
//  ViewController.m
//  ChangeConifg
//
//  Created by David Yang on 15/11/19.
//  Copyright © 2015年 Sensoro. All rights reserved.
//

#import "ViewController.h"
#import "SBKBeaconManager.h"
#import "SBKBeacon.h"

@interface ViewController () <SBKBeaconManagerDelegate,SBKBeaconDelegate> {
    NSArray *_UUIDs;
}

@property (nonatomic,strong) SBKBeacon * beacon40;
@property (nonatomic,strong) SBKBeacon * beacon30;

@property (weak, nonatomic) IBOutlet UIButton *beacon40Test;
@property (weak, nonatomic) IBOutlet UIButton *beacon30Test;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _UUIDs = @[@"23A01AF0-232A-4518-9C0E-323FB773F5EF"];
    
    [[SBKBeaconManager sharedInstance] requestAlwaysAuthorization];
    
    [SBKBeaconManager sharedInstance].delegate = self;
    
    for (NSString *str in _UUIDs) {
        SBKBeaconID *beaconID = [SBKBeaconID beaconIDWithString:str];
        [[SBKBeaconManager sharedInstance] startRangingBeaconsWithID:beaconID wakeUpApplication:NO];
    }

    _beacon30Test.enabled = NO;
    _beacon40Test.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark SBKBeaconManagerDelegate

- (void)beaconManager:(SBKBeaconManager *)beaconManager didRangeNewBeacon:(SBKBeacon *)beacon {
    if (beacon.serialNumber) {
        if( [beacon.serialNumber isEqualToString:@"0117C5525991"]){
            _beacon40 = beacon;
            _beacon40.delegate = self;
            _beacon40Test.enabled = YES;
            NSLog(@"firmware 4.0 beacon was found");
        } else if( [beacon.serialNumber isEqualToString:@"0117C5554FFA"]){
            _beacon30 = beacon;
            _beacon30.delegate = self;
            _beacon30Test.enabled = YES;
            NSLog(@"firmware 3.0 beacon was found");
        }
    };
}

- (void)beaconManager:(SBKBeaconManager *)beaconManager beaconDidGone:(SBKBeacon *)beacon {
    if( [beacon.serialNumber isEqualToString:@"0117C5525991"]){
        _beacon40 = nil;
        _beacon40.delegate = nil;
    } else if( [beacon.serialNumber isEqualToString:@"0117C5554FFA"]){
        _beacon30 = nil;
        _beacon30.delegate = nil;
    }
}

- (void)beaconManager:(SBKBeaconManager *)beaconManager scanDidFinishWithBeacons:(NSArray *)beacons {
}

#pragma mark SBKBeaconDelegate

- (void)sensoroBeaconRequirePassword:(SBKBeacon *)beacon{
    //verify the password here;
    BOOL ret = [beacon requireWritePermissionWithPassword:@"123" completion:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error accessing beacon");
        }
    }];
    
    if (ret == NO) {
        NSLog(@"4.0 requireWritePermissionWithPassword return NO");
    }
}

- (void)sensoroBeaconDidConnect:(SBKBeacon *)beacon{
    NSLog(@"Connect to %@ is OK",beacon.serialNumber);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [beacon flashLightWithCommand:SBKCommonFlashLightCommand_22
                               repeat:2
                           completion:^(NSError *error) {
                               if (error == nil) {
                                   NSLog(@"the device is disconnected");
                               }else{
                                   NSLog(@"Connect to the device is failed %@",error);
                               }
                               [beacon disconnect];
                           }];
    });
}

#pragma mar response methode

- (IBAction)connectTo40:(id)sender {
    [_beacon40 connectWithCompletion:^(NSError *error) {
        NSLog(@"the connection is OK");
    }];
}

- (IBAction)connectTo30:(id)sender {
    [_beacon30 connectWithCompletion:^(NSError *error) {
        
        //code below is for beacon before firmware 4.0;
        if (!error) {
            NSDictionary * baseSettings = _beacon30.baseSettings;
            NSLog(@"base %@ error %@", _beacon30.baseSettings,error);   // Throws error here
            //Base on firmware version to decide if it need enter password here
            if ([[baseSettings objectForKey:@"SBKBeaconBaseSettingsPasswordRequiredKey"] boolValue]) {
                
                BOOL ret = [_beacon30 requireWritePermissionWithPassword:@"123" completion:^(NSError *error) {
                    if (error != nil) {
                        NSLog(@"Error accessing beacon");
                    }
                }];
                
                if (ret == NO) {
                    NSLog(@"3.0 requireWritePermissionWithPassword return NO");
                }
                
            }
        } else {
            NSLog(@"Connecting error %@  pass:%@",error,@"123");
        }
    }];
}



@end
