//
//  ViewController.m
//  ZHCardRecognition
//
//  Created by 李保征 on 2017/9/4.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import "ViewController.h"
#import "ZHIDCardViewController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,retain) NSMutableArray *dataArray;

@end

@implementation ViewController



/** 
 身份证扫描识别  集成自 zhongfenglee/IDCardRecognition
              xiaohange / IDCardRecognition  在上一个基础上增加了反面识别
 
 身份证照片处理识别  gaofengtan / RecognizeCard
 */



- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    
    self.title = @"tableView";
    
    [self.view addSubview:self.tableView];
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat tableViewY = 0;
        CGFloat tableViewH = self.view.bounds.size.height;
        CGFloat tableViewX = 0;
        CGFloat tableViewW = self.view.bounds.size.width;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(tableViewX, tableViewY, tableViewW, tableViewH) style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        
        //控制器遵守代理
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

        //去除没有数据时显示分割线bug
        _tableView.tableFooterView = [[UIView alloc] init];
        
        _tableView.allowsSelectionDuringEditing = YES;
    }
    return _tableView;
}

- (NSMutableArray *)dataArray{
    if (!_dataArray) {
        NSArray *data = @[
                          @{
                              @"title" : @"身份证识别",
                              @"action" : @"recognitionIDCard"
                              },
                          @{
                              @"title" : @"银行卡识别",
                              @"action" : @"recognitionBankCard"
                              }
                          ];
        _dataArray = [NSMutableArray arrayWithArray:data];
    }
    return _dataArray;
}

#pragma mark - action

- (void)recognitionIDCard{
    ZHIDCardViewController *vc = [[ZHIDCardViewController alloc] init];
    vc.title = @"身份证识别";
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)recognitionBankCard{
    
}

#pragma mark - UITableViewDelegate
//组数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

//行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

//行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

//cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text = [self.dataArray[indexPath.row] valueForKey:@"title"];
    return cell;
}

//选中
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *selectorStr = [self.dataArray[indexPath.row] valueForKey:@"action"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(selectorStr)];
#pragma clang diagnostic push
}


@end
