#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BLESerialDelegate;

@interface BLESerial

@property (nonatomic, weak) id<BLESerialDelegate> delegate;

- (void)scanStart;
- (void)scanStop;
- (void)connectPeripheral:(CBPeripheral*)peripheral;
- (void)disconnectPeripheral:(CBPeripheral*)peripheral;
- (void)sendValue:(CBPeripheral*)peripheral sendData:(NSData *)data type:(CBCharacteristicWriteType)type;
@end

@protocol BLESerialDelegate <NSObject>
- (void)didScanedPeripherals:(NSMutableArray  *)foundPeripherals;
- (void)didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void)didReceiveData:(CBPeripheral *)peripheral recvData:(NSData *)recvData;
@end