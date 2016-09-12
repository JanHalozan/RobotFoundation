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
@property void *data;

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
	BOOL _scheduledDeferredClose;

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

- (instancetype)initWithDelegate:(id<TransportClientProtocol>)delegate
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

- (void)dealloc
{
	[self.class cancelPreviousPerformRequestsWithTarget:self];
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

- (void)_didReadBytesWithResult:(IOReturn)result number:(UInt32)number buffer:(uint8_t *)buffer semaphore:(dispatch_semaphore_t)semaphore
{
	NSAssert(NSThread.isMainThread, @"Unexpected thread");

	if (result == kIOReturnSuccess) {
		[self.delegate handleTransportData:[NSData dataWithBytes:buffer length:READ_BUFFER_LEN]];
	}

	if (buffer != NULL) {
		free(buffer);
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

	[tuple.service _didReadBytesWithResult:result number:(UInt32)bytesRead buffer:tuple.data semaphore:tuple.semaphore];
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
		NSLog(@"%s: the service was terminated", __PRETTY_FUNCTION__);
		[self _reallyClose];
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

	if (_scheduledDeferredClose) {
		if ([self._currentSerialNumberString isEqualToString:identifier]) {
			// It's the same device! Just restore the connection we have.
			[self _cancelDeferredClose];
			_activeClients += 1;
#if DEBUG
			NSLog(@"%s: restoring a deferred close with %zd active clients", __PRETTY_FUNCTION__, _activeClients);
#endif
			return kIOReturnSuccess;
		} else {
			// Close now and open the new device.
			[self _cancelDeferredClose];
			[self _reallyClose];
		}
	}

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
#if DEBUG
	NSLog(@"%s: legacy USB transport increased active clients to %zd", __PRETTY_FUNCTION__, _activeClients);
#endif
	return kIOReturnSuccess;
}

- (BOOL)open:(NSString *)identifier handler:(void (^)(NSInteger))handler
{
	__block IOReturn result = kIOReturnError;
	NSString *const safeIdentifier = [identifier copy];

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyOpen:safeIdentifier];
	});

	if (result != kIOReturnSuccess) {
		NSLog(@"%s: the legacy USB device could not be opened (%d)", __PRETTY_FUNCTION__, result);
		handler(result);
		return NO;
	}

#if DEBUG
	NSLog(@"%s: opened the legacy USB device", __PRETTY_FUNCTION__);
#endif

	return YES;
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

#if DEBUG
	NSLog(@"%s: number of active clients in legacy USB service dropped to %zd", __PRETTY_FUNCTION__, _activeClients);
#endif

	if (_activeClients == 0) {
#if DEBUG
		NSLog(@"%s: scheduling a deferred close", __PRETTY_FUNCTION__);
#endif

		if (_scheduledDeferredClose) {
#if DEBUG
			NSLog(@"%s: cancelling previous deferred close", __PRETTY_FUNCTION__);
#endif
			[self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(_reallyClose) object:nil];
		}
		_scheduledDeferredClose = YES;

		[self performSelector:@selector(_reallyClose) withObject:nil afterDelay:10];
	}

	return kIOReturnSuccess;
}

- (void)_cancelDeferredClose
{
#if DEBUG
	NSLog(@"%s: cancelling a deferred close", __PRETTY_FUNCTION__);
#endif
	[self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(_reallyClose) object:nil];
	_scheduledDeferredClose = NO;
}

- (void)_reallyClose
{
	NSAssert(NSThread.isMainThread, @"%s: unexpected thread", __PRETTY_FUNCTION__);

#if DEBUG
	NSLog(@"%s: actually closing now!", __PRETTY_FUNCTION__);
#endif

	[self _cancelDeferredClose];

	[self _cleanUpNotification];
	[self _cleanUpAsyncIO];
	[self _cleanUpInterface];
	[self _cleanUpDevice];
	[self _cleanUpService];
	[self _cleanUpPipes];

	_activeClients = 0;
}

- (void)close:(NSString *)identifier
{
	NSString *const safeIdentifier = [identifier copy];
	__block IOReturn result = kIOReturnError;

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyCloseWithIdentifier:safeIdentifier];
	});
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
	if (![self open:identifier handler:handler]) {
		return;
	}

	__block IOReturn result = kIOReturnError;

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	NSString *const safeIdentifier = [identifier copy];

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyWriteData:data identifier:safeIdentifier semaphore:semaphore];
	});

	if (result != kIOReturnSuccess) {
		NSLog(@"%s: initiating writing to a legacy USB device failed (%d)", __PRETTY_FUNCTION__, result);
		[self close:identifier];
		handler(result);
		return;
	}

	if (dispatch_semaphore_wait(semaphore, TenSecondTimeout()) != 0) {
		NSLog(@"%s: writing to a legacy USB device timed out", __PRETTY_FUNCTION__);
		[self close:identifier];
		handler(kIOReturnTimeout);
		return;
	}

	const IOReturn writeResult = self.writeResult;
	if (writeResult != kIOReturnSuccess) {
		NSLog(@"%s: writing to a legacy USB device failed (%d)", __PRETTY_FUNCTION__, result);
		[self close:identifier];
		handler(writeResult);
		return;
	}

	NSLog(@"%s: finished writing to a legacy USB device", __PRETTY_FUNCTION__);

	[self close:identifier];
	handler(kIOReturnSuccess);
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

	uint8_t *readBuffer = calloc(READ_BUFFER_LEN, sizeof(uint8_t));
	ServiceAndSemaphore *tuple = [[ServiceAndSemaphore alloc] init];
	tuple.service = self;
	tuple.semaphore = semaphore;
	tuple.selfLoop = tuple;
	tuple.data = readBuffer;
	return (*_interface)->ReadPipeAsync(_interface, inNum, readBuffer, READ_BUFFER_LEN, &ReadCompletion, (__bridge void *)tuple);
}

- (void)scheduleRead:(NSString *)identifier handler:(void (^)(NSInteger))handler
{
	NSLog(@"%s: legacy USB service received read request", __PRETTY_FUNCTION__);

	if (![self open:identifier handler:handler]) {
		return;
	}

	__block IOReturn result = kIOReturnError;

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	NSString *const safeIdentifier = [identifier copy];

	dispatch_sync(dispatch_get_main_queue(), ^{
		result = [self _actuallyScheduleReadWithIdentifier:safeIdentifier semaphore:semaphore];
	});

	if (result != kIOReturnSuccess) {
		NSLog(@"%s: legacy USB service failed to read data (%d)", __PRETTY_FUNCTION__, result);
		[self close:identifier];
		handler(result);
		return;
	}

	if (dispatch_semaphore_wait(semaphore, TenSecondTimeout()) != 0) {
		NSLog(@"%s: legacy USB service timed out while reading data", __PRETTY_FUNCTION__);
		[self close:identifier];
		handler(kIOReturnTimeout);
		return;
	}

	NSLog(@"%s: legacy USB service finished reading data", __PRETTY_FUNCTION__);
	[self close:identifier];
	handler(self.readResult);
}

@end
