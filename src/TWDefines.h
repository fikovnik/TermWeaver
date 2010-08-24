/*
 Copyright (c) 2010 Filip Krikava
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

// following assertions were taken from: GMTDefines.h from the google-mac-toolbox:
// http://code.google.com/p/google-toolbox-for-mac/

#ifndef TWDevLog

#ifndef NDEBUG
#define TWDevLog(...) NSLog(__VA_ARGS__)
#else
#define TWDevLog(...) do { } while (0)
#endif // NDEBUG

#endif // TWDevLog

#ifndef TWStr
#define TWStr(fmt,...) [NSString stringWithFormat:fmt,##__VA_ARGS__]
#endif TWStr // TWStr

#ifndef TWTraceLog

#ifndef NTRACE
#define TWTraceLog(...) NSLog(@"%@: %@",TWStr(@"[\%s:\%s:\%d]",__PRETTY_FUNCTION__,__FILE__,__LINE__),TWStr(__VA_ARGS__))
#define TWTrace() NSLog(@"[\%s:\%s:\%d]",__PRETTY_FUNCTION__,__FILE__,__LINE__)
#endif // NTRACE

#endif // TWTraceLog

#ifndef TWAssert

#if !defined(NS_BLOCK_ASSERTIONS)

#define TWAssert(condition, ...)                                       \
do {                                                                      \
if (!(condition)) {                                                     \
[[NSAssertionHandler currentHandler]                                  \
handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] \
file:[NSString stringWithUTF8String:__FILE__]  \
lineNumber:__LINE__                                  \
description:__VA_ARGS__];                             \
}                                                                       \
} while(0)

#else // !defined(NS_BLOCK_ASSERTIONS)
#define TWAssert(condition, ...) do { } while (0)
#endif // !defined(NS_BLOCK_ASSERTIONS)

#endif // TWAssert

#ifndef TWFail

#define TWFail(...) TWAssert(NO,##__VA_ARGS__)

#endif // TWFail

// TODO refactor
static inline BOOL isEmpty(id thing) {
    return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}
