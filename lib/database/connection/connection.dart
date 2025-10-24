// This file uses conditional exports to expose the right connection factory.
//
// It is not meant to be imported directly, but through a file that barrel-exports it.

export 'stub.dart'
    if (dart.library.io) 'native.dart'
    if (dart.library.html) 'web.dart';
