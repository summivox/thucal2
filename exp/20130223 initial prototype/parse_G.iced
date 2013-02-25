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
