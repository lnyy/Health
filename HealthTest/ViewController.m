//
//  ViewController.m
//  HealthTest
//
//  Created by apple on 2016/11/8.
//  Copyright © 2016年 lny. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>

@interface ViewController ()
@property (nonatomic,strong)HKHealthStore *health;

@property (weak, nonatomic) IBOutlet UILabel *stepLab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self sestup];
    
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(readStepData) name:@"readData" object:nil];
//    
//    NSLog(@"%d",[HKHealthStore isHealthDataAvailable]);
//    
//    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
}

- (void)sestup{

    self.stepLab.layer.cornerRadius = self.stepLab.frame.size.width/2;
    self.stepLab.layer.borderColor = [UIColor redColor].CGColor;
    self.stepLab.layer.borderWidth = 5;
    self.stepLab.backgroundColor = [UIColor blueColor];
    self.stepLab.layer.masksToBounds = YES;
}

//- (void)readDistanceData{
//
//    NSSortDescriptor *timeDescriptor = [[NSSortDescriptor alloc]initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
//    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
//    HKSampleQuery *query = [[HKSampleQuery alloc]initWithSampleType:type predicate:nil limit:HKObjectQueryNoLimit sortDescriptors:@[timeDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
//        NSLog(@"-----%@",results);
//    }];
//}
- (IBAction)readStepAction:(UIButton *)sender {
    
    if (![HKHealthStore isHealthDataAvailable]) {
        self.stepLab.text = @"该设备不支持HealthKit";
    }
    
    self.health = [[HKHealthStore alloc]init];
    HKObjectType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSSet *healthSet = [NSSet setWithObjects:stepType, nil];
    
    [self.health requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
          [self readStepCount];
        }else{
          self.stepLab.text = @"获取步数权限失败";
        }
    }];
    
}

-(void)readStepCount{
    //查询采样信息
    HKQuantityType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    //当前时间
    NSDate *now = [NSDate date];
    //日历
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute;
    NSDateComponents *dateComponent = [calender components:unitFlags fromDate:now];
    NSLog(@"dateComponent:%@",dateComponent);
    int hour = (int)[dateComponent hour];
    int minute = (int)[dateComponent minute];
    int second = (int)[dateComponent second];
    
    NSDate *nowDay = [NSDate dateWithTimeIntervalSinceNow:- (hour*3600 + minute * 60 + second)];
    NSDate *nextDay = [NSDate dateWithTimeIntervalSinceNow:- (hour*3600 + minute * 60 + second)+86400];
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:nowDay endDate:nextDay options:HKQueryOptionNone];
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:@[start] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        NSLog(@"+++++++%@",results);
        int allStepCount = 0;
        for (int i = 0; i < results.count; i++) {
            HKQuantitySample *result = results[i];
            HKQuantity *quantity = result.quantity;
            NSMutableString *stepCount  = (NSMutableString *)quantity;
            NSString *stepStr =[NSString stringWithFormat:@"%@",stepCount];
            
            NSString *str = [stepStr componentsSeparatedByString:@" "][0];
            
            int stepNum = [str intValue];
            NSLog(@"%d",stepNum);
            NSLog(@"%@",result);
            allStepCount = allStepCount+stepNum;
        }
        
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            self.stepLab.text  = [NSString stringWithFormat:@"%d",allStepCount];
            
            NSLog(@"总步数---%d",allStepCount);
        }];
        
    }];

    [self.health executeQuery:sampleQuery];
    
    
    HKObserverQuery *q1 = [[HKObserverQuery alloc]initWithSampleType:sampleType predicate:predicate updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
        
    }];
    [self.health executeQuery:q1];
    
    
    

}
- (IBAction)readDistance:(UIButton *)sender {
    
    HKObjectType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    NSSet *healthSet = [NSSet setWithObjects:stepType, nil];
    

//    if([HKHealthStore isHealthDataAvailable]){
    
        [self.health requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self readDis];
            }else{
                NSLog(@"失败");
            }
        }];
    
//    }
}

- (void)readDis{

    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:now];
    NSDate *start = [calendar dateFromComponents:components];
    NSDate *end = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:start options:0];
    
    NSPredicate *pre = [HKQuery predicateForSamplesWithStartDate:start endDate:end options:HKQueryOptionStrictStartDate];
    HKObserverQuery *query = [[HKObserverQuery alloc]initWithSampleType:type predicate:pre updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
        
        HKStatisticsQuery *sQuery =[[HKStatisticsQuery alloc]initWithQuantityType:type quantitySamplePredicate:pre options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery * _Nonnull query, HKStatistics * _Nullable result, NSError * _Nullable error) {
            NSLog(@"result----%@",result);
        }];
        
        [self.health executeQuery:sQuery];
        
    }];
    
    [self.health executeQuery:query];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
