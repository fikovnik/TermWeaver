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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface TWHotKey : NSObject {
	@private
	NSInteger mId;
	NSInteger mKeyCode;
	NSInteger mModifiers;
	SEL mHandler;
	id mProvider;
	id mUserData;
}

@property (assign, getter=id, setter=setId) NSInteger mId;
@property (assign, readonly, getter=keyCode) NSInteger mKeyCode;
@property (assign, readonly, getter=modifiers) NSInteger mModifiers;
@property (assign, readonly, getter=handler) SEL mHandler;
@property (retain, readonly, getter=provider) id mProvider;
@property (retain, readonly, getter=userData) id mUserData;

- (id) initWithKeyCode:(NSInteger)keyCode modifiers:(NSInteger)modifiers handler:(SEL)handler provider:(id)provider userData:(id)userData;

@end
