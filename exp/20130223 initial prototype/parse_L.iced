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
