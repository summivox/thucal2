parse=(weekStr)->
  r=/(([\d,-]+)|全|前八|后八|单|双)周/.exec(weekStr)
  return null if !r?

  switch r[1].charAt(0)
    when '全' then return [1..16]
    when '前' then return [1..8]
    when '后' then return [9..16]
    when '单' then return (w for w in [1..16] by 2)
    when '双' then return (w for w in [2..16] by 2)
    else
      ret=[]
      for s in r[2].split(',')
        #isolated?
        match=/^\d+$/.exec(s)
        if match?
          ret.push(Number(match[0]))
        #range?
        match=/^(\d+)-(\d+)$/.exec(s)
        if match?
          ret.push(w) for w in [Number(match[1])..Number(match[2])]
      ret

getMask=(week)->
  return null if !week?
  ret=0
  ret|=1<<w for w in week
  ret>>1 #[1..16] -> [0..15]

module.exports={
  parse: parse
  getMask: getMask
}
