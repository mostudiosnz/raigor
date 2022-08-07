# Raigor

A wrapper around [FirebaseCrashlytics](https://github.com/firebase/firebase-ios-sdk) logging used throughout MO Studios iOS projects.

## Install

Use Swift Package Manager to install.

## Usage

A Singleton `Logger` object is provided. The logger will automatically upload logs to firebase crashlytics. 

`Logger.log(...)` is stored as a log inside a crashlytics issue.

`Logger.error(...)` is stored as a non-fatal issue in crashlytics.
