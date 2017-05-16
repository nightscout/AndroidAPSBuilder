# AndroidAPSBuilder
Utilities to build AndroidAPS apk

Small HowTo:

For Windows 10 Users: Right-click buildAndroidAPS.bat and look for "Allow" checkbox and check it!

1.) If you use win 7,8 or 8.1 -> update powershell with first menu entry, then restart computer.

2.) Install Git, then JDK, then Android SDK, if you want you can Install AndroidStudio too but this step is oprtional.

3.) clone aaps, then switch to dev branch if you want. 

4.) With switch or update local branch you can update your local repo to latest dev branch. or update your local repo.

5.) select build and build what you want. attention: the debug apk's are signed with a default debug key. 

6.) create a signing keystore. this step you only have to do one time. you can use one signing key for all apk's. you can also use your own jks file just copy it in keystore folder.

7.) sign your release apk's or debug apk's. if you sign booth you can switch between debug.apk and release.apk, because they have the same key. if you not sign debug.apk with the release key you have to uninstall the debug.apk before installing a release.apk.

8.) select install apk and connect your phone. you can select which apk to install.





### Disclaimer And Warning

* All information, thought, and code described here is intended for informational and educational purposes only. Nightscout currently makes no attempt at HIPAA privacy compliance. Use Nightscout and AndroidAPS at your own risk, and do not use the information or code to make medical decisions.

* Use of code from github.com is without warranty or formal support of any kind. Please review this repository's LICENSE for details.

* All product and company names, trademarks, servicemarks, registered trademarks, and registered servicemarks are the property of their respective holders. Their use is for information purposes and does not imply any affiliation with or endorsement by them.

Please note - this project has no association with and is not endorsed by:

- [SOOIL](http://www.sooil.com/eng/)
- [Dexcom](http://www.dexcom.com/)
