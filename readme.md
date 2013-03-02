# THUCAL2: userscript for exporting Tsinghua University curriculum

Latest stable release is hosted on userscript.org:  
http://userscripts.org/scripts/show/159785

Feel free to file a bug report here or at userscript.org!

##Screenshot

![][result]

##Main Features

* Fully automated operation: only one click is needed
    * Needs no "origin date" input
    * Automatically saves exported calendar (through HTML5 Blob)
* Accurate data
    * Irregular timing (`09:50-12:15`, labs, ...)
    * Lab details (lab content, location, ...)
* Standard iCalendar format for import into popular calendar apps
* All processing done locally for the sake of privacy

##Build

THUCAL2 is built using [GRUNT](http://gruntjs.com).

```
npm install --global grunt-cli
npm install
grunt release
```

Use `dist/thucal2.user.js`

##Usage

1. Log into http://info.tsinghua.edu.cn/  
   ![][step1-1]  

2. Click `THUCAL`  
   ![][step2-1]  

3. Successful: `.ics` file downloaded (file could be unnamed in FireFox due to browser restrictions)  
   ![][step3-1]  

4. Import file into calendar app  
   ![][step4-1]  

##License

This userscript is MIT licensed. See http://opensource.org/licenses/MIT for details.

[step1-1]: http://i.imgur.com/OxO5RMg.png
[step2-1]: http://i.imgur.com/SXHWGwW.png
[step3-1]: http://i.imgur.com/IhH4vu0.png
[step4-1]: http://i.imgur.com/6oMMJqy.png
[result]:  http://i.imgur.com/96uOClz.png
