{ (c) 1994-98 Phil Hetherington, P&M Research Technologies, Inc.}
UNIT SurfTypes;
INTERFACE
USES Windows,Graphics,Messages,SurfPublicTypes;
CONST
  WM_SURF_IN = WM_USER + 100;
  WM_SURF_OUT = WM_USER + 101;

CONST
   SURF_OUT_HANDLE          = 1000;
   SURF_OUT_PROBE           = 1001;
   SURF_OUT_SPIKE           = 1002;
   SURF_OUT_SPIKE_ARRAY     = 1003;
   SURF_OUT_CR              = 1004;
   SURF_OUT_CR_ARRAY        = 1005;
   SURF_OUT_SV              = 1006;
   SURF_OUT_SV_ARRAY        = 1007;
   SURF_OUT_MSG             = 1008;
   SURF_OUT_MSG_ARRAY       = 1009;
   SURF_OUT_SURFEVENT       = 1010;
   SURF_OUT_SURFEVENT_ARRAY = 1011;
   SURF_OUT_FILESTART       = 1012;
   SURF_OUT_FILEEND         = 1013;

   SURF_IN_HANDLE    = 2000;
   SURF_IN_SPIKE     = 2001;
   SURF_IN_CR        = 2002;
   SURF_IN_SV        = 2003;
   SURF_IN_DAC       = 2004;
   SURF_IN_DIO       = 2005;
   SURF_IN_READFILE  = 2006;
   SURF_IN_SAVEFILE  = 2007;
TYPE
{ Surf uses a format similar to DW's uff data file structure.  The major difference is the
  absense of most of th records, and the unification of all spike and continuous records into
  one called the POLYTRODE record.  The POLYTRODE record can have 2 subtypes, the SPIKETYPE and
  the CONTINUOUSTYPE.  Both can have any length waveform.  The SPIKETYPE can have any number of
  channels, but the CONTINUOUSTYPE can have only one channel. In addition there are singlevalue
  records, for the storage of single 2B words, and mesg records, for the storage of 256B ShortStrings}

  SURF_LAYOUT_REC_V1 = record { Type for all spike layout records }
    ufftype        : CHAR; // Record type  chr(234)
    time_stamp     : LNG;  // Time stamp
    surf_major     : BYTE; // SURF major version number
    surf_minor     : BYTE; // SURF minor version number

    probe          : SHRT; //Probe number
    ProbeSubType   : CHAR; //=S,C for spiketype or continuoustype
    nchans         : SHRT; //number of channels in the waveform
    pts_per_chan   : SHRT; //number of pts per waveform
    trigpt         : SHRT; // pts before trigger
    lockout        : SHRT; // Lockout in pts
    intgain        : SHRT; // A/D board internal gain
    threshold      : SHRT; // A/D board threshold for trigger
    skippts        : SHRT;
    sampfreqperchan: LNG;  // A/D sampling frequency
    chanlist       : TChanList;
    screenlayout   : TScreenLayout;
    probe_descrip  : ShortString;
    extgain        : array[0..SURF_MAX_CHANNELS-1] of WORD;//added May21'99
    pad            : array[0..1023-64{959}] of byte;
  end;

  SURF_PT_REC = record //My spike record
    ufftype       : CHAR;{1 byte} // SURF_PT_REC_UFFTYPE
    subtype       : CHAR;{1 byte} //=S,C for spike or continuous
    time_stamp    : LNG;{4 bytes}
    probe         : SHRT;{2 bytes}{the probe number}
    cluster       : SHRT;{2 bytes}
    adc_waveform  : TWaveForm//adc_waveform_type;
  end;

  SURF_SV_REC = record //My single value record
    ufftype       : CHAR;//1 byte -- SURF_SV_REC_UFFTYPE
    subtype       : CHAR;//1 byte -- 'D' digital or 'A' analog
    time_stamp    : LNG; //4 bytes
    sval          : WORD;//2 bytes -- 16 bit value
  end;

  SURF_MSG_REC = record //My message record
    ufftype       : CHAR;//1 byte -- SURF_MSG_REC_UFFTYPE
    subtype       : CHAR;//1 byte -- can be used for different values
    time_stamp    : LNG; //4 bytes
    msg           : ShortString;//256 bytes
  end;

  TBufDesc = record
    d1,d2,d3,d4,d5 : integer;
  end;

IMPLEMENTATION
END.
