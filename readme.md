# THUCAL2: Smart curriculum exporter for Tsinghua University

**Download**: https://github.com/summivox/thucal2/raw/master/dist/thucal2.user.js

Surprisingly it still works <sup><b>TM</b></sup>, years after I (summivox) graduated, despite rumored complete overhaul to the whole website (which of course has become vaporware).

## Screenshot

![][result]

## Main Features

* Fully automated operation: only one click is needed
    * Needs no "origin date" input
    * Automatically saves exported calendar (through HTML5 Blob)
* Accurate results
    * Irregular timing (`09:50-12:15`, labs, ...)
    * Lab details (lab content, location, ...)
* Standard iCalendar format for import into popular calendar apps
* All processing done locally for the sake of privacy

## Build

THUCAL2 is built using [GRUNT](http://gruntjs.com).

```
npm install --global grunt-cli
npm install
grunt release
```

Use `dist/thucal2.user.js`

## Usage

1. Log into http://info.tsinghua.edu.cn/  
   ![][step1-1]  

2. Click `THUCAL`  
   ![][step2-1]  

3. Successful: `.ics` file downloaded (file could be unnamed in FireFox due to browser restrictions)  
   ![][step3-1]  

4. Import file into calendar app  
   ![][step4-1]  

## License

MIT

[step1-1]: http://i.imgur.com/iycvWRo.png
[step2-1]: http://i.imgur.com/1SNBYd7.png
[step3-1]: http://i.imgur.com/IhH4vu0.png
[step4-1]: http://i.imgur.com/6oMMJqy.png
[result]:  http://i.imgur.com/96uOClz.png
