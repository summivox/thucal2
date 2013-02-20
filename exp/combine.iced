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
        #else debugger
  Gr

$(document).ready(->
  L=parse_L($('#Lspan'), parseTermId('2012-2013-2'))
  {Gr, Gl}=parse_G($('#Gspan'))

  window.L=L
  window.Gr=Gr
  window.Gl=Gl
  window.origin=origin=getOrigin(Gr, L)
  combine(Gr, L, origin)
)
