# AndroidAPSBuilder
Utilities to build AndroidAPS apk

For Windows 10 Users:

Right-click buildAndroidAPS.bat and look for "Allow" checkbox and check it!


Small HowTo:

1.) If you use win 7,8 or 8.1 -> update powershell with first menu entry, then restart computer.

2.) Install Git, then JDK, then Android SDK, if you want you can Install AndroidStudio too but this step is oprtional.

3.) clone aaps, then switch to dev branch. With switch to dev branch you can also update your local repo to latest dev branch if there is an update.

4.) select build and build what you want. the debug apk's are signed with debug key. 

5.) create a signing keystore.

6.) sign your release apk's or debug apk's. if you sign booth you can always switch between debug.apk and release.apk, because they have the same key. if you not sign debug.apk with the release key you have to uninstall the debug.apk before installing a release.apk.

7.) select install apk and connect your phone. you can select which apk to install.
