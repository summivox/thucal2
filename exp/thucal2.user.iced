`
// vim: nowrap
// Copyright (c) 2013, smilekzs. (MIT Licensed)
// ==UserScript==
// @name          thucal2
// @namespace     http://github.com/smilekzs
// @version       0.2.0
// @description   Export Tsinghua University undergraduate curriculum to iCalendar
// @include       *.cic.tsinghua.edu.cn/syxk.vsyxkKcapb.do*
// ==/UserScript==

//#include
`


############
## common
window.buildArray=buildArray=(dims...)->
  if !(dims?.length) then return null
  d=dims?.shift()
  if d.length?
    a=[]
    for i in d
      a[i]=buildArray(dims...)
  else
    a=new Array(d)
    for i in [0...d] by 1
      a[i]=buildArray(dims...)
  a

window.inferYear=inferYear=(termIdP, m, d)->
  md=moment().month(m-1).date(d)
  th=moment().month(5-1).date(1)
  if termIdP.termN==1 && md.isAfter th
    y=termIdP.beginY
  else
    y=termIdP.endY
  moment([y, m-1, d])

window.getTOffset=getTOffset=(t)->t.clone().diff(t.clone().startOf('day'))

window.period=period=[
  "00:00" # placeholder
  "08:00" #1
  "09:50" #2
  "13:30" #3
  "15:20" #4
  "17:05" #5
  "19:20" #6
].map((s)->
  t=moment(s, 'HHmm')
  {
    beginT: getTOffset(t)
    endT  : getTOffset(t.add(1, 'hours').add(35, 'minutes'))
  }
)

window.parseTermId=parseTermId=(termId)->
  if !(match=/(\d{4})-(\d{4})-(\d)/.exec termId)? then return null
  {
    beginY: parseInt match[1]
    endY  : parseInt match[2]
    termN : parseInt match[3]
  }

window.printTermId=(termIdP)->
  termIdP.beginY+'-'+termIdP.endY+'-'+(
    switch termIdP.termN
      when 1 then '秋'
      when 2 then '春'
      else '不科学'
  )

window.parseTimeStr=parseTimeStr=(infoStr)->
  if !(match=/时间(\d{1,2}:\d{1,2})-(\d{1,2}:\d{1,2})/.exec(infoStr))? then return null
  {
    beginT: getTOffset(moment(match[1], 'HHmm'))
    endT  : getTOffset(moment(match[2], 'HHmm'))
  }

window.parseWeekStr=parseWeekStr=(weekStr)->
  if !(part=/(([\d,-]+)|全|前八|后八|单|双)周/.exec(weekStr)) then return null
  switch part[1].charAt(0)
    when '全' then return [1..16]
    when '前' then return [1..8]
    when '后' then return [9..16]
    when '单' then return (w for w in [1..16] by 2)
    when '双' then return (w for w in [2..16] by 2)
    else
      ret=[]
      for s in part[2].split(',')
        #isolated?
        if (match=/^\d+$/.exec(s))?
          ret.push(Number(match[0]))
        #range?
        if (match=/^(\d+)-(\d+)$/.exec(s))?
          ret.push(w) for w in [Number(match[1])..Number(match[2])] by 1
      ret


############
## parse_L
window.parse_L=parse_L=(root, termIdP)->
  days=root.find('td.doc_title').map(->
    if !(match=/(\d+)月(\d+)日/.exec @innerHTML)? then throw Error @innerHTML
    md=inferYear(termIdP, parseInt(match[1]), parseInt(match[2]))
  )
  tables=root.find('> table.data_list_table')
  for ymd, i in days
    items=$(tables[i]).find('tr:not(.data_list_title)').map(->
      fields=$(this).find('td').map(->@innerHTML)
      {
        beginT: getTOffset(moment(fields[0], 'HHmm'))
        endT  : getTOffset(moment(fields[1], 'HHmm'))
        name  : fields[3]
        loc   : fields[4]
      }
    )
    {ymd, items}


############
## parse_G
window.parseRegLoc=(infoStr)->
  infoStr.match(///
    [\(；] # last delimiter
    ( #1
      [^\(；]+ # location (no delimeter)
    )
    \)$
  ///)?[1]

window.parseLabInfo=(infoStr)->
  if (match=infoStr.match(///
    ( #1
      .* # everything before the last parens pair => labName
    )
    \(
    ( #2
      [^\)；]+ # first field in parens => loc
    )
    .* # ignore the rest
    \)$
  ///))?
    labName: match[1].trim()
    loc: match[2].trim()
  else
    labName: ''
    loc: ''

window.parse_G=parse_G=(root)->
  Gr=buildArray([1..7], [1..6])
  Gl=buildArray([1..7], [1..6])
  for z in [1..7] by 1
    for p in [1..6] by 1
      Gr[z][p]=[]
      Gl[z][p]=[]
      cell=$("#a#{p}_#{z}")

      # regular
      cell.find('a.mainHref').each(->
        infoStr=@nextSibling.data.trim()
        loc=parseRegLoc(infoStr)
        {beginT, endT}=period[p]
        Gr[z][p].push {
          name    : @innerText.trim()
          infoStr
          loc
          labName : ''
          week    : parseWeekStr(infoStr)
          beginT
          endT
        }
      )

      # lab
      cell.find('a.blue_red_none').each(->
        infoStr=@nextElementSibling.innerText.trim()
        {labName, loc}=parseLabInfo(infoStr)
        if (t=parseTimeStr(infoStr))?
          {beginT, endT}=t
        else
          {beginT, endT}=period[p]
        Gl[z][p].push {
          name    : @innerText.trim()
          infoStr
          loc
          labName
          week    : parseWeekStr(infoStr)
          beginT
          endT
        }
      )
  {Gr, Gl}


############
## combine
window.getOrigin=getOrigin=(Gr, L)->
  lastDay=L[L.length-1]
  lastItems=lastDay.items
  lastItem=lastItems[lastItems.length-1]
  z=lastDay.ymd.day()

  maxW=0
  for p in [6..1] by -1
    for it in Gr[z][p]
      if it.name==lastItem.name && (w=it.week[it.week.length-1])>maxW
        maxW=w

  lastDay.ymd.clone().subtract(maxW-1, 'weeks').subtract(z-1, 'days')

window.combine=combine=(Gr, L, origin)->
  # re-map L to Lrel[day-since-origin]
  Lrel=[]
  for x in L
    Lrel[x.ymd.diff(origin, 'days')]=x.items

  # override G-side attributes with L-side equivalent (if available)
  for z in [1..7] by 1
    for p in [1..6] by 1
      for gi in Gr[z][p]
        w=gi.week
        w=w[w.length-1]
        rel=(w-1)*7+(z-1)
        if (bin=Lrel[rel]) then for li in bin
          if !li.matched && li.name==gi.name
            li.matched=true
            gi.beginT=li.beginT
            gi.endT=li.endT
            gi.loc=li.loc
            break
  Gr


############
## ical
ICAL_HEADER="""
BEGIN:VCALENDAR
PRODID:-//smilekzs//thucal//EN
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:THU:2012-2013-2
X-WR-TIMEZONE:Asia/Shanghai
BEGIN:VTIMEZONE
TZID:Asia/Shanghai
X-LIC-LOCATION:Asia/Shanghai
BEGIN:STANDARD
TZOFFSETFROM:+0800
TZOFFSETTO:+0800
TZNAME:CST
DTSTART:19700101T000000
END:STANDARD
END:VTIMEZONE

"""
ICAL_FOOTER="""
END:VCALENDAR

"""
ICAL_EVENT="""
BEGIN:VEVENT
SUMMARY:<name>
LOCATION:<loc>
DESCRIPTION:<desc>
DTSTART;TZID=Asia/Shanghai:<start>
DTEND;TZID=Asia/Shanghai:<end>
RRULE:FREQ=WEEKLY;COUNT=16
<ex>
SEQUENCE:0
STATUS:CONFIRMED
END:VEVENT

"""
ICAL_EX="""
EXDATE;TZID=Asia/Shanghai:<date>

"""
window.ical=ical=new ->
  @escape=(s)->
    s.replace(/,/g, '\\,')
  @template=(tmpl, obj)->
    ret=tmpl
    for k, v of obj
      ret=ret.replace(RegExp('<'+k+'>'), v)
    ret
  @dateStr=(base, offset)->
    base.clone().add(offset).format('YYYYMMDD[T]HHmmss')
  @nameStr=(gi)->
    ret=gi.name
    if gi.labName
      ret+=' ['+gi.labName+']'
    ret
  @makeEx=(d1, gi)->
    exclude=new Array(16+1)
    for i in [1..16] by 1
      exclude[i]=true
    for w in gi.week
      exclude[w]=false
    ret=[]
    for i in [1..16] by 1
      if exclude[i]
        ret.push @template ICAL_EX,
          date: @dateStr(d1.clone().add(i-1, 'weeks'), gi.beginT)
    ret.join('')
  @makeG=(G, origin)->
    ret=[]
    for z in [1..7] by 1
      d1=origin.clone().add(z-1, 'days')
      for p in [1..6] by 1
        for gi in G[z][p]
          ret.push @template ICAL_EVENT,
            name  : @escape @nameStr gi
            loc   : @escape gi.loc
            desc  : @escape gi.infoStr
            start : @dateStr(d1, gi.beginT)
            end   : @dateStr(d1, gi.endT  )
            ex    : @makeEx(d1, gi)
    ret.join('')
  @make=(Gr, Gl, origin)->
    return ICAL_HEADER+@makeG(Gr, origin)+@makeG(Gl, origin)+ICAL_FOOTER
  this


############
## I/O
window.L_URL=L_URL='http://zhjw.cic.tsinghua.edu.cn/jxmh.do'
ERR_MSG_LIST='list错误：检查是否已登录http://info.tsinghua.edu.cn/'
window.stringify=stringify=(p)->
  (for k, v of p
    (encodeURIComponent(k) + '=' + encodeURIComponent(v))
  ).join('&')
window.get_L=get_L=(autocb)->
  await GM_xmlhttpRequest {
    url: L_URL + '?m=bks_jxrl_all'
    method: 'GET'
    onload: defer(resp)
    onerror: (err)->
      thucal.ui.log ERR_MSG_LIST
      throw Error('get_L: no token: ' + err.toString())
  }
  if !(match=/name="token" value="([\da-f]+)"/.exec(resp.responseText))?
    thucal.ui.log ERR_MSG_LIST
    throw Error 'get_L: no token: response does not contain token'
  params=
    'm': 'bks_jxrl_all'
    'role': 'bks'
    'grrlID': ''
    'displayType': ''
    'token': match[1]
    'p_start_date': moment().format('YYYYMMDD')
    'p_end_date': moment().add(1, 'years').format('YYYYMMDD')
  await GM_xmlhttpRequest {
    url: L_URL
    method: 'POST'
    headers:
      "Content-Type": "application/x-www-form-urlencoded"
    data: stringify(params)
    onload: defer(resp)
    onerror: (err)->
      thucal.ui.log ERR_MSG_LIST
      throw Error('get_L: post error: ' + err.toString())
  }
  $(resp.responseText).filter('a')
window.download=download=(cont, name)->
  b=new Blob([cont], {type: 'text/calendar'})
  saveAs(b, name)


############
## userscript logic
window.thucal=thucal=new ->
  @init=->
    @ui={}
    # button
    $('input[name="export2"]').before("""
      <input type="button" id="thucal_button" value="THUCAL: 导出为iCalendar">
    """)
    @ui.button=$('#thucal_button')
    @ui.button.on 'click', =>@make()
    $('#a1_1').parentsUntil('form').last().after("""
      <pre><code id="thucal_status" style="
        font-size: 10pt;
        line-height: 1.2em;
        font-family: Consolas, 'Courier New', monospace;
      "></code></pre>
    """)
    @ui.status=$('#thucal_status')
    @ui.log=(s)->@status.append(s+'\n')

  @make=->
    @ui.log "******THUCAL********"
    termIdP=parseTermId($('input[name=p_xnxq]').val())
    term=printTermId(termIdP)
    @ui.log '学期：'+term
    if termIdP.termN!=1 && termIdP.termN!=2
      @ui.log '不支持小学期！'
      return

    await get_L defer(Lraw)
    @ui.log 'list完成'

    try
      L=parse_L(Lraw, termIdP)
      {Gr, Gl}=parse_G($(document))
      origin=getOrigin(Gr, L)
      combine(Gr, L, origin)
      @ui.log '分析完成'
    catch e
      @ui.log '分析错误：'+e.toString()
      return console.error e

    ret=ical.make(Gr, Gl, origin)
    #console.log ret
    download(ret, "thucal-#{term}.ics")
    @ui.log '导出成功！'
  this

$(document).ready(->thucal.init())
