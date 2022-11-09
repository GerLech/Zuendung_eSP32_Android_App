unit Zuendung_ESP32;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, IniFiles,
  System.Bluetooth, FMX.StdCtrls, FMX.TabControl, System.Bluetooth.Components,
  FMX.Objects, System.ImageList, FMX.ImgList, FMX.Controls.Presentation,
  FMX.ExtCtrls, FMX.Edit, FMX.EditBox, FMX.NumberBox, System.Rtti,
  FMX.Grid.Style, FMX.Grid, FMX.ScrollBox, FireDAC.Stan.Intf,
  System.JSON, System.Math.Vectors, FMX.Memo.Types, FMX.Memo, System.Generics.Collections,
  FMX.ListBox, System.IOUtils, FMX.Layouts, FMX.Effects, FMX.Platform.Android;

type
  TTextEvent = procedure (const Sender: TObject; const AText: string; const aDeviceName: string) of object;
  TDisconnectEvent = procedure (const Sender: TObject; const aDeviceName: string) of object;

  TReadThread = class(TThread)
  private
    FSocket: TBluetoothSocket;
    FOnTextReceived: TTextEvent;
    FOnDisconnect: TDisconnectEvent;
    FName: string;
    procedure SetOnTextReceived(const Value: TTextEvent);
    procedure SetOnDisconnect(const Value: TDisconnectEvent);
  public
    constructor Create(const Socket: TBluetoothSocket; const Name: string); overload;
    procedure Execute; override;
    property OnTextReceived: TTextEvent read FOnTextReceived write SetOnTextReceived;
    property OnDisconnect: TDisconnectEvent read FOnDisconnect write SetOnDisconnect;
  end;

  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Panel2: TPanel;
    status: TCircle;
    profile: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    Button1: TButton;
    Label2: TLabel;
    Panel3: TPanel;
    imp1: TRadioButton;
    GroupBox1: TGroupBox;
    imp3: TRadioButton;
    GroupBox3: TGroupBox;
    Label3: TLabel;
    maxRpm: TNumberBox;
    Label6: TLabel;
    Label7: TLabel;
    maxDwellTime: TNumberBox;
    Label8: TLabel;
    Label9: TLabel;
    minDischTime: TNumberBox;
    Label10: TLabel;
    GroupBox4: TGroupBox;
    kennlinie: TStringGrid;
    colP: TIntegerColumn;
    pb: TImage;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    correction1: TNumberBox;
    correction2: TNumberBox;
    device: TLabel;
    log: TMemo;
    Button2: TButton;
    Bluetooth1: TBluetooth;
    Button3: TButton;
    Button4: TButton;
    BTStatus: TLabel;
    devices: TComboBox;
    colR: TCurrencyColumn;
    colA: TCurrencyColumn;
    ImageList2: TImageList;
    GroupBox5: TGroupBox;
    btn_conf: TSpeedButton;
    btn_load: TSpeedButton;
    btn_rename: TSpeedButton;
    btn_save: TSpeedButton;
    btn_saveas: TSpeedButton;
    btn_export: TSpeedButton;
    btn_import: TSpeedButton;
    btn_delete: TSpeedButton;
    btn_exit: TSpeedButton;
    Panel4: TPanel;
    Label4: TLabel;
    rpm: TLabel;
    Label5: TLabel;
    StyleBook1: TStyleBook;
    Popup1: TPopup;
    Layout1: TLayout;
    profiles: TListBox;
    ShadowEffect1: TShadowEffect;
    profileName: TLabel;
    Panel5: TPanel;
    Button6: TButton;
    Button5: TButton;
    procedure btn_confClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HandleException(Sender: Tobject; E:Exception) overload;
    procedure kennlinieEditingDone(Sender: TObject; const ACol, ARow: Integer);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure btn_loadClick(Sender: TObject);
    procedure btn_renameClick(Sender: TObject);
    procedure profilesChange(Sender: TObject);
    procedure btn_saveClick(Sender: TObject);
    procedure btn_deleteClick(Sender: TObject);
    procedure btn_exitClick(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure btn_saveasClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Bluetooth1DiscoveryEnd(const Sender: TObject;
      const ADeviceList: TBluetoothDeviceList);
  protected

  private
    { Private-Deklarationen }
    FBTData : String;
    FSocket : TBluetoothSocket;
    FReadThread: TReadThread;
    FUpdateProfiles: boolean;
    FDevice: String;
    FBTDevice: TBluetoothDevice;
    FProfile: String;
    r:Array of Integer;
    a:Array of Integer;
    isConnected : boolean;
    procedure GetDevices;
    function connectDevice( ADeviceName : String): boolean;
    procedure calcFirstCol();
    procedure fillFromJson(AJson : String);
    function GetProfileJson() : String;
    procedure fillListFromJson(AJson : String);
    procedure ManageData(data : String);
    procedure RequestStatus();
    procedure SetProfile(AName : String);
    procedure DeleteProfile(AName : String);
    procedure RenameProfile(AName : String);
    procedure UpdateProfile(AName : String);
    procedure LoadProfile( AProfile : String);
    procedure TextReceived(const Sender: TObject; const AText: string; const aDeviceName: string);
    procedure BTDisconnect(const Sender: TObject; const aDeviceName: string);
    procedure BTConnect();
    procedure showMessage(AType:TMsgDlgType; AMessage: string);
  private const
    LOCATION_PERMISSION = 'android.permission.ACCESS_FINE_LOCATION';
    C_LOCATION_PERMISSION = 'android.permission.ACCESS_COARSE_LOCATION';
  public
    { Public-Deklarationen }
    destructor Destroy; override;
  end;
const
  UUID =  '{00001101-0000-1000-8000-00805f9b34fb}';
var
  Form1: TForm1;

implementation

uses FMX.DialogService, System.Permissions;
{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.Moto360.fmx ANDROID}
{$R *.LgXhdpiTb.fmx ANDROID}

const
  defData = '{'+
    '"name":"default",'+
    '"singlePulse":false,'+
    '"maxRpm":7500,'+
    '"maxDwellTime":4700,'+
    '"minDischTime":2200,'+
    '"correction1":0,'+
    '"correction2":0,'+
    '"curve":[ '+
    '{"rpm":1400,"advance":5},'+
    '{"rpm":1600,"advance":10},'+
    '{"rpm":2000,"advance":17},'+
    '{"rpm":2400,"advance":22},'+
    '{"rpm":2900,"advance":25},'+
    '{"rpm":3600,"advance":27},'+
    '{"rpm":4300,"advance":28},'+
    '{"rpm":6000,"advance":29},'+
    '{"rpm":7400,"advance":29},'+
    '{"rpm":8000,"advance":11}]'+
    '}';

function BytesToString(const B: TBytes): string;
var
  I: Integer;
begin
  if Length(B) > 0 then
  begin
    Result := Format('%0.2X', [B[0]]);
    for I := 1 to High(B) do
      Result := Result + Format(' %0.2X', [B[I]]);
  end
  else
    Result := '';
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
profile.TabIndex :=0;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  log.Lines.Clear;
end;

procedure TForm1.GetDevices;
  var
    dev:TBluetoothDevice;
begin
  devices.Items.Clear;
  for dev in BlueTooth1.PairedDevices do
  begin
    devices.Items.Add(dev.DeviceName);
  end;

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  GetDevices;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  BTConnect();
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  if isConnected AND (profiles.ItemIndex >= 0)  then
  begin
    FProfile := profiles.Items[profiles.ItemIndex];
    LoadProfile(FProfile);
  end;
  
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Popup1.IsOpen := false;
end;

procedure TForm1.TextReceived(const Sender: TObject; const AText: string; const aDeviceName: string);
begin
  TThread.Queue(nil, procedure
    begin
      ManageData(AText);
    end);
end;

destructor TForm1.Destroy;
begin
  if FReadThread <> nil then
  begin
    FReadThread.Terminate;
    FReadThread.Free;
  end;
  inherited;
end;

procedure TForm1.HandleException(Sender: TObject; E:Exception);
begin
  log.lines.add('Exception: '+E.Message);
  BTDisconnect(Sender,'ESP32Zuendung');
end;

procedure TForm1.FormCreate(Sender: TObject);
var i:Integer;
begin
  inherited;
  Application.OnException := HandleException;
  FDevice := 'ESP32Zuendung';
  Layout1.Position.Point := TPointF.Zero;
  Popup1.Width := Layout1.Width;
  Popup1.Height := Layout1.Height;
  Layout1.Parent := Popup1;
  calcFirstCol();
  isConnected := false;
  FUpdateProfiles := false;
  pb.Bitmap.Clear($FFFFFF);
  pb.Bitmap := TBitmap.Create(398,170);
  SetLength(r,Kennlinie.RowCount);
  SetLength(a,Kennlinie.RowCount);
  for i := 1 to Kennlinie.RowCount do
  begin
    kennlinie.Cells[0,i-1] := i.ToString();
    kennlinie.Cells[1,i-1] := '0';
    kennlinie.Cells[2,i-1] := '0';
  end;
end;

procedure TForm1.FormShow(Sender: TObject);

begin
  if NOT isConnected then
  begin
  BTConnect;
  end;
end;

procedure TForm1.setProfile(AName : String);
begin
  ProfileName.Text := AName;
  FProfile := AName;
end;

procedure TForm1.fillFromJson(AJson : String);
var
  cur : TJsonArray;
  data: TJSONObject;
  el: TJSONObject;
  i : integer;
  vi : integer;
  vb : boolean;
  name : String;

begin
  name := '----';
  for i := 0 to 9 do
  begin
    r[i] := 0;
    a[i] := 0;
  end;
  data := TJSONObject(TJSOnObject.ParseJSONValue(AJson));
  try
    if data.TryGetValue<String>('name',name) then if vb then imp1.IsChecked := true else imp3.IsChecked := true;
    if name <> '----' then   FProfile :=  name;
    if data.TryGetValue<Boolean>('singlePulse',vb) then if vb then imp1.IsChecked := true else imp3.IsChecked := true;
    if data.TryGetValue<Integer>('maxRpm',vi) then maxRpm.Text := vi.ToString;
    if data.TryGetValue<Integer>('maxDwellTime',vi) then maxDwellTime.Text := vi.ToString;
    if data.TryGetValue<Integer>('minDischTime',vi) then minDischTime.Text := vi.ToString;
    if data.TryGetValue<Integer>('correction1',vi) then correction1.Text := vi.ToString;
    if data.TryGetValue<Integer>('correction2',vi) then correction2.Text := vi.ToString;

    if data.TryGetValue<TJSONArray>('curve',cur)then
    begin
      for i := 0 to cur.Count - 1 do
      begin
        el := TJSONObject(cur.Items[i]);
        el.TryGetValue<integer>('rpm',r[i]);
        el.TryGetValue<integer>('advance',a[i]);
      end;
    end;
    for i := 0 to 9 do
    begin
      kennlinie.Cells[1,i] := r[i].ToString;
      kennlinie.Cells[2,i] := a[i].ToString;
    end;
  finally
    data.Free;
  end;
  setProfile(name);

end;

function TForm1.GetProfileJson: string;
var   cur : TJsonArray;
  data: TJSONObject;
  el:TJsonObject;
  i : integer;

begin
  result := '';
  data := TJsonObject.Create;
  try
    data.AddPair('name',FProfile);
    data.AddPair('singlePulse',TJsonBool.Create(imp1.IsChecked));
    data.AddPair('maxRpm',TJsonNumber.Create(maxrpm.Text.ToInteger));
    data.AddPair('maxDwellTime',TJsonNumber.Create(maxDwellTime.Text.ToInteger));
    data.AddPair('minDischTime',TJsonNumber.Create(minDischTime.Text.ToInteger));
    data.AddPair('correction1',TJsonNumber.Create(correction1.Text.ToInteger));
    data.AddPair('correction2',TJsonNumber.Create(correction2.Text.ToInteger));
    cur := TJsonArray.Create;
    data.AddPair('curve',cur);
    for i := 0 to 9 do
    begin
      el := TJsonObject.Create;
      el.AddPair('rpm',TJsonNumber.Create(r[i]));
      el.AddPair('advance',TJsonNumber.Create(a[i]));
      cur.AddElement(el);
    end;
    result := data.ToJson;
  finally
    data.Free;
  end;
end;

procedure TForm1.kennlinieEditingDone(Sender: TObject; const ACol,
  ARow: Integer);
  var val : integer;
begin
  if ACol > 0 then val := kennlinie.Cells[ACol, ARow].ToInteger;

  if ACol = 1 then
  begin
    if val < 100 then   val := 100;
    if val > 10000 then  val := 10000;
    r[ARow] := val;
    kennlinie.Cells[ACol, ARow] := val.ToString;
  end;
  if ACol = 2 then
  begin
    if val < 0 then   val := 0;
    if val > 35 then  val := 35;
    a[ARow] := val;
    kennlinie.Cells[ACol, ARow] := val.ToString;
  end;
  //drawDiagram(pb.Bitmap.Canvas);
  pb.Repaint;
end;



procedure TForm1.loadProfile( AProfile : String);
begin
  if (FSocket <> nil) AND isConnected  then
  begin
    ProfileName.Text := '----';
    log.Lines.add('Sent data: L'+AProfile);
    FSocket.SendData(TEncoding.UTF8.GetBytes('L'+AProfile));
  end;
end;

procedure TForm1.calcFirstCol();
begin
  colP.Width:=kennlinie.Width-323;
end;



procedure TForm1.btn_confClick(Sender: TObject);
begin
  profile.TabIndex := 1;
end;



procedure TForm1.btn_deleteClick(Sender: TObject);
begin
  DeleteProfile(FProfile);
end;

procedure TForm1.btn_exitClick(Sender: TObject);
begin
  MainActivity.Finish;
end;

procedure TForm1.btn_loadClick(Sender: TObject);
begin
  Popup1.IsOpen := Not Popup1.IsOpen;
end;

procedure TForm1.btn_renameClick(Sender: TObject);
begin
  TDialogService.InputQuery('Umbenennen', ['Neuer Name'], [FProfile],
  procedure(const AResult: TModalResult; const AValues: array of string)
  var n:String;
  begin
    if AResult = MROK then
    begin
      n := AValues[0];
      if n.Length > 16 then n := n.Substring(0,16);
      if n <> FProfile then
      begin
        FProfile := n;
        ProfileName.Text := FProfile;
        renameProfile(FProfile);
      end
      else
      begin
        ShowMessage(TMsgDlgType.mtWarning,'Name wurde nicht geändert!');
      end;
    end;
  end);

end;

procedure TForm1.btn_saveasClick(Sender: TObject);
var n:String;
begin
  TDialogService.InputQuery('Speichern als', ['Neuer Name'], [FProfile],
  procedure(const AResult: TModalResult; const AValues: array of string)
  begin
    if AResult = MROK then
    begin
      n := AValues[0];
      if n.Length > 16 then n := n.Substring(0,16);
      if n <> FProfile then
      begin
        FProfile := n;
        ProfileName.Text := FProfile;
        UpdateProfile(FProfile);
      end
      else
      begin
        ShowMessage(TMsgDlgType.mtWarning,'Name wurde nicht geändert!');
      end;
    end;
  end);

end;

procedure TForm1.btn_saveClick(Sender: TObject);
begin
  UpdateProfile(FProfile);
end;

procedure TForm1.ManageData(data: string);
var cmd : Char;
    t : string;
    i : integer;
    list : TStrings;
begin
  list := TStringlist.create;
  try
    ExtractStrings([],[],PChar(data),list);
    //log.lines.Add('Got '+IntToStr(list.count)+' lines');
    for i := 0 to list.Count-1 do
    begin
      t := list[i];
      begin
        cmd := t[1];
        if (cmd <> 'R') then log.Lines.add('Got data: '+t);
        if (t <> '') then
        begin
          case cmd of
            'R': rpm.Text := t.Substring(1,length(data));
            'L': fillListFromJson(t.Substring(1,length(data)));
            'P': fillFromJson(t.Substring(1,length(data)));
            'O': showMessage(TMsgDlgType.mtInformation,t.Substring(1,length(data))); //log.Lines.Add('!'+data.Substring(1,length(data)));
            'E': showMessage(TMsgDlgType.mtError,t.Substring(1,length(data)));
          end;
        end;
      end;
    end;
  finally
    list.free;
  end;
end;

procedure TForm1.showMessage(AType: TMsgDlgType; AMessage: string);
begin
  TDialogService.MessageDialog(AMessage,AType,[TMsgDlgBtn.mbOK],TMsgDlgBtn.mbOK,0,
            procedure(const AResult: TModalResult) begin end);
end;
procedure TForm1.pbPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
const
  xo = 30;
  yo = 20;
  xm = 5;
  ym = 5;
  xu = 10;
  yu = 6;
var
i,w,h :integer;
dx,dy : single;
st:tStrokeBrush;
br:tBrush;
p1,p2 :tPointF;

begin
  Canvas.BeginScene;
  st := TStrokeBrush.Create(TBrushKind.Solid,tAlphaColorRec.DarkBlue);
  br := TBrush.Create(TBrushKind.Solid,tAlphaColorRec.Lemonchiffon);
  try
    st.Thickness := 2;
    w:= round(pb.Width);
    h:= round(pb.Height);
    dx := (w-xo-xm)/xu;
    dy := (h-yo-ym)/yu;
    Canvas.Fill.Color := tAlphaColorRec.Black;
    Canvas.FillRect(RectF(0,0,w,h),1,br);
    Canvas.DrawLine(PointF(xo,h-yo),PointF(xo,ym),1,st);
    Canvas.DrawLine(PointF(xo,h-yo),PointF(w-xm,h-yo),1,st);
    st.Color := tAlphaColorRec.Lightblue;
    st.Thickness := 1;
    Canvas.Font.Size := 9;
    for i := 0 to yu do
    begin
      if i>0 then Canvas.DrawLine(PointF(xo,h-yo-i*dy),PointF(w-xm,h-yo-i*dy),1,st);
      Canvas.FillText(RectF(0, h-yo-i*dy-10,xo, h-yo-i*dy+10),(i*5).ToString+'°',false,100,[], TTextAlign.Center, TTextAlign.Center );
    end;
    for i := 0 to xu do
    begin
      if i>0 then Canvas.DrawLine(PointF(xo+dx*i,h-yo),PointF(xo + dx*i,ym),1,st);
      Canvas.FillText(RectF(xo+dx*i -20, h-yo,xo+dx*i+20, h),i.ToString+'k',false,100,[], TTextAlign.Center, TTextAlign.Center );
    end;
    st.Color := tAlphaColorRec.Red;
    st.Thickness :=2;
    p2:= PointF(xo+dx*r[0]/1000,h-yo-a[0]*dy/5);
    Canvas.DrawLine(PointF(xo,h-yo-a[0]*dy/5),p2,1,st);
    for i := 0 to 8 do
    begin
      p1 := p2;
      p2 := PointF(xo+dx*r[i+1]/1000,h-yo-a[i+1]*dy/5);
      Canvas.DrawLine(p1,p2,1,st);
      Canvas.FillEllipse(RectF(p1.X-3,p1.y-3,p1.x+3,p1.y+3),1);
    end;
    Canvas.DrawLine(p2,PointF(w-xm,h-yo-a[9]*dy/5),1,st);
    Canvas.FillEllipse(RectF(p2.X-3,p2.y-3,p2.x+3,p2.y+3),1);
  finally
    st.Free;
    br.Free;
  end;
  canvas.EndScene;
end;

procedure TForm1.profilesChange(Sender: TObject);
begin
  if profiles.ItemIndex >= 0 then
  begin
   if Popup1.IsOpen then LoadProfile(profiles.Items[profiles.ItemIndex]);
  end;
  Popup1.IsOpen := false;
end;

procedure TForm1.fillListFromJson(AJson: string);
var
  list : TJsonArray;
  el: String;
  i : integer;
begin
  FUpdateProfiles := true;
  list := TJSONObject.ParseJSONValue(AJson) as TJSONArray;
  try
    begin
      profiles.Clear;
      for i := 0 to list.Count - 1 do
      begin
        el := list.Items[i].Value;
        profiles.Items.Add(el);
      end;
    end;

  finally
    list.Free;
  end;
  FUpdateProfiles := false;

end;

procedure TForm1.RequestStatus;
begin
  if (FSocket <> nil) AND isConnected then
  begin
    FSocket.SendData(TEncoding.UTF8.GetBytes('C'));
    log.Lines.Add('Sent Command C');
  end;
end;

function TForm1.connectDevice(ADeviceName: string): Boolean;
var
  dev : TBluetoothDevice;

begin
  Result := false;
  for dev in Bluetooth1.PairedDevices do
  begin
    if dev.DeviceName = ADeviceName then
    begin
      if true then
      begin
        FSocket := dev.CreateClientSocket(StringToGUID(UUID),false);
        if FSocket <> nil then
        begin
          FSocket.Connect;
          Result := FSocket.Connected;
          if Result then
          begin
            FBTData := '';
            FReadThread := TReadThread.Create(FSocket,ADeviceName);
            FReadThread.SetOnTextReceived(TextReceived);
            isConnected := true;
            status.Fill.Color := tAlphaColorRec.Lime;
            BTStatus.Text := 'verbunden';
            RequestStatus;
          end;
        end;
      end;
    end;
  end;

end;

procedure TForm1.Bluetooth1DiscoveryEnd(const Sender: TObject;
  const ADeviceList: TBluetoothDeviceList);
var
  dev : TBluetoothDevice;
  f : boolean;

begin
  f := false;
  dev := nil;
  devices.Items.Clear;
  log.Lines.Add('Discover finished '+IntToStr(ADeviceList.Count)+' devices');
  for dev in ADeviceList do
  begin
    devices.Items.Add(dev.DeviceName);
    if dev.DeviceName = FDevice then
    begin
      FBTDevice := dev;
      log.Lines.Add('Found device '+FDevice);
      f := true;
    end;
  end;
  if NOT f then
  begin
    log.Lines.Add('Device '+FDevice+' not found');
    showMessage(TMsgDlgType.mtWarning,'Zündung nicht gefunden');
  end
  else
  begin
    if NOT FBTDevice.IsPaired then
    begin
      log.Lines.Add('Start pairing');
      f := BlueTooth1.Pair(FBTDevice);
    end;
    if NOT f then
    begin
      log.Lines.Add('Pairing failed');
      showMessage(TMsgDlgType.mtWarning,'Zündung kann nicht gepaired werden');
    end
    else
    begin
      log.Lines.Add('Create socket');
      FSocket:= dev.CreateClientSocket(StringToGUID(UUID),false);
      if FSocket <> nil then
      begin
        try
          log.Lines.Add('Connect socket');
          FSocket.Connect;
          f := FSocket.Connected;
          if f then
          begin
            FBTData := '';
            FReadThread := TReadThread.Create(FSocket,FBTDevice.DeviceName);
            FReadThread.SetOnTextReceived(TextReceived);
            isConnected := true;
            status.Fill.Color := tAlphaColorRec.Lime;
            BTStatus.Text := 'verbunden';
            RequestStatus;
          end;
        except
          Fsocket.free;
        end;
      end;
    end;

  end;

end;

procedure TForm1.BTConnect;
begin
  log.Lines.Add('Start Discover');
  Bluetooth1.DiscoverDevices(10000);
end;

procedure TForm1.BTDisconnect(const Sender: TObject; const aDeviceName: string);
begin
  FReadThread.Terminate;
  FSocket.Free;
  isConnected := false;
  status.Fill.Color := TAlphaColorRec.Red;
  BTStatus.Text := 'nicht verbunden';
end;


procedure TForm1.DeleteProfile(AName : String);
begin
  if AName = 'default' then
  begin
    TDialogService.ShowMessage('Profil default darf nicht gelöscht werden')
  end
  else
  begin
    if (FSocket <> nil) AND isConnected then
    begin
      FSocket.SendData(TEncoding.UTF8.GetBytes('R'+FProfile));
    end
    else
    begin
      TDialogService.ShowMessage('Keine Bluetooth Verbindung')
    end;
  end;
end;

procedure TForm1.RenameProfile(AName: string);
begin
  if AName = 'default' then
  begin
    TDialogService.ShowMessage('Profil default darf nicht umbenannt werden')
  end
  else
  begin
    if (FSocket <> nil) AND isConnected then
    begin
      FSocket.SendData(TEncoding.UTF8.GetBytes('X'+GetProfileJson));
    end
    else
    begin
      TDialogService.ShowMessage('Keine Bluetooth Verbindung')
    end;
  end;
end;

procedure TForm1.UpdateProfile(AName : String);
begin
  if (FSocket <> nil) AND isConnected then
  begin
    FSocket.SendData(TEncoding.UTF8.GetBytes('U'+GetProfileJson));
  end
  else
  begin
    TDialogService.ShowMessage('Keine Bluetooth Verbindung')
  end;
end;

{ TReadThread }

constructor TReadThread.Create(const Socket: TBluetoothSocket; const Name: string);
begin
  FSocket := Socket;
  FName := Name;
  Create;
end;

procedure TReadThread.Execute;
var
  LBuffer: String;
  LReadSocket: TBluetoothSocket;
  LReset: Boolean;
begin
  inherited;
  Setlength(LBuffer,0);
  LBuffer := '';
  try
    while not Terminated do
    begin
      if FSocket.Connected then
      begin
        LReadSocket := FSocket; //.Accept(3000);
        if LReadSocket <> nil then
        begin
          LReset := False;
          While (not Terminated) and LReadSocket.Connected and (not LReset) do
          begin
            try
              LBuffer := LBuffer + TEncoding.UTF8.GetString(LReadSocket.ReceiveData);
              if (Length(LBuffer) > 0) and (LBuffer[Length(LBuffer)] = chr(10)) and Assigned(FOnTextReceived) then
              begin
                FOnTextReceived(Self, Lbuffer, Fname);
                LBuffer :=  '';
              end;
              Sleep(500);
            except
              LReset := True;
            end;
          end;
        end;
      end
      else
      begin
        if Assigned(FOnDisconnect) then  FOnDisconnect(Self, Fname);

      end;
    end;
  except
    if Assigned(FOnDisconnect) then  FOnDisconnect(Self, Fname);
  end;
end;

procedure TReadThread.SetOnTextReceived(const Value: TTextEvent);
begin
  FOnTextReceived := Value;
end;

procedure TReadThread.SetOnDisconnect(const Value: TDisconnectEvent);
begin
  FOnDisconnect := Value;
end;

end.
