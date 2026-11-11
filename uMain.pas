unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uVectorPlus;

type

  { TfrmMain }
  TfrmMain = class(TForm)
    gbDatos: TGroupBox;
    lblA: TLabel;
    lblB: TLabel;
    lblCorte: TLabel;
    edtA: TEdit;
    edtB: TEdit;
    edtCorte: TEdit;
    gbOperaciones: TGroupBox;
    btnCortes: TButton;
    btnEntreCortes: TButton;
    btnDividir: TButton;
    btnIntercalar: TButton;
    btnPurgar: TButton;
    btnLimpiar: TButton;
    rgDivision: TRadioGroup;
    lblResultados: TLabel;
    mmoResultados: TMemo;
    procedure btnCortesClick(Sender: TObject);
    procedure btnEntreCortesClick(Sender: TObject);
    procedure btnDividirClick(Sender: TObject);
    procedure btnIntercalarClick(Sender: TObject);
    procedure btnPurgarClick(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    // Lee el texto de un Edit y lo carga en el vector. False si hay error.
    function LeerVector(AEdit: TEdit; AVector: TVectorPlus;
      const ANombre: string): Boolean;
    function LeerCorte(out ACorte: Integer): Boolean;
    procedure Escribir(const ATexto: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  edtA.Text := '3 5 0 2 4 6 0 7 0';
  edtB.Text := '10 20 30 40 50';
  edtCorte.Text := '0';
  rgDivision.ItemIndex := 0;
  mmoResultados.Clear;
end;

procedure TfrmMain.Escribir(const ATexto: string);
begin
  mmoResultados.Lines.Add(ATexto);
end;

function TfrmMain.LeerCorte(out ACorte: Integer): Boolean;
begin
  Result := TryStrToInt(Trim(edtCorte.Text), ACorte);
  if not Result then
  begin
    ShowMessage('El valor del corte de control debe ser un numero entero.');
    edtCorte.SetFocus;
  end;
end;

function TfrmMain.LeerVector(AEdit: TEdit; AVector: TVectorPlus;
  const ANombre: string): Boolean;
begin
  Result := True;
  try
    AVector.CargarDesdeTexto(AEdit.Text);
  except
    on EConvertError do
    begin
      Result := False;
      ShowMessage('El vector ' + ANombre + ' solo debe tener numeros enteros ' +
        'separados por espacios o comas.');
      AEdit.SetFocus;
    end;
  end;
  if Result and (AVector.Cantidad = 0) then
  begin
    Result := False;
    ShowMessage('El vector ' + ANombre + ' esta vacio.');
    AEdit.SetFocus;
  end;
end;

{ 1. Cantidad de cortes de control }
procedure TfrmMain.btnCortesClick(Sender: TObject);
var
  V: TVectorPlus;
  C: Integer;
begin
  if not LeerCorte(C) then Exit;
  V := TVectorPlus.Create(C);
  try
    if not LeerVector(edtA, V, 'A') then Exit;
    Escribir('A = ' + V.ComoTexto);
    Escribir('Cantidad de cortes de control (' + IntToStr(C) + ') = ' +
      IntToStr(V.CantidadCortes));
    Escribir('');
  finally
    V.Free;
  end;
end;

{ 2. Cantidad de elementos entre cortes de control }
procedure TfrmMain.btnEntreCortesClick(Sender: TObject);
var
  V: TVectorPlus;
  C, I: Integer;
  E: TArregloEnteros;
begin
  if not LeerCorte(C) then Exit;
  V := TVectorPlus.Create(C);
  try
    if not LeerVector(edtA, V, 'A') then Exit;
    E := V.ElementosEntreCortes;
    Escribir('A = ' + V.ComoTexto);
    if Length(E) = 0 then
      Escribir('No hay elementos entre cortes de control.')
    else
      for I := 0 to High(E) do
        Escribir('  Grupo ' + IntToStr(I + 1) + ': ' + IntToStr(E[I]) +
          ' elemento(s)');
    Escribir('');
  finally
    V.Free;
  end;
end;

{ 3. Dividir un vector en dos (par e impar) }
procedure TfrmMain.btnDividirClick(Sender: TObject);
var
  V, P, I: TVectorPlus;
  C: Integer;
begin
  if not LeerCorte(C) then Exit;
  V := TVectorPlus.Create(C);
  P := TVectorPlus.Create(C);
  I := TVectorPlus.Create(C);
  try
    if not LeerVector(edtA, V, 'A') then Exit;
    V.DividirParImpar(P, I, rgDivision.ItemIndex = 1);
    Escribir('A = ' + V.ComoTexto);
    if rgDivision.ItemIndex = 1 then
      Escribir('Division por POSICION:')
    else
      Escribir('Division por VALOR:');
    Escribir('  Pares   = ' + P.ComoTexto);
    Escribir('  Impares = ' + I.ComoTexto);
    Escribir('');
  finally
    V.Free; P.Free; I.Free;
  end;
end;

{ 4. Intercalar dos vectores }
procedure TfrmMain.btnIntercalarClick(Sender: TObject);
var
  A, B, R: TVectorPlus;
  C: Integer;
begin
  if not LeerCorte(C) then Exit;
  A := TVectorPlus.Create(C);
  B := TVectorPlus.Create(C);
  R := TVectorPlus.Create(C);
  try
    if not LeerVector(edtA, A, 'A') then Exit;
    if not LeerVector(edtB, B, 'B') then Exit;
    R.Intercalar(A, B);
    Escribir('A = ' + A.ComoTexto);
    Escribir('B = ' + B.ComoTexto);
    Escribir('Intercalado = ' + R.ComoTexto);
    Escribir('');
  finally
    A.Free; B.Free; R.Free;
  end;
end;

{ 5. Purgar elementos usando cortes de control }
procedure TfrmMain.btnPurgarClick(Sender: TObject);
var
  V: TVectorPlus;
  C: Integer;
begin
  if not LeerCorte(C) then Exit;
  V := TVectorPlus.Create(C);
  try
    if not LeerVector(edtA, V, 'A') then Exit;
    Escribir('A (antes)   = ' + V.ComoTexto);
    V.Purgar;
    Escribir('A (purgado) = ' + V.ComoTexto);
    Escribir('');
  finally
    V.Free;
  end;
end;

procedure TfrmMain.btnLimpiarClick(Sender: TObject);
begin
  mmoResultados.Clear;
end;

end.
