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

@interface ServiceAndSemaphore : NSObject

@property (weak) LegacyUSBTransportService *service;
@property dispatch_semaphore_t semaphore;
@property ServiceAndSemaphore *selfLoop;

@end


@implementation ServiceAndSemaphore
@end


@interface LegacyUSBTransportService ()
@property IOReturn readResult;
@property IOReturn writeResult;
@end

@implementation LegacyUSBTransportService {
	io_service_t _service;
	IOUSBDeviceInterface **_device;
	IOUSBInterfaceInterface **_interface;
	CFRunLoopSourceRef _runLoopSource;
	io_object_t _registeredNotification;
	NSDictionary<NSNumber *, NSMutableArray<NSNumber *> *> *_pipes;
	uint8_t _readBuffer[READ_BUFFER_LEN];

	// Shared
	IONotificationPortRef _notificationPort;
	NSInteger _activeClients;
}

static dispatch_time_t TenSecondTimeout()
{
	return dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10);
}

static NSDictionary *__nullable MatchingDictionaryForSerialNumber(NSString *serialNumber)
{
	CFMutableDictionaryRef matchingDictCF = IOServiceMatching(kIOUSBDeviceClassName);

	if (matchingDictCF == NULL) {
		return nil;
	}

	return CFBridgingRelease(matchingDictCF);
}

static io_service_t CreateServiceWithSerialNumber(NSString *serialNumber)
{
	NSDictionary *__nullable matchingDict = MatchingDictionaryForSerialNumber(serialNumber);

	if (matchingDict == nil) {
		return IO_OBJECT_NULL;
	}

	io_iterator_t iterator = IO_OBJECT_NULL;
	if (IOServiceGetMatchingServices(kIOMasterPortDefault, CFBridgingRetain(matchingDict), &iterator) != kIOReturnSuccess) {
		return IO_OBJECT_NULL;
	}

	io_service_t device = IO_OBJECT_NULL;
	while ((device = IOIteratorNext(iterator))) {
		NSString *deviceSerialNumber = CFBridgingRelease(IORegistryEntrySearchCFProperty(device, kIOServicePlane, CFSTR(kUSBSerialNumberString), kCFAllocatorDefault, kIORegistryIterateRecursively));
		if ([deviceSerialNumber isEqualToString:serialNumber]) {
			IOObjectRelease(iterator);
			return device;
		}

		IOObjectRelease(device);
	}

	IOObjectRelease(iterator);

	return IO_OBJECT_NULL;
}

- (instancetype)initWithDelegate:(id<LegacyUSBTransportServiceDelegate>)delegate
{
	if (!(self = [super init])) {
		return nil;
	}

	_delegate = delegate;
	_pipes = @{
		@(kUSBIn): [NSMutableArray array],
		@(kUSBOut): [NSMutableArray array],
		@(kUSBNone): [NSMutableArray array],
		@(kUSBAnyDirn): [NSMutableArray array]
	};

	return self;
}

#pragma mark - Device Setup

- (IOReturn)_createServiceWithIdentifier:(NSString *)identifier
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");
	NSAssert(_service == IO_OBJECT_NULL, @"We already have a service");

	_service = CreateServiceWithSerialNumber(identifier);

	if (_service == IO_OBJECT_NULL) {
		return kIOReturnNotReady;
	}

	return kIOReturnSuccess;
}

- (void)_cleanUpService
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (_service != IO_OBJECT_NULL) {
		IOObjectRelease(_service);
		_service = IO_OBJECT_NULL;
	}
}

- (IOReturn)_setUpDevice
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

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
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (_device != NULL) {
		(*_device)->USBDeviceClose(_device);
		(*_device)->Release(_device);
		_device = NULL;
	}
}

- (IOReturn)_setUpInterfaceWithService:(io_service_t)service
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

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

	return (*_interface)->USBInterfaceOpen(_interface);
}

- (void)_cleanUpInterface
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (_interface != NULL) {
		(*_interface)->USBInterfaceClose(_interface);
		(*_interface)->Release(_interface);
		_interface = NULL;
	}
}

- (IOReturn)_setUpInterfaces
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

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

- (IOReturn)_openPipes
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

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

- (void)_cleanUpPipes
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	for (NSMutableArray *array in _pipes.allValues) {
		[array removeAllObjects];
	}
}

- (IOReturn)_setUpAsyncIO
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	CFRunLoopSourceRef source = NULL;
	const IOReturn result = (*_interface)->CreateInterfaceAsyncEventSource(_interface, &source);

	if (result != kIOReturnSuccess) {
		return result;
	}

	_runLoopSource = source;

	CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
	return kIOReturnSuccess;
}

- (void)_cleanUpAsyncIO
{
	if (_runLoopSource != NULL) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
		CFRelease(_runLoopSource);
		_runLoopSource = NULL;
	}
}

- (void)_setUpInterestNotification
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (!_notificationPort) {
		_notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
		CFRunLoopSourceRef source = IONotificationPortGetRunLoopSource(_notificationPort);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
	}

	IOServiceAddInterestNotification(_notificationPort, _service, kIOGeneralInterest, &DeviceNotification, (__bridge void *)self, &_registeredNotification);
}

- (void)_cleanUpNotification
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (_registeredNotification != IO_OBJECT_NULL) {
		IOObjectRelease(_registeredNotification);
		_registeredNotification = IO_OBJECT_NULL;
	}
}

#pragma mark - Utility

- (void)_didReadBytesWithResult:(IOReturn)result number:(UInt32)number semaphore:(dispatch_semaphore_t)semaphore
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (result == kIOReturnSuccess) {
		[self.delegate handleData:[NSData dataWithBytes:_readBuffer length:sizeof(_readBuffer)]];
	}
	
	self.readResult = result;
	dispatch_semaphore_signal(semaphore);
}

- (void)_didWriteDataWithResult:(IOReturn)result semaphore:(dispatch_semaphore_t)semaphore
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	self.writeResult = result;
	dispatch_semaphore_signal(semaphore);
}

static void ReadCompletion(void *refCon, IOReturn result, void *arg0)
{
	ServiceAndSemaphore *const tuple = (__bridge ServiceAndSemaphore *)refCon;
	const size_t bytesRead = (size_t)arg0;

	[tuple.service _didReadBytesWithResult:result number:(UInt32)bytesRead semaphore:tuple.semaphore];
	tuple.selfLoop = nil;
}

static void WriteCompletion(void *refCon, IOReturn result, void *arg0)
{
	ServiceAndSemaphore *const tuple = (__bridge ServiceAndSemaphore *)refCon;
	[tuple.service _didWriteDataWithResult:result semaphore:tuple.semaphore];
	tuple.selfLoop = nil;
}

static void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{
	LegacyUSBTransportService *const self = (__bridge LegacyUSBTransportService *)refCon;

	if (messageType == kIOMessageServiceIsTerminated) {
		// TODO: [self close];
	}
}

#pragma mark -

- (IOReturn)_runOpenDanceWithIdentifier:(NSString *)identifier
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	IOReturn result = [self _createServiceWithIdentifier:identifier];

	if (result != kIOReturnSuccess) {
		return result;
	}

	result = [self _setUpDevice];

	if (result != kIOReturnSuccess) {
		[self _cleanUpService];
		return result;
	}

	result = [self _setUpInterfaces];

	if (result != kIOReturnSuccess) {
		[self _cleanUpDevice];
		[self _cleanUpService];
		return result;
	}

	result = [self _openPipes];

	if (result != kIOReturnSuccess) {
		[self _cleanUpInterface];
		[self _cleanUpDevice];
		[self _cleanUpService];
		[self _cleanUpPipes];
		return result;
	}

	result = [self _setUpAsyncIO];

	if (result != kIOReturnSuccess) {
		[self _cleanUpInterface];
		[self _cleanUpDevice];
		[self _cleanUpService];
		[self _cleanUpPipes];
		return result;
	}

	[self _setUpInterestNotification];

	return kIOReturnSuccess;
}

- (IOReturn)_actuallyOpen:(NSString *)identifier
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (self._isOpen) {
		if (![self._currentSerialNumberString isEqualToString:identifier]) {
			// Tried to open a new device while another one was already open.
			return kIOReturnBusy;
		}
	} else {
		const IOReturn result = [self _runOpenDanceWithIdentifier:identifier];

		if (result != kIOReturnSuccess) {
			return result;
		}
	}

	_activeClients += 1;
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

- (IOReturn)_actuallyCloseWithIdentifier:(NSString *)identifier
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (!self._isOpen) {
		return kIOReturnNotOpen;
	}

	if (![self._currentSerialNumberString isEqualToString:identifier]) {
		// Device mismatch.
		return kIOReturnInternalError;
	}

	_activeClients -= 1;
	NSAssert(_activeClients >= 0, @"Mismatched client counting");

	if (_activeClients == 0) {
		[self _cleanUpNotification];
		[self _cleanUpAsyncIO];
		[self _cleanUpInterface];
		[self _cleanUpDevice];
		[self _cleanUpService];
		[self _cleanUpPipes];
	}

	return kIOReturnSuccess;
}

- (void)close:(NSString *)identifier handler:(void (^)(NSInteger))handler
{
	NSString *const safeIdentifier = [identifier copy];
	__block IOReturn result = kIOReturnError;

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyCloseWithIdentifier:safeIdentifier];
	});

	handler(result);
}

- (BOOL)_isOpen
{
	return _service != IO_OBJECT_NULL && _interface != NULL;
}

- (NSString *)_currentSerialNumberString
{
	return (__bridge NSString *)IORegistryEntrySearchCFProperty(_service, kIOServicePlane, CFSTR(kUSBSerialNumberString), kCFAllocatorDefault, kIORegistryIterateRecursively);
}

- (IOReturn)_actuallyWriteData:(NSData *)data identifier:(NSString *)identifier semaphore:(dispatch_semaphore_t)semaphore
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (!self._isOpen) {
		return kIOReturnNotOpen;
	}

	if (![self._currentSerialNumberString isEqualToString:identifier]) {
		return kIOReturnNotFound;
	}

	NSArray<NSNumber *> *const outPipes = _pipes[@(kUSBOut)];

	if (outPipes.count == 0) {
		return kIOReturnNotWritable;
	}

	const UInt8 outNum = (UInt8)[outPipes[0] intValue]; // write to first out pipe for now

	ServiceAndSemaphore *tuple = [[ServiceAndSemaphore alloc] init];
	tuple.service = self;
	tuple.semaphore = semaphore;
	tuple.selfLoop = tuple;
	return (*_interface)->WritePipeAsync(_interface, outNum, (void *)data.bytes, (UInt32)data.length, &WriteCompletion, (__bridge void *)tuple);
}

- (void)writeData:(NSData *)data identifier:(NSString *)identifier handler:(void (^)(NSInteger))handler
{
	__block IOReturn result = kIOReturnError;

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	NSString *const safeIdentifier = [identifier copy];

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyWriteData:data identifier:safeIdentifier semaphore:semaphore];
	});

	if (result != kIOReturnSuccess) {
		handler(result);
		return;
	}

	if (dispatch_semaphore_wait(semaphore, TenSecondTimeout()) != 0) {
		handler(kIOReturnTimeout);
		return;
	}

	handler(self.writeResult);
}

- (IOReturn)_actuallyScheduleReadWithIdentifier:(NSString *)identifier semaphore:(dispatch_semaphore_t)semaphore
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (!self._isOpen) {
		return kIOReturnNotOpen;
	}

	if (![self._currentSerialNumberString isEqualToString:identifier]) {
		return kIOReturnNotFound;
	}

	NSArray<NSNumber *> *const inPipes = _pipes[@(kUSBIn)];

	if (inPipes.count == 0) {
		return kIOReturnNotReadable;
	}

	const UInt8 inNum = (UInt8)[inPipes[0] intValue]; // read from the first in pipe for now
	bzero(_readBuffer, sizeof(_readBuffer));

	ServiceAndSemaphore *tuple = [[ServiceAndSemaphore alloc] init];
	tuple.service = self;
	tuple.semaphore = semaphore;
	tuple.selfLoop = tuple;
	return (*_interface)->ReadPipeAsync(_interface, inNum, _readBuffer, READ_BUFFER_LEN, &ReadCompletion, (__bridge void *)tuple);
}

- (void)scheduleRead:(NSString *)identifier handler:(void (^)(NSInteger))handler
{
	__block IOReturn result = kIOReturnError;

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	NSString *const safeIdentifier = [identifier copy];

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyScheduleReadWithIdentifier:safeIdentifier semaphore:semaphore];
	});

	if (result != kIOReturnSuccess) {
		handler(result);
		return;
	}

	if (dispatch_semaphore_wait(semaphore, TenSecondTimeout()) != 0) {
		handler(kIOReturnTimeout);
		return;
	}

	handler(self.readResult);
}

@end
