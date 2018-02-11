//
//  jinianViewController.m
//  loveProgress
//
//  Created by 彭天浩 on 2017/12/29.
//  Copyright © 2017年 彭天浩. All rights reserved.
//

#import "jinianViewController.h"
#import "MJRefresh.h"
#import "memoryTableViewCell.h"
#import "jinianDetailViewController.h"
#import "xingdongDetailViewController.h"
@interface jinianViewController ()<UITableViewDataSource,UITableViewDelegate>{
    NSMutableArray *cellArray;
    int skitFlag;
    CGPoint point;
    
    int row;
    
    MBProgressHUD *hud;

    UIImageView *arrow;

}
@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) UIButton *jinianDetailButton;

@end

@implementation jinianViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setScreen];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [AVAnalytics beginLogPageView:@"jinianPage"];
    [self.navigationController.navigationBar setHidden:NO];

    if (_avid) {
        NSLog(@"myname = %@, mydate = %@, avid = %@",_myName,_myDate,_avid);
        int count = (int)cellArray.count;//减少调用次数
        for(int i=0; i<count; i++){
            if ([((memoryTableViewCell *)[cellArray objectAtIndex:i]).avid isEqualToString:_avid]) {
                memoryTableViewCell *cellTemp = [[memoryTableViewCell alloc] init];
                cellTemp.avid = _avid;
                cellTemp.name = _myName;
                cellTemp.date = _myDate;
                [cellTemp setSelectionStyle:UITableViewCellSelectionStyleNone];
                [cellTemp update];
                [cellArray replaceObjectAtIndex:i withObject:cellTemp];
                [_tableView reloadData];
                return;
            };
        }
        memoryTableViewCell *cellTemp = [[memoryTableViewCell alloc] init];
        cellTemp.avid = _avid;
        cellTemp.name = _myName;
        cellTemp.date = _myDate;
        [cellTemp setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cellTemp update];
        [cellArray insertObject:cellTemp atIndex:0];
        [_tableView reloadData];
        [self removeArrow];
        return;
    }
}

-(void)getData{
    AVQuery *query = [AVQuery queryWithClassName:@"memory"];
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"owner" equalTo:[AVUser currentUser]];
    [query selectKeys:@[@"objectId", @"name",@"date"]];
    query.limit = 10;
    query.skip = skitFlag;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for(AVObject *avObject in objects){
            NSString *objectId = avObject[@"objectId"];
            NSString *name = avObject[@"name"];
            NSDate *date = avObject[@"date"];
            memoryTableViewCell *cellTemp = [[memoryTableViewCell alloc] init];
            cellTemp.avid = objectId;
            cellTemp.name = name;
            cellTemp.date = date;
            [cellTemp setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cellTemp update];
            [cellArray addObject:cellTemp];
        }
        if (cellArray.count == 0) {
            [self addArrow];
        }else{
            [self removeArrow];
        }
        [self.tableView reloadData];
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
        [hud hideAnimated:YES];
    }];
}


-(void)setScreen{
    self.tabBarController.tabBar.hidden = YES;
    self.title = LOCAL(@"jinian");
    [self.view setBackgroundColor:PLACEHODER_COLOR];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = item;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    cellArray = [[NSMutableArray alloc] init];

    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH,SCREEN_HEIGHT) style:UITableViewStylePlain];
    _tableView.userInteractionEnabled=YES;
    self.tableView.mj_footer.automaticallyHidden = YES;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if (@available(iOS 11.0, *)) {
        _tableView.estimatedRowHeight = 0;
    }
//    UILongPressGestureRecognizer * longPressGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressToDo:)];
//    longPressGr.minimumPressDuration = 1.0;
//
//    [self.tableView addGestureRecognizer:longPressGr];
    [self.view addSubview:_tableView];
    
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        skitFlag = 0;
        [cellArray removeAllObjects];
        [weakSelf getData];
    }];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        skitFlag+=10;
        [weakSelf getData];
    }];
    skitFlag = 0;
    [cellArray removeAllObjects];
    [self getData];
    
    _jinianDetailButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-BEGIN_X-NAV_NORMAL_HEIGHT, SCREEN_HEIGHT-NAV_NORMAL_HEIGHT-BEGIN_X, NAV_NORMAL_HEIGHT, NAV_NORMAL_HEIGHT)];
    _jinianDetailButton.layer.cornerRadius = NAV_NORMAL_HEIGHT/2;
    _jinianDetailButton.layer.shadowColor = [UIColor grayColor].CGColor;
    _jinianDetailButton.layer.shadowOffset = CGSizeMake(2,2);
    _jinianDetailButton.layer.shadowOpacity = 0.6;
    _jinianDetailButton.layer.shadowRadius = 1;
    [_jinianDetailButton setBackgroundColor:ZANGQING_COLOR];
    [_jinianDetailButton setBackgroundImage:[globalFunction scaleToSize:[UIImage imageNamed:@"add"] size:_jinianDetailButton.frame.size] forState:UIControlStateNormal];
    [_jinianDetailButton addTarget:self action:@selector(jinianAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_jinianDetailButton];
    
    arrow = [[UIImageView alloc] initWithFrame:CGRectMake(_jinianDetailButton.frame.origin.x-70+GETWIDTH(_jinianDetailButton)/3, GETY(_jinianDetailButton)-65, 70, 60)];
    [arrow setImage:[globalFunction scaleToSize:[UIImage imageNamed:@"arrow_down"] size:CGSizeMake(70, 60)] ];
    [self.view addSubview:arrow];
    
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)jinianAction{
    jinianDetailViewController *vc= [[jinianDetailViewController alloc] init];
    vc.vc = self;
    [self.navigationController pushViewController:vc animated:YES];
}

//告诉tableView一共有多少组数据
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

//告诉tableView每一组有多少行数据
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return cellArray.count;
}

//告诉tableView每一行显示的内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    memoryTableViewCell *cell = nil;
    
    if (!cellArray) {
        cell = [[memoryTableViewCell alloc] init];
        return cell;
    }else{
        cell = [cellArray objectAtIndex:indexPath.row];
        return cell;
    }
}

//高度
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 127.734375+BEGIN_X+10;
}


-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self deleteActionWithIndexPath:indexPath];
    }];
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Edit", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self editActionWithIndexPath:indexPath];
    }];
    UITableViewRowAction *addAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"addToXingdong", nil) handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self addActionWithIndexPath:indexPath];
    }];
    deleteAction.backgroundColor = HONG_COLOR;
    editAction.backgroundColor = ZANGQING_COLOR;
    addAction.backgroundColor = GREEN_COLOR;
    return @[deleteAction, editAction,addAction];
}

-(void)deleteActionWithIndexPath:(NSIndexPath *)index{
    NSString *restring = LOCAL(@"sureToDelete");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:restring message:nil preferredStyle:UIAlertControllerStyleAlert];
    //取消style:UIAlertActionStyleDefault
    
    //简直废话:style:UIAlertActionStyleDestructive
    UIAlertAction *rubbishAction = [UIAlertAction actionWithTitle:LOCAL(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
        AVObject *todo =[AVObject objectWithClassName:@"memory" objectId:((memoryTableViewCell *)cellArray[index.row]).avid];
            [todo deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if(succeeded){
                    [cellArray removeObjectAtIndex:index.row];//移除数据源的数据
                    [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index.row inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
                    if (cellArray.count == 0) {
                        [self addArrow];
                    }
                }else{
                    [UIView showToast:LOCAL(@"fail")];
                }
            }];
    }];
    [alertController addAction:rubbishAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LOCAL(@"cancel") style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)editActionWithIndexPath:(NSIndexPath *)index{
    jinianDetailViewController *detail = [[jinianDetailViewController alloc] init];
    memoryTableViewCell *cell =(memoryTableViewCell *)cellArray[index.row];
    detail.avID =cell.avid;
    detail.jinianName =cell.name;
    detail.Date = cell.date;
    _avid =cell.avid;
    detail.vc = self;
    [self.navigationController pushViewController:detail animated:YES];
}
-(void)addActionWithIndexPath:(NSIndexPath *)index{
    xingdongDetailViewController *detail = [[xingdongDetailViewController alloc] init];
    memoryTableViewCell *cell =(memoryTableViewCell *)cellArray[index.row];
    detail.jinianName =cell.name;
    detail.Date = cell.nextDate;
    [self.navigationController pushViewController:detail animated:YES];
}



- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)removeArrow{
    arrow.alpha = 0;
}

- (void)addArrow{
    arrow.alpha = 1;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [AVAnalytics endLogPageView:@"jinianPage"];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
