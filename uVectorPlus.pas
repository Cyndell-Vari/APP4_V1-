unit uVectorPlus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TArregloEnteros = array of Integer;

  { TVectorPlus }
  TVectorPlus = class
  private
    FDatos: TArregloEnteros;
    FCantidad: Integer;
    FCorte: Integer;
    function GetElemento(I: Integer): Integer;
    procedure SetElemento(I: Integer; AValor: Integer);
  public
    constructor Create(ACorte: Integer = 0);
    destructor Destroy; override;

    procedure Agregar(AValor: Integer);
    procedure Limpiar;
    procedure CargarDesdeTexto(const ATexto: string);
    function ComoTexto: string;
    // 1. Cantidad de cortes de control
    function CantidadCortes: Integer;
    // 2. Cantidad de elementos entre cortes de control (uno por grupo)
    function ElementosEntreCortes: TArregloEnteros;
    // 3. Dividir un vector en dos (par e impar)
    procedure DividirParImpar(APares, AImpares: TVectorPlus;
      APorPosicion: Boolean = False);
    // 4. Intercalar dos vectores (un elemento de A y uno de B)
    procedure Intercalar(A, B: TVectorPlus);
    // 5. Purgar los elementos usando cortes de control
    procedure Purgar;

    property Cantidad: Integer read FCantidad;
    property Corte: Integer read FCorte write FCorte;
    property Elementos[I: Integer]: Integer read GetElemento write SetElemento; default;
  end;

implementation

{ TVectorPlus }

constructor TVectorPlus.Create(ACorte: Integer);
begin
  inherited Create;
  FCorte := ACorte;
  FCantidad := 0;
  SetLength(FDatos, 0);
end;

destructor TVectorPlus.Destroy;
begin
  SetLength(FDatos, 0);
  inherited Destroy;
end;

function TVectorPlus.GetElemento(I: Integer): Integer;
begin
  if (I < 0) or (I >= FCantidad) then
    raise ERangeError.CreateFmt('Indice %d fuera de rango (0..%d)', [I, FCantidad - 1]);
  Result := FDatos[I];
end;

procedure TVectorPlus.SetElemento(I: Integer; AValor: Integer);
begin
  if (I < 0) or (I >= FCantidad) then
    raise ERangeError.CreateFmt('Indice %d fuera de rango (0..%d)', [I, FCantidad - 1]);
  FDatos[I] := AValor;
end;

procedure TVectorPlus.Agregar(AValor: Integer);
begin
  if FCantidad = Length(FDatos) then
    SetLength(FDatos, FCantidad + 8);
  FDatos[FCantidad] := AValor;
  Inc(FCantidad);
end;

procedure TVectorPlus.Limpiar;
begin
  FCantidad := 0;
  SetLength(FDatos, 0);
end;
procedure TVectorPlus.CargarDesdeTexto(const ATexto: string);
var
  Lista: TStringList;
  T: string;
  I: Integer;
begin
  Limpiar;
  T := StringReplace(ATexto, ',', ' ', [rfReplaceAll]);
  T := StringReplace(T, ';', ' ', [rfReplaceAll]);
  Lista := TStringList.Create;
  try
    Lista.Delimiter := ' ';
    Lista.StrictDelimiter := True;
    Lista.DelimitedText := Trim(T);
    for I := 0 to Lista.Count - 1 do
      if Trim(Lista[I]) <> '' then
        Agregar(StrToInt(Trim(Lista[I])));
  finally
    Lista.Free;
  end;
end;

function TVectorPlus.ComoTexto: string;
var
  I: Integer;
begin
  Result := '[';
  for I := 0 to FCantidad - 1 do
  begin
    if I > 0 then
      Result := Result + ', ';
    Result := Result + IntToStr(FDatos[I]);
  end;
  Result := Result + ']';
end;

{ 1. Cuenta cuantas veces aparece el valor de corte. }
function TVectorPlus.CantidadCortes: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FCantidad - 1 do
    if FDatos[I] = FCorte then
      Inc(Result);
end;

{ 2. Devuelve la cantidad de elementos de cada grupo delimitado por
  cortes. Un grupo vacio ubicado ENTRE dos cortes se informa como 0;
  un grupo vacio al inicio o al final del vector no se informa. }
function TVectorPlus.ElementosEntreCortes: TArregloEnteros;
var
  I, Actual, N: Integer;
  VistoCorte: Boolean;

  procedure Anotar(AValor: Integer);
  begin
    SetLength(Result, N + 1);
    Result[N] := AValor;
    Inc(N);
  end;

begin
  SetLength(Result, 0);
  N := 0;
  Actual := 0;
  VistoCorte := False;
  for I := 0 to FCantidad - 1 do
    if FDatos[I] = FCorte then
    begin
      if VistoCorte or (Actual > 0) then
        Anotar(Actual);
      Actual := 0;
      VistoCorte := True;
    end
    else
      Inc(Actual);
  if Actual > 0 then
    Anotar(Actual);
end;

{ 3. Divide el vector en dos.
  APorPosicion = False -> segun el VALOR  (pares / impares)
  APorPosicion = True  -> segun la POSICION (1ra, 3ra, ... / 2da, 4ta, ...)
  En ambos casos se conserva el orden original. }
procedure TVectorPlus.DividirParImpar(APares, AImpares: TVectorPlus;
  APorPosicion: Boolean);
var
  I: Integer;
  EsPar: Boolean;
begin
  APares.Limpiar;
  AImpares.Limpiar;
  for I := 0 to FCantidad - 1 do
  begin
    if APorPosicion then
      EsPar := (I + 1) mod 2 = 0        // posicion 2, 4, 6 ... (base 1)
    else
      EsPar := FDatos[I] mod 2 = 0;     // valor par
    if EsPar then
      APares.Agregar(FDatos[I])
    else
      AImpares.Agregar(FDatos[I]);
  end;
end;

{ 4. Self = A1, B1, A2, B2, ... Si un vector es mas largo, sus
  elementos sobrantes se agregan al final. }
procedure TVectorPlus.Intercalar(A, B: TVectorPlus);
var
  I, Mayor: Integer;
begin
  Limpiar;
  if A.Cantidad > B.Cantidad then
    Mayor := A.Cantidad
  else
    Mayor := B.Cantidad;
  for I := 0 to Mayor - 1 do
  begin
    if I < A.Cantidad then
      Agregar(A[I]);
    if I < B.Cantidad then
      Agregar(B[I]);
  end;
end;

{ 5. Elimina del vector todos los cortes de control, compactando
  los elementos restantes (se conserva su orden). }
procedure TVectorPlus.Purgar;
var
  I, K: Integer;
begin
  K := 0;
  for I := 0 to FCantidad - 1 do
    if FDatos[I] <> FCorte then
    begin
      FDatos[K] := FDatos[I];
      Inc(K);
    end;
  FCantidad := K;
  SetLength(FDatos, K);
end;

end.
