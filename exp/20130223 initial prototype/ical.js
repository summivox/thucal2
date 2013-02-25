// Generated by IcedCoffeeScript 1.4.0b
(function() {
  var ICAL_EVENT, ICAL_EX, ICAL_FOOTER, ICAL_HEADER, ical;

  ICAL_HEADER = "BEGIN:VCALENDAR\nPRODID:-//smilekzs//thucal//EN\nVERSION:2.0\nCALSCALE:GREGORIAN\nMETHOD:PUBLISH\nX-WR-CALNAME:THU:2012-2013-2\nX-WR-TIMEZONE:Asia/Shanghai\nBEGIN:VTIMEZONE\nTZID:Asia/Shanghai\nX-LIC-LOCATION:Asia/Shanghai\nBEGIN:STANDARD\nTZOFFSETFROM:+0800\nTZOFFSETTO:+0800\nTZNAME:CST\nDTSTART:19700101T000000\nEND:STANDARD\nEND:VTIMEZONE\n";

  ICAL_FOOTER = "END:VCALENDAR\n";

  ICAL_EVENT = "BEGIN:VEVENT\nSUMMARY:<name>\nLOCATION:<loc>\nDESCRIPTION:<desc>\nDTSTART;TZID=Asia/Shanghai:<start>\nDTEND;TZID=Asia/Shanghai:<end>\nRRULE:FREQ=WEEKLY;COUNT=16\n<ex>\nSEQUENCE:0\nSTATUS:CONFIRMED\nEND:VEVENT\n";

  ICAL_EX = "EXDATE;TZID=Asia/Shanghai:<date>\n";

  window.ical = ical = new function() {
    this.escape = function(s) {
      return s.replace(/,/g, '\\,');
    };
    this.template = function(tmpl, obj) {
      var k, ret, v;
      ret = tmpl;
      for (k in obj) {
        v = obj[k];
        ret = ret.replace(RegExp('<' + k + '>'), v);
      }
      return ret;
    };
    this.dateStr = function(base, offset) {
      return base.clone().add(offset).format('YYYYMMDD[T]HHmmss');
    };
    this.nameStr = function(gi) {
      var ret;
      ret = gi.name;
      if (gi.labName) ret += ' [' + gi.labName + ']';
      return ret;
    };
    this.makeEx = function(d1, gi) {
      var exclude, i, ret, w, _i, _j, _k, _len, _ref;
      exclude = new Array(16 + 1);
      for (i = _i = 1; _i <= 16; i = _i += 1) {
        exclude[i] = true;
      }
      _ref = gi.week;
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        w = _ref[_j];
        exclude[w] = false;
      }
      ret = [];
      for (i = _k = 1; _k <= 16; i = _k += 1) {
        if (exclude[i]) {
          ret.push(this.template(ICAL_EX, {
            date: this.dateStr(d1.clone().add(i - 1, 'weeks'), gi.beginT)
          }));
        }
      }
      return ret.join('');
    };
    this.makeG = function(G, origin) {
      var d1, gi, p, ret, z, _i, _j, _k, _len, _ref;
      ret = [];
      for (z = _i = 1; _i <= 7; z = _i += 1) {
        d1 = origin.clone().add(z - 1, 'days');
        for (p = _j = 1; _j <= 6; p = _j += 1) {
          _ref = G[z][p];
          for (_k = 0, _len = _ref.length; _k < _len; _k++) {
            gi = _ref[_k];
            ret.push(this.template(ICAL_EVENT, {
              name: this.escape(this.nameStr(gi)),
              loc: this.escape(gi.loc),
              desc: this.escape(gi.infoStr),
              start: this.dateStr(d1, gi.beginT),
              end: this.dateStr(d1, gi.endT),
              ex: this.makeEx(d1, gi)
            }));
          }
        }
      }
      return ret.join('');
    };
    this.make = function(Gr, Gl, origin) {
      return ICAL_HEADER + this.makeG(Gr, origin) + this.makeG(Gl, origin) + ICAL_FOOTER;
    };
    return this;
  };

}).call(this);