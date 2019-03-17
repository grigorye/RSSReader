//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#ifndef __loggy_os_log_shims_h__
#define __loggy_os_log_shims_h__

#include <os/log.h>

#if __has_include(<os/signpost.h>)
#define LOGGY_HAS_OS_SIGNPOST 1
#include <os/signpost.h>
#else
#define LOGGY_HAS_OS_SIGNPOST 0
#endif

OS_ASSUME_NONNULL_BEGIN

#define LOGGY_OS_LOG_ENCODER_MAX_COMMANDS   48
#define LOGGY_OS_LOG_ENCODER_BUF_SIZE       (2 + (2 + 16) * LOGGY_OS_LOG_ENCODER_MAX_COMMANDS)

typedef struct {
    uint8_t ob_b[LOGGY_OS_LOG_ENCODER_BUF_SIZE];
    uint32_t ob_len;
} loggy_os_log_encoder_s OS_SWIFT_NAME(LogStatementEncoder), *loggy_os_log_encoder_t;

OS_ALWAYS_INLINE OS_INLINE OS_SWIFT_NAME(getter:LogStatementEncoder.currentReturnAddress())
void *loggy_os_log_return_address(void) {
    return __builtin_return_address(1);
}

OS_SWIFT_NAME(LogStatementEncoder.append(self:_:))
void loggy_os_log_encoder_add_int32(loggy_os_log_encoder_t encoder, int32_t value);

OS_SWIFT_NAME(LogStatementEncoder.append(self:_:))
void loggy_os_log_encoder_add_int64(loggy_os_log_encoder_t encoder, int64_t value);

OS_SWIFT_NAME(LogStatementEncoder.append(self:_:))
void loggy_os_log_encoder_add_int(loggy_os_log_encoder_t encoder, size_t value);

OS_SWIFT_NAME(LogStatementEncoder.append(self:_:precision:))
void loggy_os_log_encoder_add_double(loggy_os_log_encoder_t encoder, double value, int precision);

OS_SWIFT_NAME(LogStatementEncoder.append(self:_:))
void loggy_os_log_encoder_add_object(loggy_os_log_encoder_t encoder, const void *value);

OS_SWIFT_NAME(LogStatementEncoder.__send(self:format:to:at:fromAddress:containingBinary:)) OS_REFINED_FOR_SWIFT
void loggy_os_log_send(loggy_os_log_encoder_t encoder, const char *fmt, os_log_t h, os_log_type_t type, const void *ra, const void *dso);

#if LOGGY_HAS_OS_SIGNPOST

#define LOGGY_OS_SIGNPOST_AVAILABILITY API_AVAILABLE(macosx(10.14), ios(12.0), tvos(12.0), watchos(5.0))

LOGGY_OS_SIGNPOST_AVAILABILITY OS_REFINED_FOR_SWIFT
OS_SWIFT_NAME(LogStatementEncoder.__send(self:format:to:for:name:id:fromAddress:containingBinary:))
void loggy_os_signpost_send(loggy_os_log_encoder_t encoder, const char *fmt, os_log_t h, os_signpost_type_t spty, const uint8_t *_Nullable spnm, os_signpost_id_t spid, const void *ra, const void *dso);

#endif

OS_ASSUME_NONNULL_END

#endif /* __loggy_os_log_shims_h__ */
