//
//  LYBLE.m
//  HiSchool
//
//  Created by chairman on 16/5/8.
//  Copyright © 2016年 LaiYoung. All rights reserved.
//

#import "LYBLE.h"
#import <UIKit/UIKit.h>
//* ----------------------------- */
static NSString *const kLocalNotificationKey = @"kLocalNotificationKey";
static NSString *const kNotificationCategoryIdentifile = @"kNotificationCategoryIdentifile";
//* ----------------------------- */
@interface LYBLE()
<
CBCentralManagerDelegate,
CBPeripheralDelegate
>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray *peripherals;///<扫描到的所有外围设备
@property (nonatomic, strong) CBPeripheral *connectPeripheral;///<连接的外围设备
@property (nonatomic, strong) CBCharacteristic *currentCharacter; ///<当前服务的特征
@end

@implementation LYBLE
+ (instancetype)shareManager {
    static LYBLE *ble = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ble = [[LYBLE alloc] init];
    });
    return ble;
}
#pragma mark - lazy loading
- (CBCentralManager *)centralManager {
    if (!_centralManager) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return _centralManager;
}
- (NSMutableArray *)peripherals {
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}
#pragma mark - CBCentralManagerDelegate
//* 状态发生改变的时候会执行该方法(蓝牙4.0没有打开变成打开状态就会调用该方法) */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self scanAllPeripheral];
            NSLog(@"CBCentralManagerStatePoweredOn");//打开
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");//关闭
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");//不知道
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");//重置
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");//未授权
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");//不支持
            break;
        default:
            break;
    }
}
/**
 *  当发现外围设备的时候会调用该方法
 *
 *  @param peripheral        发现的外围设备
 *  @param advertisementData 外围设备发出信号
 *  @param RSSI              信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (![self.peripherals containsObject:peripheral]) {
        [self.peripherals addObject:peripheral];
        if ([self.centralManagerDelegate respondsToSelector:@selector(allPeripherals:)]) {
            [self.centralManagerDelegate allPeripherals:self.peripherals];
        }
    }
}
/**
 *  连接上外围设备的时候会调用该方法
 *
 *  @param peripheral 连接上的外围设备
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //* 停止扫描 */
    [self stopScan];
    NSLog(@"连接成功");
    self.connect = YES;
    // 1.扫描所有的服务
    // serviceUUIDs:指定要扫描该外围设备的哪些服务(传nil,扫描所有的服务)
    [peripheral discoverServices:nil];
    
    // 2.设置代理
    peripheral.delegate = self;
}
#pragma mark - CBPeripheralDelegate
/**
 *  发现外围设备的服务会来到该方法(扫描到服务之后直接添加peripheral的services)
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"service = %@",service);
        // characteristicUUIDs : 可以指定想要扫描的特征(传nil,扫描所有的特征)
        [peripheral discoverCharacteristics:nil forService:service];
    }
}
/**
 *  当扫描到某一个服务的特征的时候会调用该方法
 *
 *  @param service    在哪一个服务里面的特征
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%@",service.characteristics);
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties & CBCharacteristicPropertyWrite) {
            if ([characteristic.UUID.UUIDString isEqualToString:self.writeUUID]) {
                //[@"hello,外设" dataUsingEncoding:NSUTF8StringEncoding]
                [peripheral writeValue:self.writeData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                self.currentCharacter = characteristic;
                NSLog(@"写数据给外设");
                
            }
        }
    }
}


#pragma mark - methods
//* 扫描所有外设 */
- (void)scanAllPeripheral {
    // serviceUUIDs:可以将你想要扫描的服务的外围设备传入(传nil,扫描所有的外围设备)
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}
//* 停止扫描 */
- (void)stopScan {
    [self.centralManager stopScan];
}
//* 连接外围设备 */
- (void)connectPeripheral:(CBPeripheral *)peripheral {
    [self.centralManager connectPeripheral:peripheral options:nil];
    self.connectPeripheral = peripheral;
}

- (void)writeDataInPerpheral:(NSData *)data {
    if (self.connectPeripheral != nil && self.currentCharacter != nil) {
        [self.connectPeripheral writeValue:self.writeData forCharacteristic:self.currentCharacter type:CBCharacteristicWriteWithResponse];
        NSLog(@"写数据给外设");
    }

}

@end

//* ---------------------------Peripheral------------------------------------ */
@interface LYBLEPeripheral()
<
CBPeripheralManagerDelegate
>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *characteristic; //特征
@property (strong, nonatomic) CBMutableService *service;               //服务
@end

@implementation LYBLEPeripheral
#pragma mark - lazy loading
- (CBPeripheralManager *)peripheralManager {
    if (!_peripheralManager) {
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return _peripheralManager;
}
#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"外围设备BLE已打开");
            [self setupService];
            break;
            
        default:
            NSLog(@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备");
            break;
    }
}
//* 向外围设备添加了服务 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error{
    
    NSDictionary *dict = @{CBAdvertisementDataLocalNameKey:self.peripheralName};
    [self.peripheralManager startAdvertising:dict];
    NSLog(@"向外围设备添加了服务");
}
//* 已经启动广播 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error{
    NSLog(@"启动广播...");
}
//* 接受读请求 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"_______________我是didReceiveReadRequest分隔符号______________");
    NSLog(@"%@",[[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding]);
}
//* 接受写请求 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests{
    NSLog(@"_______________收到中心写来的数据______________");
    CBATTRequest *request = requests.lastObject;
    NSLog(@"%@",[[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding]);
    NSString *string = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
#warning .....
//    self.label.text = string;
    //* ------------------LocalNotification-------------------------------- */
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    //触发通知时间
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    //重复间隔
    //    localNotification.repeatInterval = kCFCalendarUnitMinute;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    //通知内容
    localNotification.alertBody = string;
    localNotification.applicationIconBadgeNumber = 1;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    //通知参数
    localNotification.userInfo = @{kLocalNotificationKey: @"LaiYoung"};
    
    localNotification.category = kNotificationCategoryIdentifile;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    
}

#pragma mark - methods

//* 开启外围服务 */
- (void)openPeripheral {
    [self peripheralManager];
}
/**
 关闭外围服务
 */
- (void)closePeripheral {
    [self.peripheralManager stopAdvertising];

}
/**
 创建通知服务,特征并添加服务到外围设备
 */
- (void)creatServiceOfNotify:(NSArray<NSString *>*)UUIDs {
    if (UUIDs.count==0) return;
//    for (NSString *theStr in UUIDs) {
//        CBUUID *UUID = [CBUUID UUIDWithString:theStr];
//        CBMutableCharacteristic *notifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:UUID properties:CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteEncryptionRequired];
//    }
}
/**
 创建只读服务,特征并添加服务到外围设备
 */
- (void)creatServiceOfOnlyRead:(NSArray<NSString *>*)UUIDs {

}
/**
 创建读写服务,特征并添加服务到外围设备
 */
- (void)creatServiceOfReadOrWrite:(NSArray<NSString *>*)UUIDs {

}
#pragma mark - private method

//创建服务,特征并添加服务到外围设备
- (void)setupService{
    //可读写的特征
    CBUUID *UUID2 = [CBUUID UUIDWithString:self.writeUUID];
    self.characteristic = [[CBMutableCharacteristic alloc] initWithType:UUID2 properties:CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteEncryptionRequired];
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:self.serviceUUID];
    self.service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    [self.service setCharacteristics:@[self.characteristic]];
    
    [self.peripheralManager addService:self.service];
    
    
}

@end
