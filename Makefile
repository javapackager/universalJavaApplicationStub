CC = clang

CFLAGS = -Wall -Werror -g
CFLAGS_ARM64 = -target arm64-apple-macos11
CFLAGS_X86_64 = -target x86_64-apple-macos10.12
LIBS = -lobjc -framework Foundation -framework AppKit
INCLUDES =

SRCS = src/nativeStub.m
OBJS = $(SRCS:src/%.m=build/%.o)
OBJS_ARM64 = $(SRCS:src/%.m=build/arm64/%.o)
OBJS_X86_64 = $(SRCS:src/%.m=build/x86_64/%.o)

# define the executable file
APP_NAME = nativeJavaApplicationStub
MAIN = build/$(APP_NAME)
MAIN_ARM64 = build/arm64/$(APP_NAME)
MAIN_X86_64 = build/x86_64/$(APP_NAME)
MAIN_UNIVERSAL = build/universal/$(APP_NAME)

.PHONY: depend clean

default: $(MAIN)
universal: $(MAIN_UNIVERSAL)

$(MAIN): $(OBJS)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $^ $(LFLAGS) $(LIBS)

$(MAIN_ARM64): $(OBJS_ARM64)
	$(CC) $(CFLAGS) $(CFLAGS_ARM64) $(INCLUDES) -o $@ $^ $(LFLAGS) $(LIBS)

$(MAIN_X86_64): $(OBJS_X86_64)
	$(CC) $(CFLAGS) $(CFLAGS_X86_64) $(INCLUDES) -o $@ $^ $(LFLAGS) $(LIBS)

$(MAIN_UNIVERSAL): $(MAIN_ARM64) $(MAIN_X86_64)
	@mkdir -p build/universal
	lipo -create -output $@ $^

build/%.o: src/%.m
	@mkdir -p build
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

build/arm64/%.o: src/%.m
	@mkdir -p build/arm64
	$(CC) $(CFLAGS) $(INCLUDES) $(CFLAGS_ARM64) -c $< -o $@

build/x86_64/%.o: src/%.m
	@mkdir -p build/x86_64
	$(CC) $(CFLAGS) $(INCLUDES) $(CFLAGS_X86_64) -c $< -o $@

clean:
	rm -rf build/

depend: $(SRCS)
	makedepend $(INCLUDES) $^

# DO NOT DELETE THIS LINE -- make depend needs it