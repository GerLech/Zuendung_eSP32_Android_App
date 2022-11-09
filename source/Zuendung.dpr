program Zuendung;

uses
  System.StartUpCopy,
  FMX.Forms,
  Zuendung_ESP32 in 'Zuendung_ESP32.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
