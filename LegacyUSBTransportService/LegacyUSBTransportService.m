//
//  LegacyUSBTransportService.m
//  LegacyUSBTransportService
//
//  Created by Matt on 6/29/16.
//

#import "LegacyUSBTransportService.h"

#import "LegacyUSBTransportService-Swift.h"

#import <IOKit/usb/IOUSBLib.h>

#define READ_BUFFER_LEN 64

@interface LegacyUSBTransportService ()
@property IOReturn readResult;
@property IOReturn writeResult;
@end

@implementation LegacyUSBTransportService {
	IOUSBDeviceInterface **_device;
	IOUSBInterfaceInterface **_interface;
	IONotificationPortRef _notificationPort;
	io_object_t _registeredNotification;
	NSDictionary<NSNumber *, NSMutableArray< NSNumber *> *> *_pipes;
	io_service_t _service;
	uint8_t _readBuffer[READ_BUFFER_LEN];

	dispatch_semaphore_t _readSemaphore;
	dispatch_semaphore_t _writeSemaphore;
}

static dispatch_time_t TenSecondTimeout()
{
	return dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10);
}

static CFMutableDictionaryRef CreateMatchingDictionaryForSerialNumber(NSString *serialNumber)
{
	CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
	CFDictionarySetValue(matchingDict, CFSTR(kUSBSerialNumberString), (__bridge CFStringRef)serialNumber);

	return matchingDict;
}

static io_service_t CreateServiceWithSerialNumber(NSString *serialNumber)
{
	CFMutableDictionaryRef matchingDict = CreateMatchingDictionaryForSerialNumber(serialNumber);

	io_iterator_t iterator;
	if (IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator) != kIOReturnSuccess) {
		return IO_OBJECT_NULL;
	}

	io_service_t device;
	while ((device = IOIteratorNext(iterator))) {
		// Returns the first device.
		return device;
	}

	return IO_OBJECT_NULL;
}

#pragma mark - Device Setup

- (instancetype)initWithDelegate:(id<LegacyUSBTransportServiceDelegate>)delegate
{
	if (!(self = [super init])) {
		return nil;
	}

	_delegate = delegate;

	_writeSemaphore = dispatch_semaphore_create(0);
	_pipes = @{
		@(kUSBIn): [NSMutableArray array],
		@(kUSBOut): [NSMutableArray array],
		@(kUSBNone): [NSMutableArray array],
		@(kUSBAnyDirn): [NSMutableArray array]
	};

	return self;
}

- (IOReturn)_createServiceWithIdentifier:(NSString *)identifier
{
	_service = CreateServiceWithSerialNumber(identifier);

	if (_service == IO_OBJECT_NULL) {
		return kIOReturnNotReady;
	}

	return kIOReturnSuccess;
}

- (IOReturn)_setUpDevice
{
	IOCFPlugInInterface **plugInInterface = NULL;
	SInt32 score = 0;
	IOReturn result = IOCreatePlugInInterfaceForService(_service, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);

	if (result != kIOReturnSuccess) {
		return result;
	}

	HRESULT herr = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID *)&_device);

	(*plugInInterface)->Release(plugInInterface);

	if (herr != S_OK) {
		return kIOReturnNotReady;
	}

	result = (*_device)->USBDeviceOpen(_device);
	return result;
}

- (void)_cleanUpDevice
{
	if (_device) {
		(*_device)->USBDeviceClose(_device);
		(*_device)->Release(_device);
		_device = NULL;
	}
}

- (IOReturn)_setUpInterfaceWithService:(io_service_t)service
{
	IOCFPlugInInterface **plugInInterface = NULL;
	SInt32 score = 0;
	IOReturn result = IOCreatePlugInInterfaceForService(service, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);

	if (result != kIOReturnSuccess) {
		return result;
	}

	HRESULT herr = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), (LPVOID *)&_interface);
	(*plugInInterface)->Release(plugInInterface);

	if (herr != S_OK) {
		return kIOReturnNotReady;
	}

	return kIOReturnSuccess;
}

- (void)_cleanUpInterface
{
	if (_interface) {
		(*_interface)->USBInterfaceClose(_interface);
		(*_interface)->Release(_interface);
		_interface = NULL;
	}
}

- (IOReturn)_setUpInterfaces
{
	IOUSBFindInterfaceRequest request;
	bzero(&request, sizeof(request));
	request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
	request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
	request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
	request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;

	io_iterator_t iterator = IO_OBJECT_NULL;
	IOReturn result = (*_device)->CreateInterfaceIterator(_device, &request, &iterator);

	if (result != kIOReturnSuccess) {
		return result;
	}

	io_service_t interface = IO_OBJECT_NULL;
	while ((interface = IOIteratorNext(iterator))) {
		IOReturn interfaceResult = [self _setUpInterfaceWithService:interface];

		if (interfaceResult != kIOReturnSuccess) {
			IOObjectRelease(iterator);
			return interfaceResult;
		}

		break; // only setup first interface for now
	}

	IOObjectRelease(iterator);

	return kIOReturnSuccess;
}

- (IOReturn)_openInterface
{
	return (*_interface)->USBInterfaceOpen(_interface);
}

- (IOReturn)_openPipes
{
	UInt8 endpoints = 0;
	IOReturn result = (*_interface)->GetNumEndpoints(_interface, &endpoints);

	if (result != kIOReturnSuccess) {
		return result;
	}

	// ignore pipe 0 (control pipe)
	for (UInt8 n = 1; n <= endpoints; n++) {
		UInt8 direction = 0, number = 0, transferType = 0, interval = 0;
		UInt16 maxPacketSize = 0;

		result = (*_interface)->GetPipeProperties(_interface, n, &direction, &number, &transferType, &maxPacketSize, &interval);

		if (result != kIOReturnSuccess) {
			return result;
		}

		if (transferType == kUSBBulk && (direction == kUSBIn || direction == kUSBOut)) {
			NSMutableArray *const pipes = _pipes[@(direction)];
			[pipes addObject:@(number)];
		}
	}

	return kIOReturnSuccess;
}

- (IOReturn)_setUpAsyncIO
{
	CFRunLoopSourceRef source = NULL;
	IOReturn result = (*_interface)->CreateInterfaceAsyncEventSource(_interface, &source);

	if (result != kIOReturnSuccess) {
		return result;
	}

	CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
	return kIOReturnSuccess;
}

- (void)_setUpInterestNotification
{
	if (!_notificationPort) {
		_notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
		CFRunLoopSourceRef source = IONotificationPortGetRunLoopSource(_notificationPort);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
	}

	IOServiceAddInterestNotification(_notificationPort, _service, kIOGeneralInterest, &DeviceNotification, (__bridge void *)self, &_registeredNotification);
}

- (void)_cleanUpNotification
{
	if (_registeredNotification != IO_OBJECT_NULL) {
		IOObjectRelease(_registeredNotification);
		_registeredNotification = IO_OBJECT_NULL;
	}
}

#pragma mark - Utility

- (void)_didReadBytesWithResult:(IOReturn)result number:(UInt32)number
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (result == kIOReturnSuccess) {
		[self.delegate handleData:[NSData dataWithBytes:_readBuffer length:sizeof(_readBuffer)]];
	}
	
	self.readResult = result;
	dispatch_semaphore_signal(_readSemaphore);
}

- (void)_didWriteDataWithResult:(IOReturn)result
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	self.writeResult = result;
	dispatch_semaphore_signal(_writeSemaphore);
}

static void ReadCompletion(void *refCon, IOReturn result, void *arg0)
{
	LegacyUSBTransportService *const self = (__bridge LegacyUSBTransportService *)refCon;
	const size_t bytesRead = (size_t)arg0;

	[self _didReadBytesWithResult:result number:(UInt32)bytesRead];
}

static void WriteCompletion(void *refCon, IOReturn result, void *arg0)
{
	LegacyUSBTransportService *const self = (__bridge LegacyUSBTransportService *)refCon;
	[self _didWriteDataWithResult:result];
}

static void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{
	LegacyUSBTransportService *const self = (__bridge LegacyUSBTransportService *)refCon;

	if (messageType == kIOMessageServiceIsTerminated) {
		// TODO: [self close];
	}
}

#pragma mark -

- (IOReturn)_actuallyOpen:(NSString *)identifier
{
	IOReturn result = [self _createServiceWithIdentifier:identifier];

	if (result != kIOReturnSuccess) {
		return result;
	}

	result = [self _setUpDevice];

	if (result != kIOReturnSuccess) {
		return result;
	}

	result = [self _setUpInterfaces];

	if (result != kIOReturnSuccess) {
		return result;
	}

	result = [self _openInterface];

	if (result != kIOReturnSuccess) {
		return result;
	}

	result = [self _openPipes];

	if (result != kIOReturnSuccess) {
		return result;
	}

	result = [self _setUpAsyncIO];

	if (result != kIOReturnSuccess) {
		return result;
	}

	[self _setUpInterestNotification];

	return kIOReturnSuccess;
}

- (void)open:(NSString *)identifier handler:(void (^)(NSInteger))handler
{
	__block IOReturn result = kIOReturnError;
	NSString *const safeIdentifier = [identifier copy];

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyOpen:safeIdentifier];
	});

	handler(result);
}

- (void)_actuallyClose
{
	[self _cleanUpInterface];
	[self _cleanUpDevice];
	[self _cleanUpNotification];

	for (NSMutableArray *array in _pipes.allValues) {
		[array removeAllObjects];
	}
}

- (void)close:(NSString *)identifier handler:(void (^)(NSInteger))handler
{
	// TODO: Handle identifier
	dispatch_sync(dispatch_get_main_queue(), ^{
		[self _actuallyClose];
	});

	handler(kIOReturnSuccess);
}

- (IOReturn)_actuallyWriteData:(NSData *)data identifier:(NSString *)identifier
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (_service == IO_OBJECT_NULL) {
		return kIOReturnNotOpen;
	}

	NSString *const serialNumber = (__bridge NSString *)IORegistryEntrySearchCFProperty(_service, kIOServicePlane, CFSTR(kUSBSerialNumberString), kCFAllocatorDefault, kIORegistryIterateRecursively);

	if (![serialNumber isEqualToString:identifier]) {
		return kIOReturnNotFound;
	}

	NSArray<NSNumber *> *const outPipes = _pipes[@(kUSBOut)];

	if (outPipes.count == 0) {
		return kIOReturnNotWritable;
	}

	const UInt8 outNum = (UInt8)[outPipes[0] intValue]; // write to first out pipe for now
	return (*_interface)->WritePipeAsync(_interface, outNum, (void *)data.bytes, (UInt32)data.length, &WriteCompletion, (__bridge void *)self);
}

- (void)writeData:(NSData *)data identifier:(NSString *)identifier handler:(void (^)(NSInteger))handler
{
	// TODO: check if open
	__block IOReturn result = kIOReturnError;

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyWriteData:data identifier:identifier];
	});

	if (result != kIOReturnSuccess) {
		handler(result);
		return;
	}

	if (dispatch_semaphore_wait(_writeSemaphore, TenSecondTimeout()) != 0) {
		handler(kIOReturnTimeout);
		return;
	}

	handler(self.writeResult);
}

- (IOReturn)_actuallyScheduleRead
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	NSArray<NSNumber *> *const inPipes = _pipes[@(kUSBIn)];

	if (inPipes.count == 0) {
		return kIOReturnNotReadable;
	}

	const UInt8 inNum = (UInt8)[inPipes[0] intValue]; // read from the first in pipe for now
	bzero(_readBuffer, sizeof(_readBuffer));

	return (*_interface)->ReadPipeAsync(_interface, inNum, _readBuffer, READ_BUFFER_LEN, &ReadCompletion, (__bridge void *)self);
}

- (void)scheduleRead:(void (^)(NSInteger))handler
{
	// TODO: check if open
	// TODO: take identifier?
	__block IOReturn result = kIOReturnError;

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyScheduleRead];
	});

	if (result != kIOReturnSuccess) {
		handler(result);
		return;
	}

	if (dispatch_semaphore_wait(_readSemaphore, TenSecondTimeout()) != 0) {
		handler(kIOReturnTimeout);
		return;
	}

	handler(self.readResult);
}

@end
