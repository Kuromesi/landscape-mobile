generate:
	dart run build_runner build
	
release:
	flutter build apk --release

debug:
	flutter build apk --debug