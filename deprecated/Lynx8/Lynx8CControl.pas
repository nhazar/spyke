UNIT Lynx8CControl;

INTERFACE

USES
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  OleCtrls, DTAcq32Lib_TLB, DtxPascal, StdCtrls, ExtCtrls, Spin;

CONST
   BIT0   =   $0001;      // bit #0 value
   BIT1   =   $0002;      // bit #1 value
   BIT2   =   $0004;      // bit #2 value
   BIT3   =   $0008;      // bit #3 value
   BIT4   =   $0010;      // bit #4 value
   BIT5   =   $0020;      // bit #5 value
   BIT6   =   $0040;      // bit #6 value
   BIT7   =   $0080;      // bit #7 value
   BIT8   =   $0100;      // bit #8 value
   BIT9   =   $0200;      // bit #9 value
   BIT10  =   $0400;      // bit #10 value
   BIT11  =   $0800;      // bit #11 value
   BIT12  =   $1000;      // bit #12 value
   BIT13  =   $2000;      // bit #13 value
   BIT14  =   $4000;      // bit #14 value
   BIT15  =   $8000;      // bit #15 value

  SEQ_CTR_REG_LOAD   = BIT12;
  SEQ_CTR_REG_INC    = BIT13;
  AMP_REG_LOAD       = BIT14;
  DC_EQU_SW_REG_LOAD = BIT15;

  FILTER_REG_START = 0;
  GAIN_REG_START   = 8;

  LOWCUT_TENTHHZ   = 0;
  LOWCUT_1HZ	= BIT0;
  LOWCUT_10HZ	= BIT1;
  LOWCUT_100HZ	= BIT2;
  LOWCUT_300HZ	= BIT3;
  LOWCUT_600HZ	= BIT4;
  LOWCUT_900HZ	= (BIT3 or BIT4);

  HICUT_50HZ	= 0;
  HICUT_125HZ	= BIT5;   // 120 HZ ACTUALLY
  HICUT_200HZ	= BIT8;
  HICUT_250HZ	= BIT9;
  HICUT_275HZ	= (BIT5  or BIT8);
  HICUT_325HZ	= (BIT5  or BIT9);
  HICUT_400HZ	= (BIT8  or BIT9);
  HICUT_475HZ	= (BIT5  or BIT8 or BIT9);
  HICUT_3KHZ	= BIT6;
  HICUT_6KHZ	= BIT7;
  HICUT_9KHZ	= (BIT6  or BIT7);

  REF_FULL_GAIN	= 50000;
//  ALL_CHANNELS	= 9; // used for the display function

  DTDIO_PIO_OUTPUT	= 1;	// enables pio byte for output
  DTDIO_PIO_INPUT	= 0;	// enables pio byte for input
  DTDIO_DAC_X		= $0080;  // dac X channel output port
  DTDIO_DAC_Y		= $0180;  // dac Y channel output port
  DTDIO_DAC_XY		= $0000;  // dac X and Y channel output
  DTDIO_DAC_MIN_VALUE	= 0;	// dac min output value
  DTDIO_DAC_MAX_VALUE	= 4095;	// dac max output value

  PORTADDRESS : array[0..1] of Word = ($378,$278);

TYPE
  WordArray = array[0..7] of Word;
  TLynx8Amp = class(TForm)
    Label4: TLabel;
    DOUTBits: TLabel;
    doutval: TLabel;
    Label1: TLabel;
    dinval: TLabel;
    DINBits: TLabel;
    Label5: TLabel;
    Label2: TLabel;
    WordSpin: TSpinEdit;
    Button1: TButton;
    Label3: TLabel;
    DIO: TDTAcq32;
    procedure WordSpinChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
     Function  LoadSeqCtrReg(nreg_value : Word) : integer;
     //Procedure IncSeqCtrReg;
     Function  LoadCurAmpReg(nload_value : Word) : integer;
     //Procedure SetFilterGainList(var lpnfilter_settings, lpngain_settings : WordArray);
     Function  vDTDIO_pio_read : Word{16 bit unsigned};
     //Procedure vDTDIO_pio_init( port0,port1 : byte);
     Function  BitOn(w : WORD; Bit : integer) : boolean;
     procedure SetDinBits(w : word);
     procedure SetDoutBits(w : word);
     Procedure vDTDIO_pio_write( nvalue : Word{16 bit unsigned});
     Procedure OutputValue(nvalue : Word{unsigned 16 bit});
  public
    { Public declarations }
     last_pio_value_output : Word;
     filter_values,gain_values : WordArray;
     //SurfHandle : Hwnd;
     Procedure InitAmp;
     Function  SetEqualizeSwitches( nswitches_on : Word ) : integer;
     Function  LoadSingleFilterVal(nchannel, nfilter_setting : Word) : integer;
     Function  LoadSingleGainVal(nchannel, ngain_setting : Word) : integer;
     function InPort(port : word) : byte;
     Procedure OutPort(port : word; bval : byte);
     function OutPortV(port : word; bval : byte; state : byte) : boolean;
     procedure SetPortsForOutput;
     procedure SetPortsForInput;
  end;

var
  Lynx8Amp: TLynx8Amp;

IMPLEMENTATION

{==============================================================================}
function TLynx8Amp.InPort(port : word) : byte;
var value : byte;
Begin
  asm
    mov dx,port
    in al,dx
    mov value,al
  end;
  InPort := value;
end;

{==============================================================================}
procedure TLynx8Amp.OutPort(port : word; bval : byte);
begin
  asm
    push ax  // back up ax
    push dx  // back up dx

    {direct port write}
    mov dx,port
    mov al,bval
    out dx,al

    pop dx  // restore dx
    pop ax  // restore ax
  end;
end;

{====================================================================}
function TLynx8Amp.OutPortV(port : word; bval : byte; state : byte) : boolean;
var value : byte;
begin
  asm
    mov dx,port
    in al,dx
    mov value,al
  end;
  if state <> value then
  begin
    Showmessage('Port was not ready');
    OutPortV:= false;
    exit;
  end else
  asm
    push ax  // back up ax
    push dx  // back up dx

    //direct port write
    mov  dx,port
    mov al,bval
    out dx,al

    pop dx  // restore dx
    pop ax  // restore ax
  end;
  OutPortV:= True;
end;

{====================================================================}
Procedure TLynx8Amp.vDTDIO_pio_write( nvalue : Word{16 bit unsigned});
begin
  //SetDOutBits(nvalue);
  //SetPortsForOutput;
  DIO.PutSingleValue(0,1.0,ULNG(nvalue));
  //SetPortsForInput;
  //SetDInBits(vDTDIO_pio_read);
end;

{====================================================================}
Function TLynx8Amp.vDTDIO_pio_read : Word{16 bit unsigned};
begin
  vDTDIO_pio_read := WORD(DIO.GetSingleValue(0,1.0));
end;

{====================================================================}
(*Procedure TLynx8Amp.vDTDIO_pio_init( port0,port1 : byte);
begin
end; *)

{====================================================================}
Procedure TLynx8Amp.InitAmp;
{ This will setup the DTDIO PIO ports as outputs and set the high 4
  control bits of the register (bits 12->15).  Setting these bits will
  get the control section to accept commands as these 4 bits are activited
  by lowering the line.}
var i : integer;
begin
  //Setup a DT ActiveX object as a DOUT
//Select Board
  if DIO.numboards = 0 then
  begin
    ShowMessage('No boards found');
    Exit;
  end;
  if DIO.numboards = 1 then
  begin
    //ShowMessage('Only 1 board found.  Lynx8Control will use '+DIO.BoardList[0]);
    DIO.Board := DIO.BoardList[0];
  end;

  if DIO.numboards > 1 then
  begin
    for i := 0 to DIO.numboards-1 do
      if DIO.BoardList[i] = 'DT3010B' then DIO.Board := DIO.BoardList[i];
    if DIO.Board = '' then
    begin
      DIO.Board := DIO.BoardList[1];
      ShowMessage('DT3010B A/D board not found.  Lynx8Control will use '+DIO.BoardList[0]);
    end;
  end;

  // set the DTDIO PIO port as output
  last_pio_value_output := 0;
  SetPortsForOutput;

  vDTDIO_pio_write($FFFF);  // enable all reg's to 1's
  // set the 4 control lines to hi
  OutputValue( SEQ_CTR_REG_LOAD or SEQ_CTR_REG_INC or
                   AMP_REG_LOAD or DC_EQU_SW_REG_LOAD );
  SetPortsForInput;
end;

{====================================================================}
Procedure TLynx8Amp.OutputValue(nvalue : Word);
{ this will output the value to the PIO port and save this value in the
  nlast_pio_value_output variable.}
begin
  // set the 4 control lines to hi
  vDTDIO_pio_write( nvalue );
  // save the value set
  last_pio_value_output := nvalue;
end;

{====================================================================}
Function TLynx8Amp.SetEqualizeSwitches( nswitches_on : Word ) : integer;
{ This will output the switch bit values passed in to the amp data bus
 (lower 12 bits) and will lower and raise the DC Equalize Switch register
 bit to load the specified value into the switches.}
var nvalue : Word;
begin
    // make sure that a bogus value has not been passed
    if (nswitches_on > $00FF) then
    begin
      SetEqualizeSwitches := -1;
      exit;
    end;

    SetPortsForOutput;

    // raise the control lines to make sure we don't screw up data
    OutputValue( $F000 or last_pio_value_output );
    nvalue := $F000 or nswitches_on;
    OutputValue(nvalue);

    // now output same value with the switch register load bit low
    nvalue := nvalue and (not DC_EQU_SW_REG_LOAD);
    OutputValue(nvalue);

    // now raise the switch register load bit to lock in the values in sw reg
    nvalue := nvalue or DC_EQU_SW_REG_LOAD;
    OutputValue(nvalue);
    SetEqualizeSwitches := 0;

    SetPortsForInput;
end;

{====================================================================}
Function TLynx8Amp.LoadSeqCtrReg(nreg_value : Word) : integer;
{ This will load the sequence counter register with the value spec'd.
 This will involve setting the register value number on the data bus and
 lowering and raising the control line to load the counter register of the
 74'163 chip. }
var nvalue : Word;
begin
    if ( (nreg_value >15){ or (nreg_value <0)} ) then
    begin
      LoadSeqCtrReg := -1;
      exit;
    end;

    // raise the control lines to make sure we don't screw up data
    OutputValue( $F000 or last_pio_value_output );

    // or in the register value to set the data bus to
    nvalue := $F000 or nreg_value;
    OutputValue(nvalue);

    // lower the seq ctr reg load bit
    nvalue := nvalue and (not SEQ_CTR_REG_LOAD);
    OutputValue(nvalue);

    // lower and raise the clock signal to pass the preset through on the 163
    nvalue := nvalue and (not SEQ_CTR_REG_INC);
    OutputValue(nvalue);
    nvalue := nvalue or SEQ_CTR_REG_INC;
    OutputValue(nvalue);

    // raise the seq ctr reg load bit
    nvalue := nvalue or SEQ_CTR_REG_LOAD;
    OutputValue(nvalue);
    LoadSeqCtrReg := 0;
end;

{====================================================================}
(*Procedure TLynx8Amp.IncSeqCtrReg;
{ this will lower and raise the Seq Ctr Reg Inc line.}
var nvalue : Word;
begin
    nvalue := last_pio_value_output and (not SEQ_CTR_REG_INC);
    OutputValue(nvalue);

    nvalue := nvalue or SEQ_CTR_REG_INC;
    OutputValue(nvalue);
end;  *)

{====================================================================}
Function TLynx8Amp.LoadCurAmpReg(nload_value : Word) : integer;
{ This will put the value spec'd on the amp data bus and will lower and raise
  the control line to load the value into the current register.  The register
  which gets loaded will be that which is pointed to by the Sequence Register
  Counter (the 74163 chip).}
var nvalue : Word;
begin
    // make sure that the load value is not outside of 0 -> 12 bits
    if ( {(nload_value <0) or }(nload_value >4095) ) then
    begin
      LoadCurAmpReg := -1;
      exit;
    end;

    // raise all control lines with current 12 bit data
    nvalue := last_pio_value_output or $F000;
    OutputValue(nvalue);

    // output the data value on the amp's data bus
    nvalue := $F000 or nload_value;
    OutputValue(nvalue);

    // lower the load reg control line
    nvalue := nvalue and (not AMP_REG_LOAD);
    OutputValue(nvalue);

    // raise the load reg control line to lock the value in
    nvalue := nvalue or AMP_REG_LOAD;
    OutputValue(nvalue);
    LoadCurAmpReg := 0;
end;

{====================================================================}
(*Procedure TLynx8Amp.SetFilterGainList(var lpnfilter_settings, lpngain_settings : WordArray);
{ This will down load the filter setting and gain settings arrays which are
 passed in.  Each list will be 8 entries long.  The amp will be loaded in
 sequence from filter0 to gain7.}
var i : Word;
begin
    // point the sequence counter register to the start of the filters
    LoadSeqCtrReg( FILTER_REG_START );

    // load each of the filter settings
    for i := 0 to 7 do
    begin
      LoadCurAmpReg(lpnfilter_settings[i]);
      IncSeqCtrReg;
      filter_values[i] := lpnfilter_settings[i];
    end;

    // load each of the gain settings and inc the seq ctr after each one
    for i := 0 to 7 do
    begin
      LoadCurAmpReg(lpngain_settings[i]);
      IncSeqCtrReg;
      gain_values[i] := lpngain_settings[i];
    end;
end;
*)

{====================================================================}
Function TLynx8Amp.LoadSingleFilterVal(nchannel, nfilter_setting : Word) : integer;
{ This will load the spec'd channel's filter setting register to that spec'd.}
begin
  if ( {(nchannel <0) or }(nchannel > 8) or
       {(nfilter_setting <0) or} (nfilter_setting> $03FF) ) then
  begin
    LoadSingleFilterVal := -1;
    exit;
  end;

  LoadSeqCtrReg( FILTER_REG_START + nchannel );
  LoadCurAmpReg( nfilter_setting );
  filter_values[nchannel] := nfilter_setting;

  LoadSingleFilterVal := 0;
end;

{====================================================================}
Function  TLynx8Amp.LoadSingleGainVal(nchannel, ngain_setting : Word) : integer;
{ This will load the spec'd channel's gain setting register to that spec'd.}
begin
    if {(nchannel <0) or }(nchannel > 8) or
       {(ngain_setting <0) or }(ngain_setting> $0FFF) then
    begin
      LoadSingleGainVal := -1;
      exit;
    end;

    LoadSeqCtrReg( GAIN_REG_START + nchannel );
    LoadCurAmpReg( ngain_setting );
    gain_values[nchannel] := ngain_setting;
    LoadSingleGainVal := 0;
end;

{--------------------------------------------------------------------------------}
Function TLynx8Amp.BitOn(w : WORD; Bit : integer) : boolean;
begin
  BitOn := FALSE;
  case bit of
    0 : if w AND BIT0 <> 0 then Biton := TRUE;
    1 : if w AND BIT1 <> 0 then Biton := TRUE;
    2 : if w AND BIT2 <> 0 then Biton := TRUE;
    3 : if w AND BIT3 <> 0 then Biton := TRUE;
    4 : if w AND BIT4 <> 0 then Biton := TRUE;
    5 : if w AND BIT5 <> 0 then Biton := TRUE;
    6 : if w AND BIT6 <> 0 then Biton := TRUE;
    7 : if w AND BIT7 <> 0 then Biton := TRUE;
    8 : if w AND BIT8 <> 0 then Biton := TRUE;
    9 : if w AND BIT9 <> 0 then Biton := TRUE;
    10 : if w AND BIT10 <> 0 then Biton := TRUE;
    11 : if w AND BIT11 <> 0 then Biton := TRUE;
    12 : if w AND BIT12 <> 0 then Biton := TRUE;
    13 : if w AND BIT13 <> 0 then Biton := TRUE;
    14 : if w AND BIT14 <> 0 then Biton := TRUE;
    15 : if w AND BIT15 <> 0 then Biton := TRUE;
  end;
end;

{--------------------------------------------------------------------------------}
procedure TLynx8Amp.SetDinBits(w : word);
var s : string;
    i : integer;
begin
  s := '';
  for i := 0 to 15 do
    if BitOn(w,i) then s := '+'+s else s := '-'+s;
  DinBits.Caption := s;
  DinVal.Caption := inttostr(w);
end;

{--------------------------------------------------------------------------------}
procedure TLynx8Amp.SetDoutBits(w : word);
var s : string;
    i : integer;
begin
  s := '';
  for i := 0 to 15 do
    if BitOn(w,i) then s := '+'+s else s := '-'+s;
  DoutBits.Caption := s;
  DoutVal.Caption := inttostr(w);
end;

{$R *.DFM}

procedure TLynx8Amp.WordSpinChange(Sender: TObject);
begin
  SetPortsForOutput;
  vDTDIO_pio_write(WordSpin.value);
  SetDOutBits(WordSpin.value);
  SetPortsForInput;
  SetDInBits(vDTDIO_pio_read);
end;

procedure TLynx8Amp.Button1Click(Sender: TObject);
begin
  SetPortsForInput;
  SetDInBits(vDTDIO_pio_read);
end;

procedure TLynx8Amp.SetPortsForOutput;
begin
  DIO.SubSysType := OLSS_DOUT;//set type = Digital Output
  DIO.SubSysElement := 0;
  DIO.DataFlow := OL_DF_SINGLEVALUE; //set up for single value operation
  DIO.Resolution := 16;
	DIO.Config;
end;
procedure TLynx8Amp.SetPortsForInput;
begin
  DIO.SubSysType := OLSS_DIN;//set type = Digital Input, for now
  DIO.SubSysElement := 0;
  DIO.DataFlow := OL_DF_SINGLEVALUE; //set up for single value operation
  DIO.Resolution := 16;
  DIO.Config;
end;

end.