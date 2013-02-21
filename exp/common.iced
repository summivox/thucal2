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

window.cmp=cmp=(a, b)->
  switch
    when a<b then -1
    when a>b then +1
    else 0

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
