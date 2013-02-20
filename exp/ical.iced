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
