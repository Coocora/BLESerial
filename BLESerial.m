#import "BLESerial.h"

@interface BLESerial () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager      *centralManager;  
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral; 

@end


@implementation BLESerial

- (id)init
{
	self = [super init];
	if (self) {
		// Start up the CBCentralManager  
		_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];  
	}
}

- (void)scanStart
{
	[self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kTRANSFER_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

- (void)scanStop
{
	[self.centralManager stopScan];
}

- (void)connectPeripheral:(CBPeripheral*)peripheral
{
	[self.centralManager connectPeripheral:peripheral options:nil];
}

// �ҵ��豸ί�з���. ע������ÿ�ҵ�һ���豸�ͻᱻ����  
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI  
{  
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);  
      
    // Ok, it's in range - have we already seen it?  
    if (self.discoveredPeripheral != peripheral) {  
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it  
        self.discoveredPeripheral = peripheral;
    }  
}  

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
}

// �Ѿ�����֪ͨ, ������ֱ��֪ͨ�ϲ�, ���ǵȵ��ҵ�ָ����Characteristics��֪ͨ
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
 
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kTRANSFER_SERVICE_UUID]]];
}

// �ҵ����Ǹո�ָ���ķ���
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kTRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}

// �ҵ����Ǹո�ָ��������
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kTRANSFER_CHARACTERISTIC_UUID]]) {
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
			
			[self.delegate didConnectPeripheral:peripheral];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kTRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}
 
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    self.discoveredPeripheral = nil;
}


@end