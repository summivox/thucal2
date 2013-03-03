############
## common
buildArray=(dims...)->
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

cmp=(a, b)->
  switch
    when a<b then -1
    when a>b then +1
    else 0

inferYear=(termIdP, m, d)->
  md=moment().month(m-1).date(d)
  th=moment().month(5-1).date(1)
  if termIdP.termN==1 && md.isAfter th
    y=termIdP.beginY
  else
    y=termIdP.endY
  moment([y, m-1, d])

getTOffset=(t)->t.clone().diff(t.clone().startOf('day'))

period=[
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

parseTermId=(termId)->
  if !(match=/(\d{4})-(\d{4})-(\d)/.exec termId)? then return null
  {
    beginY: parseInt match[1]
    endY  : parseInt match[2]
    termN : parseInt match[3]
  }

printTermId=(termIdP)->
  termIdP.beginY+'-'+termIdP.endY+'-'+(
    switch termIdP.termN
      when 1 then '秋'
      when 2 then '春'
      else '不科学'
  )

parseTimeStr=(infoStr)->
  if !(match=/时间(\d{1,2}:\d{1,2})-(\d{1,2}:\d{1,2})/.exec(infoStr))? then return null
  {
    beginT: getTOffset(moment(match[1], 'HHmm'))
    endT  : getTOffset(moment(match[2], 'HHmm'))
  }

parseWeekStr=(weekStr)->
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
parse_L=(root, termIdP)->
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
        cat   : fields[2]
        name  : fields[3]
        loc   : fields[4]
      }
    )
    {ymd, items}


############
## parse_G
parseRegLoc=(infoStr)->
  infoStr.match(///
    [\(；] # last delimiter
    ( #1
      [^\(\)；]+ # location (no delimeter)
    )
    \)$
  ///)?[1]

# lab information: name, location
# beware nasty cases:
#   name(loc(loc)；...)
#   (name)name( loc；...)
# use manual parsing
parseLabInfo=(infoStr)->
  #locate parens matching last
  i=infoStr.lastIndexOf(')')
  if i==-1 then return {labName: '', loc: ''}
  n=1
  while n && i>0
    switch infoStr[--i]
      when '(' then n--
      when ')' then n++
  if i==0 then return {labName: '', loc: ''}
  {
    labName: infoStr[0...i]
    loc: infoStr[i+1..].match(/([^；]*)；/)?[1]?.trim()
  }

parse_G=(root)->
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
        Gr[z][p].push {
          name    : @textContent.trim()
          infoStr
          loc
          labName : ''
          week    : parseWeekStr(infoStr)
          beginT  : null # default
          endT    : null
        }
      )

      # lab
      cell.find('a.blue_red_none').each(->
        infoStr=@nextElementSibling.textContent.trim()
        {labName, loc}=parseLabInfo(infoStr)
        if (t=parseTimeStr(infoStr))?
          {beginT, endT}=t
        else
          beginT=endT=null # default
        Gl[z][p].push {
          name    : @textContent.trim()
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
getOrigin=(Gr, Gl, L)->
  lastDay=L[L.length-1]
  lastItems=lastDay.items
  lastItem=lastItems[lastItems.length-1]
  z=lastDay.ymd.day()
  if z==0 then z=7 # moment.day() returns 0 for Sunday

  maxW=0
  for p in [6..1] by -1
    for it in Gr[z][p]
      if it.name==lastItem.name && (w=it.week[it.week.length-1])>maxW
        maxW=w
    for it in Gl[z][p]
      if it.name==lastItem.name && (w=it.week[it.week.length-1])>maxW
        maxW=w

  lastDay.ymd.clone().subtract(maxW-1, 'weeks').subtract(z-1, 'days')

# remap L to Lrel[day-since-origin]
getLrel=(L, origin)->
  Lrel=[]
  for x in L
    Lrel[x.ymd.diff(origin, 'days')]=x.items

# complete G using information from Lrel
# time priority: G-side > L-side > default(neither G nor L displays time)
combine=(G, Lrel, cat, origin)->
  for z in [1..7] by 1
    for p in [1..6] by 1
      for gi in G[z][p]
        w=gi.week
        w=w[w.length-1]
        rel=(w-1)*7+(z-1)
        if (bin=Lrel[rel]) then for li in bin
          if !li.matched && li.cat==cat && li.name==gi.name
            li.matched=true
            gi.beginT||=li.beginT # G > L
            gi.endT  ||=li.endT
            gi.loc=li.loc
            break
        gi.beginT||=period[p].beginT # L > default
        gi.endT  ||=period[p].endT
  G


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
<recur>SEQUENCE:0
UID:<uid>
TRANSP:OPAQUE
STATUS:CONFIRMED
END:VEVENT
"""
ICAL_XRULE="<x>RULE:FREQ=WEEKLY;COUNT=<n>\n"
ICAL_XDATE="<x>DATE;TZID=Asia/Shanghai:<list>\n"
ICAL_WEEK="""
BEGIN:VEVENT
SUMMARY:<name>
DTSTART;VALUE=DATE:<start>
DTEND;VALUE=DATE:<end>
SEQUENCE:0
UID:<uid>
TRANSP:TRANSPARENT
STATUS:CONFIRMED
END:VEVENT
"""
ical=new ->
  @uidSeq=0
  @getUid=->(@uidSeq++)+'.'+@uidBase
  @escape=(s)->
    s.replace(/,/g, '\\,')
  @template=(tmpl, obj)->
    ret=tmpl
    for k, v of obj
      ret=ret.replace(RegExp('<'+k+'>', 'g'), v)
    ret
  @dateStr=(m)->m.format('YYYYMMDD')
  @timeStr=(base, offset)->
    base.clone().add(offset).format('YYYYMMDD[T]HHmmss')
  @nameStr=(gi)->
    ret=gi.name
    if gi.labName
      ret+=' ['+gi.labName+']'
    ret
  @makeRecur=(oz, gi)->
    ws=gi.week
    w0=ws[0]
    wl=ws[ws.length-1]
    n=wl-w0+1
    if w0==wl then return ''
    ruleStr=@template ICAL_XRULE, {x: 'R', n}

    if ws.length==n then return ruleStr
    exclude=new Array(16+1)
    for i in [w0..wl] by 1
      exclude[i]=true
    for w in ws
      exclude[w]=false
    list=[]
    for i in [w0..wl] by 1
      if exclude[i]
        list.push @timeStr(oz.clone().add(i-1, 'weeks'), gi.beginT)
    dateStr=@template ICAL_XDATE, {x: 'EX', list: list.join(',')}

    return ruleStr+dateStr
  @makeG=(G, origin)->
    ret=[]
    for z in [1..7] by 1
      oz=origin.clone().add(z-1, 'days')
      bin=[]
      seq=0
      for p in [1..6] by 1
        for gi in G[z][p]
          ow=oz.clone().add(gi.week[0]-1, 'weeks')
          bin.push {
            seq   : seq++
            name  : @escape @nameStr gi
            loc   : @escape gi.loc
            desc  : @escape gi.infoStr
            start : @timeStr(ow, gi.beginT)
            end   : @timeStr(ow, gi.endT  )
            recur : @makeRecur(oz, gi)
            uid   : @getUid()
          }
      # remove duplicate entries within a day
      ret=ret.concat bin.sort((a, b)->
        cmp(a.name, b.name)||cmp(a.start, b.start)
      ).filter((x, i, a)->
        xp=a[i-1]
        i==0 || x.name!=xp.name || x.start!=xp.start || x.end!=xp.end
      ).sort((a, b)->
        a.seq-b.seq
      )
    ret.map((x)=>@template ICAL_EVENT, x).join('\n')
  @makeW=(origin, nameFactory)->
    (for w in [1..16] by 1
      start=origin.clone().add(w-1, 'weeks')
      end=start.clone().add(1, 'days')
      @template ICAL_WEEK, {
        name  : @escape nameFactory w
        start : @dateStr start
        end   : @dateStr end
        uid   : @getUid()
      }
    ).join('\n')

  @make=(Gr, Gl, origin)->
    @uidBase=moment().unix()+'@thucal'
    [
      ICAL_HEADER
      @makeG(Gr, origin)
      @makeG(Gl, origin)
      @makeW(origin, (w)->"第#{w}周")
      ICAL_FOOTER
    ].join('\n')
  this


############
## I/O

ERR_MSG_LIST='list错误：检查是否已登录http://info.tsinghua.edu.cn/'
stringify=(p)->
  (for k, v of p
    (encodeURIComponent(k) + '=' + encodeURIComponent(v))
  ).join('&')
get_L=(autocb)->
  await GM_xmlhttpRequest {
    url: thucal.params.listUrl + '?m=' + thucal.params.listVerb
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
    'm': thucal.params.listVerb
    'role': thucal.params.listRole
    'grrlID': ''
    'displayType': ''
    'token': match[1]
    'p_start_date': moment().format('YYYYMMDD')
    'p_end_date': moment().add(1, 'years').format('YYYYMMDD')
  await GM_xmlhttpRequest {
    url: thucal.params.listUrl
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
download=(cont, name)->
  b=new Blob([cont], {type: 'text/calendar'})
  saveAs(b, name)


############
## userscript logic
unsafeWindow.thucal=thucal=new ->
  @lib={$, moment, saveAs}
  @init=->

    ## ui

    @ui={}
    # button
    $('input[name="export2"]').before("""
      <input type="button" id="thucal_button" value="THUCAL: 导出为iCalendar">
    """)
    @ui.button=$('#thucal_button')
    @ui.button.on 'click', =>@make()
    # log
    $('#a1_1').parentsUntil('form').last().after("""
      <pre><code id="thucal_status" style="
        font-size: 10pt;
        line-height: 1.2em;
        font-family: Consolas, 'Courier New', monospace;
      "></code></pre>
    """)
    @ui.status=$('#thucal_status')
    @ui.log=(s)->@status.append(s+'\n')

    ## params

    if document.location.toString().match(/Yjs/)
      @params=
        listUrl: 'http://zhjw.cic.tsinghua.edu.cn/jxmh.do'
        listVerb: 'yjs_jxrl_all'
        listRole: 'yjs'
    else
      @params=
        listUrl: 'http://zhjw.cic.tsinghua.edu.cn/jxmh.do'
        listVerb: 'bks_jxrl_all'
        listRole: 'bks'

  @make=->
    @ui.log "******THUCAL2******"
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
      origin=getOrigin(Gr, Gl, L)
      Lrel=getLrel(L, origin)
      combine(Gr, Lrel, '上课', origin)
      combine(Gl, Lrel, '实验', origin)
      @ui.log '分析完成'
    catch e
      @ui.log '分析错误：'+e.toString()
      return console.error e

    try
      ret=ical.make(Gr, Gl, origin)
      #console.log ret
      download(ret, "thucal-#{term}.ics")
      @ui.log '导出成功！'
    catch e
      @ui.log '导出错误：'+e.toString()
      return console.error e
  this

$(document).ready(->thucal.init())
