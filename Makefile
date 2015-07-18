record-screen: main.m
	cc -o $@ $< -fobjc-arc -Wall -framework Foundation -framework AVFoundation -framework ApplicationServices -framework CoreVideo -framework CoreMedia -framework AppKit
