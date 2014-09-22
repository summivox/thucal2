# [THUCAL2][repo]

### 最常见问题：受网络学堂信息限制，每学期第一周星期一开始可一用！！！（实测星期天晚上应该就可以了～）

    最新版本: 0.4.0



##特点

* 完美解决各种不规则时间课程问题（指定时间的实验课，1大节3小节课……）
* 直接生成iCalendar文件，方便导入各种日历app（Google日历，Hotmail日历，苹果日历……）
* 所有导出工作在浏览器中完成
* 同时支持本科生和研究生

##FAQ

* Q: 提示`list错误：检查是否已登录http://info.tsinghua.edu.cn/`
  A: 照做。
  > 原因：info自身session管理混乱
* Q: 提示`分析错误`
  A: 有多种情况：
    1. THUCAL2只有在【学期开始之前半天】开始才可以使用（info在此之前还是上个学期的模式，信息不全）
    2. 插件冲突。请检查 TM/GM/本插件 均已更新至最新版，并关闭其他可能在info上运行的插件再试
* Q: 选课时间过了怎么办？
  A: 登录info，右侧【选课信息】=>【进入选课】，如图：
  ![][zhjw]


##效果

![][result]

##下载 安装

* Chrome：先安装[TamperMonkey][]环境
* Firefox: 先安装[GreaseMonkey][]环境
* Mac/Safari：先安装[NinjaKit][]环境 **(需要手动安装脚本，见NinjaKit说明)**
* ~~其他: 换Chrome吧少年！~~

[TamperMonkey]: https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo
[NinjaKit]: http://ss-o.net/safari/extension/NinjaKit.safariextz
[GreaseKit]: http://8-p.info/greasekit/
[GreaseMonkey]: https://addons.mozilla.org/en-US/firefox/addon/greasemonkey/

安装完成后，即可[下载安装本userscript](https://github.com/summivox/thucal2/raw/master/dist/thucal2.user.js)：  
https://github.com/summivox/thucal2/raw/master/dist/thucal2.user.js

##使用方法（以本科生为例，研究生类似）

**听说info界面更新了……下面的截图还是旧版的，操作没区别**

1. 登录info，打开选课系统，点`整体课表`  
   ![][step1-1]  

2. 点右上角多出的`THUCAL`按钮  
   ![][step2-1]  

3. 下方出现提示，若成功，浏览器会下载一个`thucal-xxxx-xxxx-x.ics`文件(FireFox可能会出现其他的名字，不要紧)，即为导出的日历  
   ![][step3-1]  

4. 将该文件导入支持iCalendar格式的日历app中。如：[Google Calendar导入日历][gcal1]。  
   ![][step4-1]  

##问题反馈

大家使用中如果遇到什么问题，欢迎在原日志下或[github][issue]与我讨论～

[summivox]: https://github.com/summivox
[repo]: https://github.com/summivox/thucal2
[issue]: https://github.com/summivox/thucal2/issues


[gcal1]: http://support.google.com/calendar/bin/answer.py?hl=zh-Hans&answer=83126

[zhjw]: http://i.imgur.com/NoebEdw.png
[step1-1]: http://i.imgur.com/OxO5RMg.png
[step2-1]: http://i.imgur.com/SXHWGwW.png
[step3-1]: http://i.imgur.com/IhH4vu0.png
[step4-1]: http://i.imgur.com/6oMMJqy.png
[result]:  http://i.imgur.com/96uOClz.png
