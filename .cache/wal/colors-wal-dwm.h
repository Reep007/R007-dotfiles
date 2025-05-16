static const char norm_fg[] = "#cfdfee";
static const char norm_bg[] = "#040408";
static const char norm_border[] = "#909ca6";

static const char sel_fg[] = "#cfdfee";
static const char sel_bg[] = "#1D639B";
static const char sel_border[] = "#cfdfee";

static const char urg_fg[] = "#cfdfee";
static const char urg_bg[] = "#4B4A42";
static const char urg_border[] = "#4B4A42";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
