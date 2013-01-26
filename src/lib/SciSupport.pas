unit scisupport;

// Support unit for scintilla use in pascal. The constants are all created from scintilla.iface by
// a python script.

interface

{$DEFINE MACRO_SUPPORT}

uses Windows;

type
  TScintillaMessageFnc = function(ptr : Pointer; Msg, wParam, lParam : LongInt) : LongInt; cdecl;
  uptr_t = Longword;
  sptr_t = Longint;
  TNotifyHeader = record
	  hwndFrom : Pointer;
	  idFrom : Cardinal;
	  code : Cardinal;
  end;
  PSCNotification = ^TSCNotification;
  TSCNotification = record
    nmhdr 		          : TNotifyHeader;
    position    	      : Integer;		// SCN_STYLENEEDED, SCN_MODIFIED
    ch 			            : Integer;		// SCN_CHARADDED, SCN_KEY
    modifiers		        : Integer;		// SCN_KEY
    modificationType	  : Integer;		// SCN_MODIFIED
    text		            : PChar;			// SCN_MODIFIED
    length		          : Integer;		// SCN_MODIFIED
    linesAdded		      : Integer;		// SCN_MODIFIED
{$ifdef MACRO_SUPPORT}
    message		          : Integer;		// SCN_MACRORECORD
    wParam		          : uptr_t;		// SCN_MACRORECORD
    lParam		          : sptr_t;			// SCN_MACRORECORD
{$endif}
    line		            : Integer;		// SCN_MODIFIED
    foldLevelNow	      : Integer;		// SCN_MODIFIED
    foldLevelPrev	      : Integer;		// SCN_MODIFIED
    margin		          : Integer;		// SCN_MARGINCLICK
    listType		        : Integer;		// SCN_USERLISTSELECTION
    x                   : Integer;          // SCN_DWELLSTART, SCN_DWELLEND
    y                   : Integer;          // SCN_DWELLSTART, SCN_DWELLEND
    token               : Integer;    // SCN_MODIFIED with SC_MOD_CONTAINER
    annotationLinesAdded: Integer; // SCN_MODIFIED with SC_MOD_CHANGEANNOTATION
    updated             : Integer;    // SCN_UPDATEUI
  end;
  TCharacterRange = Record
    cpMin : Longint;
	  cpMax : Longint;
  end;
  PTextRange = ^TTextRange;
  TTextRange = Record
    chrg : TCharacterRange;
    lpstrText : LPSTR;
  end;
  PTextToFind = ^TTextToFind;
  TTextToFind  = Record
    chrg : TCharacterRange;
	  lpstrText : LPSTR;
	  chrgText : TCharacterRange;
  end;

const
//++Const -- start of section automatically generated from Scintilla.iface
    INVALID_POSITION = -1;
    SCI_START = 2000;
    SCI_OPTIONAL_START = 3000;
    SCI_LEXER_START = 4000;
    SCI_ADDTEXT = 2001;
    SCI_ADDSTYLEDTEXT = 2002;
    SCI_INSERTTEXT = 2003;
    SCI_CLEARALL = 2004;
    SCI_CLEARDOCUMENTSTYLE = 2005;
    SCI_GETLENGTH = 2006;
    SCI_GETCHARAT = 2007;
    SCI_GETCURRENTPOS = 2008;
    SCI_GETANCHOR = 2009;
    SCI_GETSTYLEAT = 2010;
    SCI_REDO = 2011;
    SCI_SETUNDOCOLLECTION = 2012;
    SCI_SELECTALL = 2013;
    SCI_SETSAVEPOINT = 2014;
    SCI_GETSTYLEDTEXT = 2015;
    SCI_CANREDO = 2016;
    SCI_MARKERLINEFROMHANDLE = 2017;
    SCI_MARKERDELETEHANDLE = 2018;
    SCI_GETUNDOCOLLECTION = 2019;
    SCWS_INVISIBLE = 0;
    SCWS_VISIBLEALWAYS = 1;
    SCWS_VISIBLEAFTERINDENT = 2;
    SCI_GETVIEWWS = 2020;
    SCI_SETVIEWWS = 2021;
    SCI_POSITIONFROMPOINT = 2022;
    SCI_POSITIONFROMPOINTCLOSE = 2023;
    SCI_GOTOLINE = 2024;
    SCI_GOTOPOS = 2025;
    SCI_SETANCHOR = 2026;
    SCI_GETCURLINE = 2027;
    SCI_GETENDSTYLED = 2028;
    SC_EOL_CRLF = 0;
    SC_EOL_CR = 1;
    SC_EOL_LF = 2;
    SCI_CONVERTEOLS = 2029;
    SCI_GETEOLMODE = 2030;
    SCI_SETEOLMODE = 2031;
    SCI_STARTSTYLING = 2032;
    SCI_SETSTYLING = 2033;
    SCI_GETBUFFEREDDRAW = 2034;
    SCI_SETBUFFEREDDRAW = 2035;
    SCI_SETTABWIDTH = 2036;
    SCI_GETTABWIDTH = 2121;
    SC_CP_UTF8 = 65001;
    SC_CP_DBCS = 1;
    SCI_SETCODEPAGE = 2037;
    SCI_SETUSEPALETTE = 2039;
    MARKER_MAX = 31;
    SC_MARK_CIRCLE = 0;
    SC_MARK_ROUNDRECT = 1;
    SC_MARK_ARROW = 2;
    SC_MARK_SMALLRECT = 3;
    SC_MARK_SHORTARROW = 4;
    SC_MARK_EMPTY = 5;
    SC_MARK_ARROWDOWN = 6;
    SC_MARK_MINUS = 7;
    SC_MARK_PLUS = 8;
    SC_MARK_VLINE = 9;
    SC_MARK_LCORNER = 10;
    SC_MARK_TCORNER = 11;
    SC_MARK_BOXPLUS = 12;
    SC_MARK_BOXPLUSCONNECTED = 13;
    SC_MARK_BOXMINUS = 14;
    SC_MARK_BOXMINUSCONNECTED = 15;
    SC_MARK_LCORNERCURVE = 16;
    SC_MARK_TCORNERCURVE = 17;
    SC_MARK_CIRCLEPLUS = 18;
    SC_MARK_CIRCLEPLUSCONNECTED = 19;
    SC_MARK_CIRCLEMINUS = 20;
    SC_MARK_CIRCLEMINUSCONNECTED = 21;
    SC_MARK_BACKGROUND = 22;
    SC_MARK_DOTDOTDOT = 23;
    SC_MARK_ARROWS = 24;
    SC_MARK_PIXMAP = 25;
    SC_MARK_CHARACTER = 10000;
    SC_MARKNUM_FOLDEREND = 25;
    SC_MARKNUM_FOLDEROPENMID = 26;
    SC_MARKNUM_FOLDERMIDTAIL = 27;
    SC_MARKNUM_FOLDERTAIL = 28;
    SC_MARKNUM_FOLDERSUB = 29;
    SC_MARKNUM_FOLDER = 30;
    SC_MARKNUM_FOLDEROPEN = 31;
    SC_MASK_FOLDERS = $FE000000;
    SCI_MARKERDEFINE = 2040;
    SCI_MARKERSETFORE = 2041;
    SCI_MARKERSETBACK = 2042;
    SCI_MARKERADD = 2043;
    SCI_MARKERDELETE = 2044;
    SCI_MARKERDELETEALL = 2045;
    SCI_MARKERGET = 2046;
    SCI_MARKERNEXT = 2047;
    SCI_MARKERPREVIOUS = 2048;
    SCI_MARKERDEFINEPIXMAP = 2049;
    SC_MARGIN_SYMBOL = 0;
    SC_MARGIN_NUMBER = 1;
    SCI_SETMARGINTYPEN = 2240;
    SCI_GETMARGINTYPEN = 2241;
    SCI_SETMARGINWIDTHN = 2242;
    SCI_GETMARGINWIDTHN = 2243;
    SCI_SETMARGINMASKN = 2244;
    SCI_GETMARGINMASKN = 2245;
    SCI_SETMARGINSENSITIVEN = 2246;
    SCI_GETMARGINSENSITIVEN = 2247;
    STYLE_DEFAULT = 32;
    STYLE_LINENUMBER = 33;
    STYLE_BRACELIGHT = 34;
    STYLE_BRACEBAD = 35;
    STYLE_CONTROLCHAR = 36;
    STYLE_INDENTGUIDE = 37;
    STYLE_LASTPREDEFINED = 39;
    STYLE_MAX = 127;
    SC_CHARSET_ANSI = 0;
    SC_CHARSET_DEFAULT = 1;
    SC_CHARSET_BALTIC = 186;
    SC_CHARSET_CHINESEBIG5 = 136;
    SC_CHARSET_EASTEUROPE = 238;
    SC_CHARSET_GB2312 = 134;
    SC_CHARSET_GREEK = 161;
    SC_CHARSET_HANGUL = 129;
    SC_CHARSET_MAC = 77;
    SC_CHARSET_OEM = 255;
    SC_CHARSET_RUSSIAN = 204;
    SC_CHARSET_SHIFTJIS = 128;
    SC_CHARSET_SYMBOL = 2;
    SC_CHARSET_TURKISH = 162;
    SC_CHARSET_JOHAB = 130;
    SC_CHARSET_HEBREW = 177;
    SC_CHARSET_ARABIC = 178;
    SC_CHARSET_VIETNAMESE = 163;
    SC_CHARSET_THAI = 222;
    SCI_STYLECLEARALL = 2050;
    SCI_STYLESETFORE = 2051;
    SCI_STYLESETBACK = 2052;
    SCI_STYLESETBOLD = 2053;
    SCI_STYLESETITALIC = 2054;
    SCI_STYLESETSIZE = 2055;
    SCI_STYLESETFONT = 2056;
    SCI_STYLESETEOLFILLED = 2057;
    SCI_STYLERESETDEFAULT = 2058;
    SCI_STYLESETUNDERLINE = 2059;
    SC_CASE_MIXED = 0;
    SC_CASE_UPPER = 1;
    SC_CASE_LOWER = 2;
    SCI_STYLESETCASE = 2060;
    SCI_STYLESETCHARACTERSET = 2066;
    SCI_STYLESETHOTSPOT = 2409;
    SCI_SETSELFORE = 2067;
    SCI_SETSELBACK = 2068;
    SCI_SETCARETFORE = 2069;
    SCI_ASSIGNCMDKEY = 2070;
    SCI_CLEARCMDKEY = 2071;
    SCI_CLEARALLCMDKEYS = 2072;
    SCI_SETSTYLINGEX = 2073;
    SCI_STYLESETVISIBLE = 2074;
    SCI_GETCARETPERIOD = 2075;
    SCI_SETCARETPERIOD = 2076;
    SCI_SETWORDCHARS = 2077;
    SCI_BEGINUNDOACTION = 2078;
    SCI_ENDUNDOACTION = 2079;
    SCI_SETCHARSDEFAULT = 2444;
    INDIC_MAX = 7;
    INDIC_PLAIN = 0;
    INDIC_SQUIGGLE = 1;
    INDIC_TT = 2;
    INDIC_DIAGONAL = 3;
    INDIC_STRIKE = 4;
    INDIC_HIDDEN = 5;
    INDIC_BOX = 6;
    INDIC0_MASK = $20;
    INDIC1_MASK = $40;
    INDIC2_MASK = $80;
    INDICS_MASK = $E0;
    SCI_INDICSETSTYLE = 2080;
    SCI_INDICGETSTYLE = 2081;
    SCI_INDICSETFORE = 2082;
    SCI_INDICGETFORE = 2083;
    SCI_SETWHITESPACEFORE = 2084;
    SCI_SETWHITESPACEBACK = 2085;
    SCI_SETSTYLEBITS = 2090;
    SCI_GETSTYLEBITS = 2091;
    SCI_SETLINESTATE = 2092;
    SCI_GETLINESTATE = 2093;
    SCI_GETMAXLINESTATE = 2094;
    SCI_GETCARETLINEVISIBLE = 2095;
    SCI_SETCARETLINEVISIBLE = 2096;
    SCI_GETCARETLINEBACK = 2097;
    SCI_SETCARETLINEBACK = 2098;
    SCI_STYLESETCHANGEABLE = 2099;
    SCI_AUTOCSHOW = 2100;
    SCI_AUTOCCANCEL = 2101;
    SCI_AUTOCACTIVE = 2102;
    SCI_AUTOCPOSSTART = 2103;
    SCI_AUTOCCOMPLETE = 2104;
    SCI_AUTOCSTOPS = 2105;
    SCI_AUTOCSETSEPARATOR = 2106;
    SCI_AUTOCGETSEPARATOR = 2107;
    SCI_AUTOCSELECT = 2108;
    SCI_AUTOCSETCANCELATSTART = 2110;
    SCI_AUTOCGETCANCELATSTART = 2111;
    SCI_AUTOCSETFILLUPS = 2112;
    SCI_AUTOCSETCHOOSESINGLE = 2113;
    SCI_AUTOCGETCHOOSESINGLE = 2114;
    SCI_AUTOCSETIGNORECASE = 2115;
    SCI_AUTOCGETIGNORECASE = 2116;
    SCI_USERLISTSHOW = 2117;
    SCI_AUTOCSETAUTOHIDE = 2118;
    SCI_AUTOCGETAUTOHIDE = 2119;
    SCI_AUTOCSETDROPRESTOFWORD = 2270;
    SCI_AUTOCGETDROPRESTOFWORD = 2271;
    SCI_REGISTERIMAGE = 2405;
    SCI_CLEARREGISTEREDIMAGES = 2408;
    SCI_AUTOCGETTYPESEPARATOR = 2285;
    SCI_AUTOCSETTYPESEPARATOR = 2286;
    SCI_SETINDENT = 2122;
    SCI_GETINDENT = 2123;
    SCI_SETUSETABS = 2124;
    SCI_GETUSETABS = 2125;
    SCI_SETLINEINDENTATION = 2126;
    SCI_GETLINEINDENTATION = 2127;
    SCI_GETLINEINDENTPOSITION = 2128;
    SCI_GETCOLUMN = 2129;
    SCI_SETHSCROLLBAR = 2130;
    SCI_GETHSCROLLBAR = 2131;
    SCI_SETINDENTATIONGUIDES = 2132;
    SCI_GETINDENTATIONGUIDES = 2133;
    SCI_SETHIGHLIGHTGUIDE = 2134;
    SCI_GETHIGHLIGHTGUIDE = 2135;
    SCI_GETLINEENDPOSITION = 2136;
    SCI_GETCODEPAGE = 2137;
    SCI_GETCARETFORE = 2138;
    SCI_GETUSEPALETTE = 2139;
    SCI_GETREADONLY = 2140;
    SCI_SETCURRENTPOS = 2141;
    SCI_SETSELECTIONSTART = 2142;
    SCI_GETSELECTIONSTART = 2143;
    SCI_SETSELECTIONEND = 2144;
    SCI_GETSELECTIONEND = 2145;
    SCI_SETPRINTMAGNIFICATION = 2146;
    SCI_GETPRINTMAGNIFICATION = 2147;
    SC_PRINT_NORMAL = 0;
    SC_PRINT_INVERTLIGHT = 1;
    SC_PRINT_BLACKONWHITE = 2;
    SC_PRINT_COLOURONWHITE = 3;
    SC_PRINT_COLOURONWHITEDEFAULTBG = 4;
    SCI_SETPRINTCOLOURMODE = 2148;
    SCI_GETPRINTCOLOURMODE = 2149;
    SCFIND_WHOLEWORD = 2;
    SCFIND_MATCHCASE = 4;
    SCFIND_WORDSTART = $00100000;
    SCFIND_REGEXP = $00200000;
    SCFIND_POSIX = $00400000;
    SCI_FINDTEXT = 2150;
    SCI_FORMATRANGE = 2151;
    SCI_GETFIRSTVISIBLELINE = 2152;
    SCI_GETLINE = 2153;
    SCI_GETLINECOUNT = 2154;
    SCI_SETMARGINLEFT = 2155;
    SCI_GETMARGINLEFT = 2156;
    SCI_SETMARGINRIGHT = 2157;
    SCI_GETMARGINRIGHT = 2158;
    SCI_GETMODIFY = 2159;
    SCI_SETSEL = 2160;
    SCI_GETSELTEXT = 2161;
    SCI_GETTEXTRANGE = 2162;
    SCI_HIDESELECTION = 2163;
    SCI_POINTXFROMPOSITION = 2164;
    SCI_POINTYFROMPOSITION = 2165;
    SCI_LINEFROMPOSITION = 2166;
    SCI_POSITIONFROMLINE = 2167;
    SCI_LINESCROLL = 2168;
    SCI_SCROLLCARET = 2169;
    SCI_REPLACESEL = 2170;
    SCI_SETREADONLY = 2171;
    SCI_NULL = 2172;
    SCI_CANPASTE = 2173;
    SCI_CANUNDO = 2174;
    SCI_EMPTYUNDOBUFFER = 2175;
    SCI_UNDO = 2176;
    SCI_CUT = 2177;
    SCI_COPY = 2178;
    SCI_PASTE = 2179;
    SCI_CLEAR = 2180;
    SCI_SETTEXT = 2181;
    SCI_GETTEXT = 2182;
    SCI_GETTEXTLENGTH = 2183;
    SCI_GETDIRECTFUNCTION = 2184;
    SCI_GETDIRECTPOINTER = 2185;
    SCI_SETOVERTYPE = 2186;
    SCI_GETOVERTYPE = 2187;
    SCI_SETCARETWIDTH = 2188;
    SCI_GETCARETWIDTH = 2189;
    SCI_SETTARGETSTART = 2190;
    SCI_GETTARGETSTART = 2191;
    SCI_SETTARGETEND = 2192;
    SCI_GETTARGETEND = 2193;
    SCI_REPLACETARGET = 2194;
    SCI_REPLACETARGETRE = 2195;
    SCI_SEARCHINTARGET = 2197;
    SCI_SETSEARCHFLAGS = 2198;
    SCI_GETSEARCHFLAGS = 2199;
    SCI_CALLTIPSHOW = 2200;
    SCI_CALLTIPCANCEL = 2201;
    SCI_CALLTIPACTIVE = 2202;
    SCI_CALLTIPPOSSTART = 2203;
    SCI_CALLTIPSETHLT = 2204;
    SCI_CALLTIPSETBACK = 2205;
    SCI_CALLTIPSETFORE = 2206;
    SCI_CALLTIPSETFOREHLT = 2207;
    SCI_VISIBLEFROMDOCLINE = 2220;
    SCI_DOCLINEFROMVISIBLE = 2221;
    SC_FOLDLEVELBASE = $400;
    SC_FOLDLEVELWHITEFLAG = $1000;
    SC_FOLDLEVELHEADERFLAG = $2000;
    SC_FOLDLEVELBOXHEADERFLAG = $4000;
    SC_FOLDLEVELBOXFOOTERFLAG = $8000;
    SC_FOLDLEVELCONTRACTED = $10000;
    SC_FOLDLEVELUNINDENT = $20000;
    SC_FOLDLEVELNUMBERMASK = $0FFF;
    SCI_SETFOLDLEVEL = 2222;
    SCI_GETFOLDLEVEL = 2223;
    SCI_GETLASTCHILD = 2224;
    SCI_GETFOLDPARENT = 2225;
    SCI_SHOWLINES = 2226;
    SCI_HIDELINES = 2227;
    SCI_GETLINEVISIBLE = 2228;
    SCI_SETFOLDEXPANDED = 2229;
    SCI_GETFOLDEXPANDED = 2230;
    SCI_TOGGLEFOLD = 2231;
    SCI_ENSUREVISIBLE = 2232;
    SC_FOLDFLAG_LINEBEFORE_EXPANDED = $0002;
    SC_FOLDFLAG_LINEBEFORE_CONTRACTED = $0004;
    SC_FOLDFLAG_LINEAFTER_EXPANDED = $0008;
    SC_FOLDFLAG_LINEAFTER_CONTRACTED = $0010;
    SC_FOLDFLAG_LEVELNUMBERS = $0040;
    SC_FOLDFLAG_BOX = $0001;
    SCI_SETFOLDFLAGS = 2233;
    SCI_ENSUREVISIBLEENFORCEPOLICY = 2234;
    SCI_SETTABINDENTS = 2260;
    SCI_GETTABINDENTS = 2261;
    SCI_SETBACKSPACEUNINDENTS = 2262;
    SCI_GETBACKSPACEUNINDENTS = 2263;
    SC_TIME_FOREVER = 10000000;
    SCI_SETMOUSEDWELLTIME = 2264;
    SCI_GETMOUSEDWELLTIME = 2265;
    SCI_WORDSTARTPOSITION = 2266;
    SCI_WORDENDPOSITION = 2267;
    SC_WRAP_NONE = 0;
    SC_WRAP_WORD = 1;
    SCI_SETWRAPMODE = 2268;
    SCI_GETWRAPMODE = 2269;
    SC_CACHE_NONE = 0;
    SC_CACHE_CARET = 1;
    SC_CACHE_PAGE = 2;
    SC_CACHE_DOCUMENT = 3;
    SCI_SETLAYOUTCACHE = 2272;
    SCI_GETLAYOUTCACHE = 2273;
    SCI_SETSCROLLWIDTH = 2274;
    SCI_GETSCROLLWIDTH = 2275;
    SCI_TEXTWIDTH = 2276;
    SCI_SETENDATLASTLINE = 2277;
    SCI_GETENDATLASTLINE = 2278;
    SCI_TEXTHEIGHT = 2279;
    SCI_SETVSCROLLBAR = 2280;
    SCI_GETVSCROLLBAR = 2281;
    SCI_APPENDTEXT = 2282;
    SCI_GETTWOPHASEDRAW = 2283;
    SCI_SETTWOPHASEDRAW = 2284;
    SCI_TARGETFROMSELECTION = 2287;
    SCI_LINESJOIN = 2288;
    SCI_LINESSPLIT = 2289;
    SCI_SETFOLDMARGINCOLOUR = 2290;
    SCI_SETFOLDMARGINHICOLOUR = 2291;
    SCI_LINEDOWN = 2300;
    SCI_LINEDOWNEXTEND = 2301;
    SCI_LINEUP = 2302;
    SCI_LINEUPEXTEND = 2303;
    SCI_CHARLEFT = 2304;
    SCI_CHARLEFTEXTEND = 2305;
    SCI_CHARRIGHT = 2306;
    SCI_CHARRIGHTEXTEND = 2307;
    SCI_WORDLEFT = 2308;
    SCI_WORDLEFTEXTEND = 2309;
    SCI_WORDRIGHT = 2310;
    SCI_WORDRIGHTEXTEND = 2311;
    SCI_HOME = 2312;
    SCI_HOMEEXTEND = 2313;
    SCI_LINEEND = 2314;
    SCI_LINEENDEXTEND = 2315;
    SCI_DOCUMENTSTART = 2316;
    SCI_DOCUMENTSTARTEXTEND = 2317;
    SCI_DOCUMENTEND = 2318;
    SCI_DOCUMENTENDEXTEND = 2319;
    SCI_PAGEUP = 2320;
    SCI_PAGEUPEXTEND = 2321;
    SCI_PAGEDOWN = 2322;
    SCI_PAGEDOWNEXTEND = 2323;
    SCI_EDITTOGGLEOVERTYPE = 2324;
    SCI_CANCEL = 2325;
    SCI_DELETEBACK = 2326;
    SCI_TAB = 2327;
    SCI_BACKTAB = 2328;
    SCI_NEWLINE = 2329;
    SCI_FORMFEED = 2330;
    SCI_VCHOME = 2331;
    SCI_VCHOMEEXTEND = 2332;
    SCI_ZOOMIN = 2333;
    SCI_ZOOMOUT = 2334;
    SCI_DELWORDLEFT = 2335;
    SCI_DELWORDRIGHT = 2336;
    SCI_LINECUT = 2337;
    SCI_LINEDELETE = 2338;
    SCI_LINETRANSPOSE = 2339;
    SCI_LINEDUPLICATE = 2404;
    SCI_LOWERCASE = 2340;
    SCI_UPPERCASE = 2341;
    SCI_LINESCROLLDOWN = 2342;
    SCI_LINESCROLLUP = 2343;
    SCI_DELETEBACKNOTLINE = 2344;
    SCI_HOMEDISPLAY = 2345;
    SCI_HOMEDISPLAYEXTEND = 2346;
    SCI_LINEENDDISPLAY = 2347;
    SCI_LINEENDDISPLAYEXTEND = 2348;
    SCI_HOMEWRAP = 2349;
    SCI_HOMEWRAPEXTEND = 2450;
    SCI_LINEENDWRAP = 2451;
    SCI_LINEENDWRAPEXTEND = 2452;
    SCI_VCHOMEWRAP = 2453;
    SCI_VCHOMEWRAPEXTEND = 2454;
    SCI_LINECOPY = 2455;
    SCI_MOVECARETINSIDEVIEW = 2401;
    SCI_LINELENGTH = 2350;
    SCI_BRACEHIGHLIGHT = 2351;
    SCI_BRACEBADLIGHT = 2352;
    SCI_BRACEMATCH = 2353;
    SCI_GETVIEWEOL = 2355;
    SCI_SETVIEWEOL = 2356;
    SCI_GETDOCPOINTER = 2357;
    SCI_SETDOCPOINTER = 2358;
    SCI_SETMODEVENTMASK = 2359;
    EDGE_NONE = 0;
    EDGE_LINE = 1;
    EDGE_BACKGROUND = 2;
    SCI_GETEDGECOLUMN = 2360;
    SCI_SETEDGECOLUMN = 2361;
    SCI_GETEDGEMODE = 2362;
    SCI_SETEDGEMODE = 2363;
    SCI_GETEDGECOLOUR = 2364;
    SCI_SETEDGECOLOUR = 2365;
    SCI_SEARCHANCHOR = 2366;
    SCI_SEARCHNEXT = 2367;
    SCI_SEARCHPREV = 2368;
    SCI_LINESONSCREEN = 2370;
    SCI_USEPOPUP = 2371;
    SCI_SELECTIONISRECTANGLE = 2372;
    SCI_SETZOOM = 2373;
    SCI_GETZOOM = 2374;
    SCI_CREATEDOCUMENT = 2375;
    SCI_ADDREFDOCUMENT = 2376;
    SCI_RELEASEDOCUMENT = 2377;
    SCI_GETMODEVENTMASK = 2378;
    SCI_SETFOCUSEX = 2380;
    SCI_GETFOCUS = 2381;
    SCI_SETSTATUS = 2382;
    SCI_GETSTATUS = 2383;
    SCI_SETMOUSEDOWNCAPTURES = 2384;
    SCI_GETMOUSEDOWNCAPTURES = 2385;
    SC_CURSORNORMAL = -1;
    SC_CURSORWAIT = 4;
    SCI_SETCURSOR = 2386;
    SCI_GETCURSOR = 2387;
    SCI_SETCONTROLCHARSYMBOL = 2388;
    SCI_GETCONTROLCHARSYMBOL = 2389;
    SCI_WORDPARTLEFT = 2390;
    SCI_WORDPARTLEFTEXTEND = 2391;
    SCI_WORDPARTRIGHT = 2392;
    SCI_WORDPARTRIGHTEXTEND = 2393;
    VISIBLE_SLOP = $01;
    VISIBLE_STRICT = $04;
    SCI_SETVISIBLEPOLICY = 2394;
    SCI_DELLINELEFT = 2395;
    SCI_DELLINERIGHT = 2396;
    SCI_SETXOFFSET = 2397;
    SCI_GETXOFFSET = 2398;
    SCI_CHOOSECARETX = 2399;
    SCI_GRABFOCUS = 2400;
    CARET_SLOP = $01;
    CARET_STRICT = $04;
    CARET_JUMPS = $10;
    CARET_EVEN = $08;
    SCI_SETXCARETPOLICY = 2402;
    SCI_SETYCARETPOLICY = 2403;
    SCI_SETPRINTWRAPMODE = 2406;
    SCI_GETPRINTWRAPMODE = 2407;
    SCI_SETHOTSPOTACTIVEFORE = 2410;
    SCI_SETHOTSPOTACTIVEBACK = 2411;
    SCI_SETHOTSPOTACTIVEUNDERLINE = 2412;
    SCI_SETHOTSPOTSINGLELINE = 2421;
    SCI_PARADOWN = 2413;
    SCI_PARADOWNEXTEND = 2414;
    SCI_PARAUP = 2415;
    SCI_PARAUPEXTEND = 2416;
    SCI_POSITIONBEFORE = 2417;
    SCI_POSITIONAFTER = 2418;
    SCI_COPYRANGE = 2419;
    SCI_COPYTEXT = 2420;
    SC_SEL_STREAM = 0;
    SC_SEL_RECTANGLE = 1;
    SC_SEL_LINES = 2;
    SCI_SETSELECTIONMODE = 2422;
    SCI_GETSELECTIONMODE = 2423;
    SCI_GETLINESELSTARTPOSITION = 2424;
    SCI_GETLINESELENDPOSITION = 2425;
    SCI_LINEDOWNRECTEXTEND = 2426;
    SCI_LINEUPRECTEXTEND = 2427;
    SCI_CHARLEFTRECTEXTEND = 2428;
    SCI_CHARRIGHTRECTEXTEND = 2429;
    SCI_HOMERECTEXTEND = 2430;
    SCI_VCHOMERECTEXTEND = 2431;
    SCI_LINEENDRECTEXTEND = 2432;
    SCI_PAGEUPRECTEXTEND = 2433;
    SCI_PAGEDOWNRECTEXTEND = 2434;
    SCI_STARTRECORD = 3001;
    SCI_STOPRECORD = 3002;
    SCI_SETLEXER = 4001;
    SCI_GETLEXER = 4002;
    SCI_COLOURISE = 4003;
    SCI_SETPROPERTY = 4004;
    KEYWORDSET_MAX = 8;
    SCI_SETKEYWORDS = 4005;
    SCI_SETLEXERLANGUAGE = 4006;
    SCI_LOADLEXERLIBRARY = 4007;
    SC_MOD_INSERTTEXT = $1;
    SC_MOD_DELETETEXT = $2;
    SC_MOD_CHANGESTYLE = $4;
    SC_MOD_CHANGEFOLD = $8;
    SC_PERFORMED_USER = $10;
    SC_PERFORMED_UNDO = $20;
    SC_PERFORMED_REDO = $40;
    SC_LASTSTEPINUNDOREDO = $100;
    SC_MOD_CHANGEMARKER = $200;
    SC_MOD_BEFOREINSERT = $400;
    SC_MOD_BEFOREDELETE = $800;
    SC_MODEVENTMASKALL = $F77;
    SCEN_CHANGE = 768;
    SCEN_SETFOCUS = 512;
    SCEN_KILLFOCUS = 256;
    SCK_DOWN = 300;
    SCK_UP = 301;
    SCK_LEFT = 302;
    SCK_RIGHT = 303;
    SCK_HOME = 304;
    SCK_END = 305;
    SCK_PRIOR = 306;
    SCK_NEXT = 307;
    SCK_DELETE = 308;
    SCK_INSERT = 309;
    SCK_ESCAPE = 7;
    SCK_BACK = 8;
    SCK_TAB = 9;
    SCK_RETURN = 13;
    SCK_ADD = 310;
    SCK_SUBTRACT = 311;
    SCK_DIVIDE = 312;
    SCMOD_SHIFT = 1;
    SCMOD_CTRL = 2;
    SCMOD_ALT = 4;
    SCLEX_CONTAINER = 0;
    SCLEX_NULL = 1;
    SCLEX_PYTHON = 2;
    SCLEX_CPP = 3;
    SCLEX_HTML = 4;
    SCLEX_XML = 5;
    SCLEX_PERL = 6;
    SCLEX_SQL = 7;
    SCLEX_VB = 8;
    SCLEX_PROPERTIES = 9;
    SCLEX_ERRORLIST = 10;
    SCLEX_MAKEFILE = 11;
    SCLEX_BATCH = 12;
    SCLEX_XCODE = 13;
    SCLEX_LATEX = 14;
    SCLEX_LUA = 15;
    SCLEX_DIFF = 16;
    SCLEX_CONF = 17;
    SCLEX_PASCAL = 18;
    SCLEX_AVE = 19;
    SCLEX_ADA = 20;
    SCLEX_LISP = 21;
    SCLEX_RUBY = 22;
    SCLEX_EIFFEL = 23;
    SCLEX_EIFFELKW = 24;
    SCLEX_TCL = 25;
    SCLEX_NNCRONTAB = 26;
    SCLEX_BULLANT = 27;
    SCLEX_VBSCRIPT = 28;
    SCLEX_ASP = 29;
    SCLEX_PHP = 30;
    SCLEX_BAAN = 31;
    SCLEX_MATLAB = 32;
    SCLEX_SCRIPTOL = 33;
    SCLEX_ASM = 34;
    SCLEX_CPPNOCASE = 35;
    SCLEX_FORTRAN = 36;
    SCLEX_F77 = 37;
    SCLEX_CSS = 38;
    SCLEX_POV = 39;
    SCLEX_LOUT = 40;
    SCLEX_ESCRIPT = 41;
    SCLEX_PS = 42;
    SCLEX_NSIS = 43;
    SCLEX_MMIXAL = 44;
    SCLEX_CLW = 45;
    SCLEX_CLWNOCASE = 46;
    SCLEX_LOT = 47;
    SCLEX_YAML = 48;
    SCLEX_TEX = 49;
    SCLEX_METAPOST = 50;
    SCLEX_POWERBASIC = 51;
    SCLEX_FORTH = 52;
    SCLEX_AUTOMATIC = 1000;
    SCE_P_DEFAULT = 0;
    SCE_P_COMMENTLINE = 1;
    SCE_P_NUMBER = 2;
    SCE_P_STRING = 3;
    SCE_P_CHARACTER = 4;
    SCE_P_WORD = 5;
    SCE_P_TRIPLE = 6;
    SCE_P_TRIPLEDOUBLE = 7;
    SCE_P_CLASSNAME = 8;
    SCE_P_DEFNAME = 9;
    SCE_P_OPERATOR = 10;
    SCE_P_IDENTIFIER = 11;
    SCE_P_COMMENTBLOCK = 12;
    SCE_P_STRINGEOL = 13;
    SCE_C_DEFAULT = 0;
    SCE_C_COMMENT = 1;
    SCE_C_COMMENTLINE = 2;
    SCE_C_COMMENTDOC = 3;
    SCE_C_NUMBER = 4;
    SCE_C_WORD = 5;
    SCE_C_STRING = 6;
    SCE_C_CHARACTER = 7;
    SCE_C_UUID = 8;
    SCE_C_PREPROCESSOR = 9;
    SCE_C_OPERATOR = 10;
    SCE_C_IDENTIFIER = 11;
    SCE_C_STRINGEOL = 12;
    SCE_C_VERBATIM = 13;
    SCE_C_REGEX = 14;
    SCE_C_COMMENTLINEDOC = 15;
    SCE_C_WORD2 = 16;
    SCE_C_COMMENTDOCKEYWORD = 17;
    SCE_C_COMMENTDOCKEYWORDERROR = 18;
    SCE_C_GLOBALCLASS = 19;
    SCE_H_DEFAULT = 0;
    SCE_H_TAG = 1;
    SCE_H_TAGUNKNOWN = 2;
    SCE_H_ATTRIBUTE = 3;
    SCE_H_ATTRIBUTEUNKNOWN = 4;
    SCE_H_NUMBER = 5;
    SCE_H_DOUBLESTRING = 6;
    SCE_H_SINGLESTRING = 7;
    SCE_H_OTHER = 8;
    SCE_H_COMMENT = 9;
    SCE_H_ENTITY = 10;
    SCE_H_TAGEND = 11;
    SCE_H_XMLSTART = 12;
    SCE_H_XMLEND = 13;
    SCE_H_SCRIPT = 14;
    SCE_H_ASP = 15;
    SCE_H_ASPAT = 16;
    SCE_H_CDATA = 17;
    SCE_H_QUESTION = 18;
    SCE_H_VALUE = 19;
    SCE_H_XCCOMMENT = 20;
    SCE_H_SGML_DEFAULT = 21;
    SCE_H_SGML_COMMAND = 22;
    SCE_H_SGML_1ST_PARAM = 23;
    SCE_H_SGML_DOUBLESTRING = 24;
    SCE_H_SGML_SIMPLESTRING = 25;
    SCE_H_SGML_ERROR = 26;
    SCE_H_SGML_SPECIAL = 27;
    SCE_H_SGML_ENTITY = 28;
    SCE_H_SGML_COMMENT = 29;
    SCE_H_SGML_1ST_PARAM_COMMENT = 30;
    SCE_H_SGML_BLOCK_DEFAULT = 31;
    SCE_HJ_START = 40;
    SCE_HJ_DEFAULT = 41;
    SCE_HJ_COMMENT = 42;
    SCE_HJ_COMMENTLINE = 43;
    SCE_HJ_COMMENTDOC = 44;
    SCE_HJ_NUMBER = 45;
    SCE_HJ_WORD = 46;
    SCE_HJ_KEYWORD = 47;
    SCE_HJ_DOUBLESTRING = 48;
    SCE_HJ_SINGLESTRING = 49;
    SCE_HJ_SYMBOLS = 50;
    SCE_HJ_STRINGEOL = 51;
    SCE_HJ_REGEX = 52;
    SCE_HJA_START = 55;
    SCE_HJA_DEFAULT = 56;
    SCE_HJA_COMMENT = 57;
    SCE_HJA_COMMENTLINE = 58;
    SCE_HJA_COMMENTDOC = 59;
    SCE_HJA_NUMBER = 60;
    SCE_HJA_WORD = 61;
    SCE_HJA_KEYWORD = 62;
    SCE_HJA_DOUBLESTRING = 63;
    SCE_HJA_SINGLESTRING = 64;
    SCE_HJA_SYMBOLS = 65;
    SCE_HJA_STRINGEOL = 66;
    SCE_HJA_REGEX = 67;
    SCE_HB_START = 70;
    SCE_HB_DEFAULT = 71;
    SCE_HB_COMMENTLINE = 72;
    SCE_HB_NUMBER = 73;
    SCE_HB_WORD = 74;
    SCE_HB_STRING = 75;
    SCE_HB_IDENTIFIER = 76;
    SCE_HB_STRINGEOL = 77;
    SCE_HBA_START = 80;
    SCE_HBA_DEFAULT = 81;
    SCE_HBA_COMMENTLINE = 82;
    SCE_HBA_NUMBER = 83;
    SCE_HBA_WORD = 84;
    SCE_HBA_STRING = 85;
    SCE_HBA_IDENTIFIER = 86;
    SCE_HBA_STRINGEOL = 87;
    SCE_HP_START = 90;
    SCE_HP_DEFAULT = 91;
    SCE_HP_COMMENTLINE = 92;
    SCE_HP_NUMBER = 93;
    SCE_HP_STRING = 94;
    SCE_HP_CHARACTER = 95;
    SCE_HP_WORD = 96;
    SCE_HP_TRIPLE = 97;
    SCE_HP_TRIPLEDOUBLE = 98;
    SCE_HP_CLASSNAME = 99;
    SCE_HP_DEFNAME = 100;
    SCE_HP_OPERATOR = 101;
    SCE_HP_IDENTIFIER = 102;
    SCE_HPA_START = 105;
    SCE_HPA_DEFAULT = 106;
    SCE_HPA_COMMENTLINE = 107;
    SCE_HPA_NUMBER = 108;
    SCE_HPA_STRING = 109;
    SCE_HPA_CHARACTER = 110;
    SCE_HPA_WORD = 111;
    SCE_HPA_TRIPLE = 112;
    SCE_HPA_TRIPLEDOUBLE = 113;
    SCE_HPA_CLASSNAME = 114;
    SCE_HPA_DEFNAME = 115;
    SCE_HPA_OPERATOR = 116;
    SCE_HPA_IDENTIFIER = 117;
    SCE_HPHP_DEFAULT = 118;
    SCE_HPHP_HSTRING = 119;
    SCE_HPHP_SIMPLESTRING = 120;
    SCE_HPHP_WORD = 121;
    SCE_HPHP_NUMBER = 122;
    SCE_HPHP_VARIABLE = 123;
    SCE_HPHP_COMMENT = 124;
    SCE_HPHP_COMMENTLINE = 125;
    SCE_HPHP_HSTRING_VARIABLE = 126;
    SCE_HPHP_OPERATOR = 127;
    SCE_PL_DEFAULT = 0;
    SCE_PL_ERROR = 1;
    SCE_PL_COMMENTLINE = 2;
    SCE_PL_POD = 3;
    SCE_PL_NUMBER = 4;
    SCE_PL_WORD = 5;
    SCE_PL_STRING = 6;
    SCE_PL_CHARACTER = 7;
    SCE_PL_PUNCTUATION = 8;
    SCE_PL_PREPROCESSOR = 9;
    SCE_PL_OPERATOR = 10;
    SCE_PL_IDENTIFIER = 11;
    SCE_PL_SCALAR = 12;
    SCE_PL_ARRAY = 13;
    SCE_PL_HASH = 14;
    SCE_PL_SYMBOLTABLE = 15;
    SCE_PL_REGEX = 17;
    SCE_PL_REGSUBST = 18;
    SCE_PL_LONGQUOTE = 19;
    SCE_PL_BACKTICKS = 20;
    SCE_PL_DATASECTION = 21;
    SCE_PL_HERE_DELIM = 22;
    SCE_PL_HERE_Q = 23;
    SCE_PL_HERE_QQ = 24;
    SCE_PL_HERE_QX = 25;
    SCE_PL_STRING_Q = 26;
    SCE_PL_STRING_QQ = 27;
    SCE_PL_STRING_QX = 28;
    SCE_PL_STRING_QR = 29;
    SCE_PL_STRING_QW = 30;
    SCE_B_DEFAULT = 0;
    SCE_B_COMMENT = 1;
    SCE_B_NUMBER = 2;
    SCE_B_KEYWORD = 3;
    SCE_B_STRING = 4;
    SCE_B_PREPROCESSOR = 5;
    SCE_B_OPERATOR = 6;
    SCE_B_IDENTIFIER = 7;
    SCE_B_DATE = 8;
    SCE_PROPS_DEFAULT = 0;
    SCE_PROPS_COMMENT = 1;
    SCE_PROPS_SECTION = 2;
    SCE_PROPS_ASSIGNMENT = 3;
    SCE_PROPS_DEFVAL = 4;
    SCE_L_DEFAULT = 0;
    SCE_L_COMMAND = 1;
    SCE_L_TAG = 2;
    SCE_L_MATH = 3;
    SCE_L_COMMENT = 4;
    SCE_LUA_DEFAULT = 0;
    SCE_LUA_COMMENT = 1;
    SCE_LUA_COMMENTLINE = 2;
    SCE_LUA_COMMENTDOC = 3;
    SCE_LUA_NUMBER = 4;
    SCE_LUA_WORD = 5;
    SCE_LUA_STRING = 6;
    SCE_LUA_CHARACTER = 7;
    SCE_LUA_LITERALSTRING = 8;
    SCE_LUA_PREPROCESSOR = 9;
    SCE_LUA_OPERATOR = 10;
    SCE_LUA_IDENTIFIER = 11;
    SCE_LUA_STRINGEOL = 12;
    SCE_LUA_WORD2 = 13;
    SCE_LUA_WORD3 = 14;
    SCE_LUA_WORD4 = 15;
    SCE_LUA_WORD5 = 16;
    SCE_LUA_WORD6 = 17;
    SCE_LUA_WORD7 = 18;
    SCE_LUA_WORD8 = 19;
    SCE_ERR_DEFAULT = 0;
    SCE_ERR_PYTHON = 1;
    SCE_ERR_GCC = 2;
    SCE_ERR_MS = 3;
    SCE_ERR_CMD = 4;
    SCE_ERR_BORLAND = 5;
    SCE_ERR_PERL = 6;
    SCE_ERR_NET = 7;
    SCE_ERR_LUA = 8;
    SCE_ERR_CTAG = 9;
    SCE_ERR_DIFF_CHANGED = 10;
    SCE_ERR_DIFF_ADDITION = 11;
    SCE_ERR_DIFF_DELETION = 12;
    SCE_ERR_DIFF_MESSAGE = 13;
    SCE_ERR_PHP = 14;
    SCE_ERR_ELF = 15;
    SCE_ERR_IFC = 16;
    SCE_BAT_DEFAULT = 0;
    SCE_BAT_COMMENT = 1;
    SCE_BAT_WORD = 2;
    SCE_BAT_LABEL = 3;
    SCE_BAT_HIDE = 4;
    SCE_BAT_COMMAND = 5;
    SCE_BAT_IDENTIFIER = 6;
    SCE_BAT_OPERATOR = 7;
    SCE_MAKE_DEFAULT = 0;
    SCE_MAKE_COMMENT = 1;
    SCE_MAKE_PREPROCESSOR = 2;
    SCE_MAKE_IDENTIFIER = 3;
    SCE_MAKE_OPERATOR = 4;
    SCE_MAKE_TARGET = 5;
    SCE_MAKE_IDEOL = 9;
    SCE_DIFF_DEFAULT = 0;
    SCE_DIFF_COMMENT = 1;
    SCE_DIFF_COMMAND = 2;
    SCE_DIFF_HEADER = 3;
    SCE_DIFF_POSITION = 4;
    SCE_DIFF_DELETED = 5;
    SCE_DIFF_ADDED = 6;
    SCE_CONF_DEFAULT = 0;
    SCE_CONF_COMMENT = 1;
    SCE_CONF_NUMBER = 2;
    SCE_CONF_IDENTIFIER = 3;
    SCE_CONF_EXTENSION = 4;
    SCE_CONF_PARAMETER = 5;
    SCE_CONF_STRING = 6;
    SCE_CONF_OPERATOR = 7;
    SCE_CONF_IP = 8;
    SCE_CONF_DIRECTIVE = 9;
    SCE_AVE_DEFAULT = 0;
    SCE_AVE_COMMENT = 1;
    SCE_AVE_NUMBER = 2;
    SCE_AVE_WORD = 3;
    SCE_AVE_STRING = 6;
    SCE_AVE_ENUM = 7;
    SCE_AVE_STRINGEOL = 8;
    SCE_AVE_IDENTIFIER = 9;
    SCE_AVE_OPERATOR = 10;
    SCE_AVE_WORD1 = 11;
    SCE_AVE_WORD2 = 12;
    SCE_AVE_WORD3 = 13;
    SCE_AVE_WORD4 = 14;
    SCE_AVE_WORD5 = 15;
    SCE_AVE_WORD6 = 16;
    SCE_ADA_DEFAULT = 0;
    SCE_ADA_WORD = 1;
    SCE_ADA_IDENTIFIER = 2;
    SCE_ADA_NUMBER = 3;
    SCE_ADA_DELIMITER = 4;
    SCE_ADA_CHARACTER = 5;
    SCE_ADA_CHARACTEREOL = 6;
    SCE_ADA_STRING = 7;
    SCE_ADA_STRINGEOL = 8;
    SCE_ADA_LABEL = 9;
    SCE_ADA_COMMENTLINE = 10;
    SCE_ADA_ILLEGAL = 11;
    SCE_BAAN_DEFAULT = 0;
    SCE_BAAN_COMMENT = 1;
    SCE_BAAN_COMMENTDOC = 2;
    SCE_BAAN_NUMBER = 3;
    SCE_BAAN_WORD = 4;
    SCE_BAAN_STRING = 5;
    SCE_BAAN_PREPROCESSOR = 6;
    SCE_BAAN_OPERATOR = 7;
    SCE_BAAN_IDENTIFIER = 8;
    SCE_BAAN_STRINGEOL = 9;
    SCE_BAAN_WORD2 = 10;
    SCE_LISP_DEFAULT = 0;
    SCE_LISP_COMMENT = 1;
    SCE_LISP_NUMBER = 2;
    SCE_LISP_KEYWORD = 3;
    SCE_LISP_STRING = 6;
    SCE_LISP_STRINGEOL = 8;
    SCE_LISP_IDENTIFIER = 9;
    SCE_LISP_OPERATOR = 10;
    SCE_EIFFEL_DEFAULT = 0;
    SCE_EIFFEL_COMMENTLINE = 1;
    SCE_EIFFEL_NUMBER = 2;
    SCE_EIFFEL_WORD = 3;
    SCE_EIFFEL_STRING = 4;
    SCE_EIFFEL_CHARACTER = 5;
    SCE_EIFFEL_OPERATOR = 6;
    SCE_EIFFEL_IDENTIFIER = 7;
    SCE_EIFFEL_STRINGEOL = 8;
    SCE_NNCRONTAB_DEFAULT = 0;
    SCE_NNCRONTAB_COMMENT = 1;
    SCE_NNCRONTAB_TASK = 2;
    SCE_NNCRONTAB_SECTION = 3;
    SCE_NNCRONTAB_KEYWORD = 4;
    SCE_NNCRONTAB_MODIFIER = 5;
    SCE_NNCRONTAB_ASTERISK = 6;
    SCE_NNCRONTAB_NUMBER = 7;
    SCE_NNCRONTAB_STRING = 8;
    SCE_NNCRONTAB_ENVIRONMENT = 9;
    SCE_NNCRONTAB_IDENTIFIER = 10;
    SCE_FORTH_DEFAULT = 0;
    SCE_FORTH_COMMENT = 1;
    SCE_FORTH_COMMENT_ML = 2;
    SCE_FORTH_IDENTIFIER = 3;
    SCE_FORTH_CONTROL = 4;
    SCE_FORTH_KEYWORD = 5;
    SCE_FORTH_DEFWORD = 6;
    SCE_FORTH_PREWORD1 = 7;
    SCE_FORTH_PREWORD2 = 8;
    SCE_FORTH_NUMBER = 9;
    SCE_FORTH_STRING = 10;
    SCE_FORTH_LOCALE = 11;
    SCE_MATLAB_DEFAULT = 0;
    SCE_MATLAB_COMMENT = 1;
    SCE_MATLAB_COMMAND = 2;
    SCE_MATLAB_NUMBER = 3;
    SCE_MATLAB_KEYWORD = 4;
    SCE_MATLAB_STRING = 5;
    SCE_MATLAB_OPERATOR = 6;
    SCE_MATLAB_IDENTIFIER = 7;
    SCE_SCRIPTOL_DEFAULT = 0;
    SCE_SCRIPTOL_WHITE = 1;
    SCE_SCRIPTOL_COMMENTLINE = 2;
    SCE_SCRIPTOL_PERSISTENT = 3;
    SCE_SCRIPTOL_CSTYLE = 4;
    SCE_SCRIPTOL_COMMENTBLOCK = 5;
    SCE_SCRIPTOL_NUMBER = 6;
    SCE_SCRIPTOL_STRING = 7;
    SCE_SCRIPTOL_CHARACTER = 8;
    SCE_SCRIPTOL_STRINGEOL = 9;
    SCE_SCRIPTOL_KEYWORD = 10;
    SCE_SCRIPTOL_OPERATOR = 11;
    SCE_SCRIPTOL_IDENTIFIER = 12;
    SCE_SCRIPTOL_TRIPLE = 13;
    SCE_SCRIPTOL_CLASSNAME = 14;
    SCE_SCRIPTOL_PREPROCESSOR = 15;
    SCE_ASM_DEFAULT = 0;
    SCE_ASM_COMMENT = 1;
    SCE_ASM_NUMBER = 2;
    SCE_ASM_STRING = 3;
    SCE_ASM_OPERATOR = 4;
    SCE_ASM_IDENTIFIER = 5;
    SCE_ASM_CPUINSTRUCTION = 6;
    SCE_ASM_MATHINSTRUCTION = 7;
    SCE_ASM_REGISTER = 8;
    SCE_ASM_DIRECTIVE = 9;
    SCE_ASM_DIRECTIVEOPERAND = 10;
    SCE_ASM_COMMENTBLOCK = 11;
    SCE_ASM_CHARACTER = 12;
    SCE_ASM_STRINGEOL = 13;
    SCE_ASM_EXTINSTRUCTION = 14;
    SCE_F_DEFAULT = 0;
    SCE_F_COMMENT = 1;
    SCE_F_NUMBER = 2;
    SCE_F_STRING1 = 3;
    SCE_F_STRING2 = 4;
    SCE_F_STRINGEOL = 5;
    SCE_F_OPERATOR = 6;
    SCE_F_IDENTIFIER = 7;
    SCE_F_WORD = 8;
    SCE_F_WORD2 = 9;
    SCE_F_WORD3 = 10;
    SCE_F_PREPROCESSOR = 11;
    SCE_F_OPERATOR2 = 12;
    SCE_F_LABEL = 13;
    SCE_F_CONTINUATION = 14;
    SCE_CSS_DEFAULT = 0;
    SCE_CSS_TAG = 1;
    SCE_CSS_CLASS = 2;
    SCE_CSS_PSEUDOCLASS = 3;
    SCE_CSS_UNKNOWN_PSEUDOCLASS = 4;
    SCE_CSS_OPERATOR = 5;
    SCE_CSS_IDENTIFIER = 6;
    SCE_CSS_UNKNOWN_IDENTIFIER = 7;
    SCE_CSS_VALUE = 8;
    SCE_CSS_COMMENT = 9;
    SCE_CSS_ID = 10;
    SCE_CSS_IMPORTANT = 11;
    SCE_CSS_DIRECTIVE = 12;
    SCE_CSS_DOUBLESTRING = 13;
    SCE_CSS_SINGLESTRING = 14;
    SCE_POV_DEFAULT = 0;
    SCE_POV_COMMENT = 1;
    SCE_POV_COMMENTLINE = 2;
    SCE_POV_NUMBER = 3;
    SCE_POV_OPERATOR = 4;
    SCE_POV_IDENTIFIER = 5;
    SCE_POV_STRING = 6;
    SCE_POV_STRINGEOL = 7;
    SCE_POV_DIRECTIVE = 8;
    SCE_POV_BADDIRECTIVE = 9;
    SCE_POV_WORD2 = 10;
    SCE_POV_WORD3 = 11;
    SCE_POV_WORD4 = 12;
    SCE_POV_WORD5 = 13;
    SCE_POV_WORD6 = 14;
    SCE_POV_WORD7 = 15;
    SCE_POV_WORD8 = 16;
    SCE_LOUT_DEFAULT = 0;
    SCE_LOUT_COMMENT = 1;
    SCE_LOUT_NUMBER = 2;
    SCE_LOUT_WORD = 3;
    SCE_LOUT_WORD2 = 4;
    SCE_LOUT_WORD3 = 5;
    SCE_LOUT_WORD4 = 6;
    SCE_LOUT_STRING = 7;
    SCE_LOUT_OPERATOR = 8;
    SCE_LOUT_IDENTIFIER = 9;
    SCE_LOUT_STRINGEOL = 10;
    SCE_ESCRIPT_DEFAULT = 0;
    SCE_ESCRIPT_COMMENT = 1;
    SCE_ESCRIPT_COMMENTLINE = 2;
    SCE_ESCRIPT_COMMENTDOC = 3;
    SCE_ESCRIPT_NUMBER = 4;
    SCE_ESCRIPT_WORD = 5;
    SCE_ESCRIPT_STRING = 6;
    SCE_ESCRIPT_OPERATOR = 7;
    SCE_ESCRIPT_IDENTIFIER = 8;
    SCE_ESCRIPT_BRACE = 9;
    SCE_ESCRIPT_WORD2 = 10;
    SCE_ESCRIPT_WORD3 = 11;
    SCE_PS_DEFAULT = 0;
    SCE_PS_COMMENT = 1;
    SCE_PS_DSC_COMMENT = 2;
    SCE_PS_DSC_VALUE = 3;
    SCE_PS_NUMBER = 4;
    SCE_PS_NAME = 5;
    SCE_PS_KEYWORD = 6;
    SCE_PS_LITERAL = 7;
    SCE_PS_IMMEVAL = 8;
    SCE_PS_PAREN_ARRAY = 9;
    SCE_PS_PAREN_DICT = 10;
    SCE_PS_PAREN_PROC = 11;
    SCE_PS_TEXT = 12;
    SCE_PS_HEXSTRING = 13;
    SCE_PS_BASE85STRING = 14;
    SCE_PS_BADSTRINGCHAR = 15;
    SCE_NSIS_DEFAULT = 0;
    SCE_NSIS_COMMENT = 1;
    SCE_NSIS_STRINGDQ = 2;
    SCE_NSIS_STRINGLQ = 3;
    SCE_NSIS_STRINGRQ = 4;
    SCE_NSIS_FUNCTION = 5;
    SCE_NSIS_VARIABLE = 6;
    SCE_NSIS_LABEL = 7;
    SCE_NSIS_USERDEFINED = 8;
    SCE_NSIS_SECTIONDEF = 9;
    SCE_NSIS_SUBSECTIONDEF = 10;
    SCE_NSIS_IFDEFINEDEF = 11;
    SCE_NSIS_MACRODEF = 12;
    SCE_NSIS_STRINGVAR = 13;
    SCE_MMIXAL_LEADWS = 0;
    SCE_MMIXAL_COMMENT = 1;
    SCE_MMIXAL_LABEL = 2;
    SCE_MMIXAL_OPCODE = 3;
    SCE_MMIXAL_OPCODE_PRE = 4;
    SCE_MMIXAL_OPCODE_VALID = 5;
    SCE_MMIXAL_OPCODE_UNKNOWN = 6;
    SCE_MMIXAL_OPCODE_POST = 7;
    SCE_MMIXAL_OPERANDS = 8;
    SCE_MMIXAL_NUMBER = 9;
    SCE_MMIXAL_REF = 10;
    SCE_MMIXAL_CHAR = 11;
    SCE_MMIXAL_STRING = 12;
    SCE_MMIXAL_REGISTER = 13;
    SCE_MMIXAL_HEX = 14;
    SCE_MMIXAL_OPERATOR = 15;
    SCE_MMIXAL_SYMBOL = 16;
    SCE_MMIXAL_INCLUDE = 17;
    SCE_CLW_DEFAULT = 0;
    SCE_CLW_LABEL = 1;
    SCE_CLW_COMMENT = 2;
    SCE_CLW_STRING = 3;
    SCE_CLW_USER_IDENTIFIER = 4;
    SCE_CLW_INTEGER_CONSTANT = 5;
    SCE_CLW_REAL_CONSTANT = 6;
    SCE_CLW_PICTURE_STRING = 7;
    SCE_CLW_KEYWORD = 8;
    SCE_CLW_COMPILER_DIRECTIVE = 9;
    SCE_CLW_BUILTIN_PROCEDURES_FUNCTION = 10;
    SCE_CLW_STRUCTURE_DATA_TYPE = 11;
    SCE_CLW_ATTRIBUTE = 12;
    SCE_CLW_STANDARD_EQUATE = 13;
    SCE_CLW_ERROR = 14;
    SCE_LOT_DEFAULT = 0;
    SCE_LOT_HEADER = 1;
    SCE_LOT_BREAK = 2;
    SCE_LOT_SET = 3;
    SCE_LOT_PASS = 4;
    SCE_LOT_FAIL = 5;
    SCE_LOT_ABORT = 6;
    SCE_YAML_DEFAULT = 0;
    SCE_YAML_COMMENT = 1;
    SCE_YAML_IDENTIFIER = 2;
    SCE_YAML_KEYWORD = 3;
    SCE_YAML_NUMBER = 4;
    SCE_YAML_REFERENCE = 5;
    SCE_YAML_DOCUMENT = 6;
    SCE_YAML_TEXT = 7;
    SCE_YAML_ERROR = 8;
    SCE_TEX_DEFAULT = 0;
    SCE_TEX_SPECIAL = 1;
    SCE_TEX_GROUP = 2;
    SCE_TEX_SYMBOL = 3;
    SCE_TEX_COMMAND = 4;
    SCE_TEX_TEXT = 5;
    SCE_METAPOST_DEFAULT = 0;
    SCE_METAPOST_SPECIAL = 1;
    SCE_METAPOST_GROUP = 2;
    SCE_METAPOST_SYMBOL = 3;
    SCE_METAPOST_COMMAND = 4;
    SCE_METAPOST_TEXT = 5;
    SCE_METAPOST_EXTRA = 6;
    SCN_STYLENEEDED = 2000;
    SCN_CHARADDED = 2001;
    SCN_SAVEPOINTREACHED = 2002;
    SCN_SAVEPOINTLEFT = 2003;
    SCN_MODIFYATTEMPTRO = 2004;
    SCN_KEY = 2005;
    SCN_DOUBLECLICK = 2006;
    SCN_UPDATEUI = 2007;
    SCN_MODIFIED = 2008;
    SCN_MACRORECORD = 2009;
    SCN_MARGINCLICK = 2010;
    SCN_NEEDSHOWN = 2011;
    SCN_PAINTED = 2013;
    SCN_USERLISTSELECTION = 2014;
    SCN_URIDROPPED = 2015;
    SCN_DWELLSTART = 2016;
    SCN_DWELLEND = 2017;
    SCN_ZOOM = 2018;
    SCN_HOTSPOTCLICK = 2019;
    SCN_HOTSPOTDOUBLECLICK = 2020;
    SCN_CALLTIPCLICK = 2021;

    SC_UPDATE_CONTENT = 1;
    SC_UPDATE_SELECTION = 2;
    SC_UPDATE_V_SCROLL = 4;
    SC_UPDATE_H_SCROLL = 8;
//--Const

implementation

end.
