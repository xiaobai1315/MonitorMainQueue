//
//  ViewController.m
//  t
//
//  Created by Jermy on 2017/11/9.
//  Copyright © 2017年 Jermy. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, weak) UIView *myView;
@end

@implementation ViewController
{
    CFRunLoopObserverRef _runloopObserver;
    dispatch_semaphore_t _semaphore;
    NSInteger _timeOutCount;
    CFRunLoopActivity _activity;
}

-(void)viewDidLoad
{
    UIButton *startMonitorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [startMonitorBtn setTitle:@"开始监控" forState:UIControlStateNormal];
    startMonitorBtn.frame = CGRectMake(10, 50, 80, 40);
    [startMonitorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [startMonitorBtn addTarget:self action:@selector(startMonitor) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startMonitorBtn];
    
    UIButton *blockThread = [UIButton buttonWithType:UIButtonTypeCustom];
    blockThread.frame = CGRectMake(100, 50, 80, 40);
    [blockThread setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [blockThread setTitle:@"阻塞主线程" forState:UIControlStateNormal];
    [blockThread addTarget:self action:@selector(blockThread) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:blockThread];
    
    UITableView *tableView = [[UITableView alloc] init];
    tableView.frame = CGRectMake(0, 80, 375, 500);
    tableView.backgroundColor = [UIColor grayColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"cell-%zd", indexPath.row];
    
    return cell;
}

-(void)blockThread
{
    NSLog(@"blockThread");
    dispatch_async(dispatch_get_main_queue(), ^{
       
        for(NSInteger i = 0; i < 100000; i++){
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
            NSString *str = @"2017-03-08 01:03:31";
            
            [formatter dateFromString:str];
        }
    });
}

void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    ViewController *vc = (__bridge ViewController *)info;
    vc->_activity = activity;
    
    switch (activity) {
        case kCFRunLoopAfterWaiting:
            NSLog(@"kCFRunLoopAfterWaiting");
            break;
            
        case kCFRunLoopBeforeSources:
            NSLog(@"kCFRunLoopBeforeSources");
            break;
            
        case kCFRunLoopBeforeWaiting:
            NSLog(@"kCFRunLoopBeforeWaiting");
            break;
            
        case kCFRunLoopBeforeTimers:
            NSLog(@"kCFRunLoopBeforeTimers");
            break;
            
        default:
            break;
    }
    
    dispatch_semaphore_t semaphore = vc->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

//开始监控
-(void)startMonitor
{
    if(_runloopObserver){
        return;
    }
    _semaphore = dispatch_semaphore_create(0);
    
    CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL};
    _runloopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, runLoopObserverCallBack, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _runloopObserver, kCFRunLoopCommonModes);

    //开启子线程循环监控
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        while (YES) {
            
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
            long semaphoreWait = dispatch_semaphore_wait(_semaphore, time);

            if(semaphoreWait != 0){ //超时
                if(!_runloopObserver){
                    _timeOutCount = 0;
                    _semaphore  = 0;
                    _activity = 0;
                    return;
                }
                
                if(_activity == kCFRunLoopAfterWaiting || _activity == kCFRunLoopBeforeSources){
                    
                    NSLog(@"发现一次延时");
                    if(++_timeOutCount < 3){
                        continue;
                    }
                }
            }else{
                _timeOutCount = 0;
            }
        }
    });
}

@end
