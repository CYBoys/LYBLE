//
//  LYBLE.h
//  HiSchool
//
//  Created by chairman on 16/5/8.
//  Copyright © 2016年 LaiYoung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
@protocol BLECentralDelegate <NSObject>
@required
/**
 Scanning to all of the peripherals
 */
- (void)allPeripherals:(NSArray *)peripherals;
@optional

@end
//* CBCentralManager */
@interface LYBLE : NSObject


@property (nonatomic, copy) NSString *writeUUID;///<特征的UUID 读写
//@property (nonatomic, copy) NSString *serviceUUID;///<服务的UUID
//@property (nonatomic, copy) NSString *notifyUUID;///<特征的UUID 通知
//@property (nonatomic, copy) NSString *readUUID;///<特征的UUID 只读
@property (nonatomic, assign,getter=isConnect) BOOL connect;///<连接成功
@property (nonatomic, weak) id<BLECentralDelegate> centralManagerDelegate;
@property (nonatomic, strong) NSData *writeData;///<写入数据
+ (instancetype)shareManager;
/**
 扫描所有外设
 */
- (void)scanAllPeripheral;
/**
 停止扫描
 */
- (void)stopScan;

/**
 连接外围设备 
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral;
/**
 写数据到外设
 */
- (void)writeDataInPerpheral:(NSData *)data;
@end

//* --------------------------CBPeripheralManager---------------------------- */
@interface LYBLEPeripheral : NSObject
@property (nonatomic, copy) NSString *writeUUID;///<特征的UUID 读写
@property (nonatomic, copy) NSString *serviceUUID;///<服务的UUID
@property (nonatomic, copy) NSString *notifyUUID;///<特征的UUID 通知
@property (nonatomic, copy) NSString *readUUID;///<特征的UUID 只读
@property (nonatomic, copy) NSString *peripheralName;///<外围设备名称
/**
 开启外围服务
 */
- (void)openPeripheral;
/** 
 关闭外围服务
 */
- (void)closePeripheral;
/**
 创建通知服务,特征并添加服务到外围设备
 */
- (void)creatServiceOfNotify:(NSArray<NSString *>*)UUIDs;
/**
 创建只读服务,特征并添加服务到外围设备
 */
- (void)creatServiceOfOnlyRead:(NSArray<NSString *>*)UUIDs;
/**
 创建读写服务,特征并添加服务到外围设备
 */
- (void)creatServiceOfReadOrWrite:(NSArray<NSString *>*)UUIDs;
@end


