/// Code-Ausführung je Plattform: am Handy über eine WebView, im Browser
/// direkt über JavaScript.
library;

export 'platform_runners_native.dart'
    if (dart.library.js_interop) 'platform_runners_web.dart';
