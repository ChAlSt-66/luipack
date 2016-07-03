unit HandlebarsScanner;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type

  THandlebarsToken = (
    tkEOF,
    tkContent,
    tkOpenPartial,
    tkOpenPartialBlock,
    tkOpenBlock,
    tkEndBlock,
    tkOpenRawBlock,
    tkCloseRawBlock,
    tkEndRawBlock,
    tkOpenBlockParams,
    tkCloseBlockParams,
    tkOpenSExpr,
    tkCloseSExpr,
    tkInverse,
    tkOpenInverse,
    tkOpenInverseChain,
    tkOpenUnescaped,
    tkCloseUnescaped,
    tkOpen,
    tkClose,
    tkComment,
    tkEquals,
    tkId,
    tkSep,
    tkBoolean,
    tkNumber,
    tkString,
    tkUndefined,
    tkNull,
    tkInvalid
  );

  //inspired by fpc jsonscanner

  { THandlebarsScanner }

  THandlebarsScanner = class
  private
     FSource : TStringList;
     FCurToken: THandlebarsToken;
     FCurTokenString: string;
     FCurLine: string;
     TokenStr: PChar;
     FCurRow: Integer;
     function FetchLine: Boolean;
     function GetCurColumn: Integer;
     procedure ScanContent;
   protected
     procedure Error(const Msg: string);overload;
     procedure Error(const Msg: string; const Args: array of Const);overload;
   public
     constructor Create(Source : TStream); overload;
     constructor Create(const Source : String); overload;
     destructor Destroy; override;
     function FetchToken: THandlebarsToken;

     property CurLine: string read FCurLine;
     property CurRow: Integer read FCurRow;
     property CurColumn: Integer read GetCurColumn;

     property CurToken: THandlebarsToken read FCurToken;
     property CurTokenString: string read FCurTokenString;
   end;

implementation

{ THandlebarsScanner }

function THandlebarsScanner.FetchLine: Boolean;
begin
  Result := FCurRow < FSource.Count;
  if Result then
  begin
    FCurLine := FSource[FCurRow];
    TokenStr := PChar(FCurLine);
    Inc(FCurRow);
  end
  else
  begin
    FCurLine := '';
    TokenStr := nil;
  end;
end;

function THandlebarsScanner.GetCurColumn: Integer;
begin
  Result := TokenStr - PChar(CurLine);
end;

procedure THandlebarsScanner.ScanContent;
var
  TokenStart: PChar;
  SectionLength: Integer;
begin
  TokenStart := TokenStr;
  while True do
  begin
    Inc(TokenStr);
    SectionLength := TokenStr - TokenStart;
    if TokenStr[0] = #0 then
    begin
      if not FetchLine then
      begin
        SetLength(FCurTokenString, SectionLength);
        Move(TokenStart^, FCurTokenString[1], SectionLength);
        Break;
      end;
    end;
    if (TokenStr[0] = '{') and (TokenStr[1] = '{') then
    begin
      SetLength(FCurTokenString, SectionLength);
      Move(TokenStart^, FCurTokenString[1], SectionLength);
      Break;
    end;
  end;
end;

procedure THandlebarsScanner.Error(const Msg: string);
begin

end;

procedure THandlebarsScanner.Error(const Msg: string; const Args: array of const);
begin

end;

constructor THandlebarsScanner.Create(Source: TStream);
begin
  FSource := TStringList.Create;
  FSource.LoadFromStream(Source);
end;

constructor THandlebarsScanner.Create(const Source: String);
begin
  FSource := TStringList.Create;
  FSource.Text := Source;
end;

destructor THandlebarsScanner.Destroy;
begin
  FSource.Destroy;
  inherited Destroy;
end;

function THandlebarsScanner.FetchToken: THandlebarsToken;
begin
  if (TokenStr = nil) and not FetchLine then
  begin
    Result := tkEOF;
    FCurToken := Result;
    Exit;
  end;

  FCurTokenString := '';

  case TokenStr[0] of
    #0:         // Empty line
      begin
        FetchLine;
        //Result := tkWhitespace;
      end;
    '{':
      begin
        //{{
        if TokenStr[1] = '{' then
        begin
          Inc(TokenStr, 2);
          case TokenStr[0] of
            '>': Result := tkOpenPartial;
            '#': Result := tkOpenBlock;
          else
            Result := tkOpen;
          end;
          if Result <> tkOpen then
            Inc(TokenStr);
        end
        else
        begin
          Result := tkContent;
          ScanContent;
        end;
      end;
  else
    Result := tkContent;
    ScanContent;
  end;

  FCurToken := Result;
end;

end.

