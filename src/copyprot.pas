{ Journal-word copy protection: asks for a word from the journal by page, entry and word number, up to three times with
  a fresh question each time, and marks each stage in GDVars.protectionMarks for FixMain, which aborts unless the check
  passes and all four marks are set. }
{$O+}
unit CopyProt;

interface

{ Asks for a journal word, a fresh question after each wrong answer, at most three times.
  @returns(True when an answer matches its decoded table entry.) }
function CopyProtection: Boolean;

implementation

uses Border, CharHlp, TextRend, GDConsts, GDVars, Crt, Types;

const
  MAX_ATTEMPTS = 3;
  WORD_CIPHER_BIAS = 40;
  MAX_INPUT_LENGTH = 20;
  QUESTION_FRAME_MODE = 0;
  QUESTION_COLUMN = 3;
  WORD_NUMBER_COLUMN = 19;
  WORD_ROW = 2;
  ENTRY_ROW = 4;
  PAGE_ROW = 6;
  CHALLENGE_STARTED = 1;
  ANSWER_READ = 2;
  ATTEMPTS_FINISHED = 3;
  RESULT_ASSIGNED = 4;
  STAGE_COMPLETE = 1;

function CopyProtection: Boolean;

  { Entry wordIndex decoded: each letter is its byte plus 40 plus the word's length. }
  function Decode(wordIndex: Word): String;
  var
    wordLength: Byte;
    charIndex: Byte;
    decodedChar: Byte;
    decodedWord: String;
  begin
    decodedWord := '';
    wordLength := GDConsts.journalWords[wordIndex].wordLen;
    for charIndex := 1 to wordLength do begin
      decodedChar := GDConsts.journalWords[wordIndex].chars[charIndex] + CopyProt.WORD_CIPHER_BIAS + wordLength;
      decodedWord := decodedWord + Chr(decodedChar);
    end;
    Decode := decodedWord;
  end;

var
  { Unused in this version; see the other implementations of this routine. }
  inputChar: Byte;
  wordIndex: Byte;
  attemptCount: Byte;
  { Unused in this version; see the other implementations of this routine. }
  index: Byte;
  expectedWord: String;
  enteredWord: String;
begin
  FillChar(GDVars.protectionMarks, SizeOf(GDVars.protectionMarks), 0);
  Border.DrawWindowFrame(CopyProt.QUESTION_FRAME_MODE);
  attemptCount := 0;
  repeat
    Inc(attemptCount);
    expectedWord := '';
    GDVars.protectionMarks[CopyProt.CHALLENGE_STARTED] := CopyProt.STAGE_COMPLETE;
    wordIndex := Random(SizeOf(GDConsts.journalWords) div SizeOf(Types.TCodeRec) - 1) + 1;
    expectedWord := Decode(wordIndex);
    with GDConsts.journalWords[wordIndex] do begin
      TextRend.DisplayString(CopyProt.QUESTION_COLUMN, CopyProt.WORD_ROW, LightGreen, Black, GDConsts.promptWord);
      TextRend.DisplayString(CopyProt.WORD_NUMBER_COLUMN, CopyProt.WORD_ROW, LightGreen, Black,
                             CharHlp.ByteToString(wordNum) + '    ');
      TextRend.DisplayString(CopyProt.QUESTION_COLUMN, CopyProt.ENTRY_ROW, LightGreen, Black,
                             GDConsts.promptEntry + CharHlp.ByteToString(entryNum) + '     ');
      TextRend.DisplayString(CopyProt.QUESTION_COLUMN, CopyProt.PAGE_ROW, LightGreen, Black,
                             GDConsts.promptPage + CharHlp.ByteToString(pageNum) + ')?      ');
    end;
    enteredWord := TextRend.ReadString(GDConsts.enterAnswerPrompt, Yellow, Black, CopyProt.MAX_INPUT_LENGTH);
    GDVars.protectionMarks[CopyProt.ANSWER_READ] := CopyProt.STAGE_COMPLETE;
  until (attemptCount = CopyProt.MAX_ATTEMPTS) or (enteredWord = expectedWord);
  GDVars.protectionMarks[CopyProt.ATTEMPTS_FINISHED] := CopyProt.STAGE_COMPLETE;
  if enteredWord = expectedWord then
    CopyProtection := True
  else
    CopyProtection := False;
  GDVars.protectionMarks[CopyProt.RESULT_ASSIGNED] := CopyProt.STAGE_COMPLETE;
end;

begin
end.
