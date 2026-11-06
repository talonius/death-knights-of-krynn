CODE SEGMENT BYTE PUBLIC 'CODE'
  ASSUME CS:CODE, DS:CODE
  PUBLIC InstallSoundTimer, UninstallSoundTimer, VoiceWriteA, VoiceWriteB, SetVoiceByte, DriverData
; ---- data region ----
  db 00Dh,000h,000h,030h
DriverData:
  db 000h,000h,0D2h,0F5h,0EEh,0ADh,0F4h,0E9h,0EDh,0E5h,0A0h,0A0h,0C5h,0F2h,0F2h,0EFh
  db 0F2h,0A0h,0B2h,0B0h,0B9h,0A0h,0E1h,0F4h,0A0h,0B0h,0C2h,0C1h,0C4h,0BAh,0B0h,0B0h
  db 0B3h,0B8h,08Ah,08Dh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,001h,000h,000h,000h,002h,000h,003h,004h,000h,006h,008h,000h,00Ch,010h
  db 000h,018h,020h,000h,030h,040h,066h,015h,0C4h,015h,0CBh,015h,05Dh,015h,046h,015h
  db 097h,015h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,084h,08Eh,084h,086h,0F7h,07Eh,0D7h,077h,04Fh,071h,0C4h,06Ah,0C6h,064h
  db 01Eh,05Fh,0C7h,059h,0BDh,054h,0FCh,04Fh,07Eh,04Bh,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0C0h,0FFh,040h,0F1h
  db 0C0h,0E3h,000h,0D7h,040h,0CBh,080h,0BFh,0C0h,0B4h,080h,0AAh,000h,0A1h,000h,098h
  db 080h,08Fh,040h,087h,043h,00Ch,043h,00Ch,043h,00Ch,043h,00Ch,04Bh,00Ch,043h,00Ch
  db 043h,00Ch,043h,00Ch,043h,00Bh,043h,00Ch,043h,00Ch,043h,00Ch,0B3h,00Bh,043h,00Ch
  db 043h,00Ch,043h,00Ch,0DBh,00Bh,043h,00Ch,043h,00Ch,043h,00Ch,07Bh,00Bh,043h,00Ch
  db 043h,00Ch,043h,00Ch,013h,00Ch,043h,00Ch,043h,00Ch,043h,00Ch,01Bh,00Bh,043h,00Ch
  db 043h,00Ch,043h,00Ch,0D7h,00Ah,043h,00Ch,043h,00Ch,043h,00Ch,0F3h,00Ah,043h,00Ch
  db 043h,00Ch,043h,00Ch,0E7h,008h,043h,00Ch,043h,00Ch,043h,00Ch,093h,00Ch,043h,00Ch
  db 043h,00Ch,043h,00Ch,027h,009h,043h,00Ch,043h,00Ch,043h,00Ch,067h,009h,043h,00Ch
  db 043h,00Ch,043h,00Ch,06Fh,00Ah,043h,00Ch,043h,00Ch,043h,00Ch,097h,00Ah,043h,00Ch
  db 043h,00Ch,043h,00Ch,0E7h,009h,043h,00Ch,043h,00Ch,043h,00Ch,02Bh,00Ah,043h,00Ch
  db 043h,00Ch,043h,00Ch,0A7h,009h,043h,00Ch,043h,00Ch,043h,00Ch,097h,00Dh,043h,00Ch
  db 043h,00Ch,043h,00Ch,0BBh,00Ch,000h,000h,000h,000h,000h,000h,0D7h,010h,0D7h,010h
  db 0D7h,010h,0D7h,010h,0DFh,010h,00Bh,011h,037h,011h,0D7h,010h,0D7h,010h,0D7h,010h
  db 0D7h,010h,0BBh,010h,023h,010h,01Fh,010h,01Bh,010h,0D7h,010h,03Fh,010h,0D7h,010h
  db 083h,010h,09Bh,010h,0F3h,00Fh,0D7h,010h,0D7h,010h,0D7h,010h,0D7h,010h,0D7h,010h
  db 0CBh,00Fh,0DBh,00Fh,09Fh,00Fh,09Bh,00Fh,0D7h,010h,0D7h,010h,0D7h,010h,0D7h,010h
  db 0D7h,010h,063h,00Fh,0D7h,010h,0D7h,010h,0D7h,010h,083h,00Fh,0D7h,010h,0D7h,010h
  db 0AFh,00Dh,0C7h,00Dh,063h,011h,07Bh,011h,093h,011h,0D7h,010h,0D7h,010h,0D7h,010h
  db 0E7h,00Dh,0FFh,00Dh,047h,00Eh,0D7h,010h,01Fh,00Eh,02Fh,00Eh,0D7h,010h,0D7h,010h
  db 00Bh,00Fh,017h,00Fh,0D7h,010h,0D7h,010h,02Bh,00Fh,043h,00Fh,0D7h,010h,0D7h,010h
  db 0A7h,00Eh,0B3h,00Eh,0D7h,010h,0D7h,010h,0D7h,00Eh,0D7h,010h,08Bh,00Eh,0D7h,010h
  db 063h,00Eh,073h,00Eh,074h,012h,0D7h,010h,0D7h,010h,0D7h,010h,0ABh,011h,0D7h,010h
  db 0D7h,010h,0D7h,010h,000h,003h,006h,009h,00Ch,00Fh,012h,015h,018h,01Bh,01Eh,021h
  db 024h,027h,02Ah,02Dh,030h,033h,036h,039h,03Bh,03Eh,041h,043h,046h,049h,04Bh,04Eh
  db 050h,052h,055h,057h,059h,05Bh,05Eh,060h,062h,064h,066h,067h,069h,06Bh,06Ch,06Eh
  db 070h,071h,072h,074h,075h,076h,077h,078h,079h,07Ah,07Bh,07Bh,07Ch,07Dh,07Dh,07Eh
  db 07Eh,07Eh,07Eh,07Eh,07Eh,07Eh,07Eh,07Eh,07Eh,07Eh,07Dh,07Dh,07Ch,07Bh,07Bh,07Ah
  db 079h,078h,077h,076h,075h,074h,072h,071h,070h,06Eh,06Ch,06Bh,069h,067h,066h,064h
  db 062h,060h,05Eh,05Bh,059h,057h,055h,052h,050h,04Eh,04Bh,049h,046h,043h,041h,03Eh
  db 03Bh,039h,036h,033h,030h,02Dh,02Ah,027h,024h,021h,01Eh,01Bh,018h,015h,012h,00Fh
  db 00Ch,009h,006h,003h,000h,0FDh,0FAh,0F7h,0F4h,0F1h,0EEh,0EBh,0E8h,0E5h,0E2h,0DFh
  db 0DCh,0D9h,0D6h,0D3h,0D0h,0CDh,0CAh,0C7h,0C5h,0C2h,0BFh,0BDh,0BAh,0B7h,0B5h,0B2h
  db 0B0h,0AEh,0ABh,0A9h,0A7h,0A5h,0A2h,0A0h,09Eh,09Ch,09Ah,099h,097h,095h,094h,092h
  db 090h,08Fh,08Eh,08Ch,08Bh,08Ah,089h,088h,087h,086h,085h,085h,084h,083h,083h,082h
  db 082h,082h,082h,082h,082h,082h,082h,082h,082h,082h,083h,083h,084h,085h,085h,086h
  db 087h,088h,089h,08Ah,08Bh,08Ch,08Eh,08Fh,090h,092h,094h,095h,097h,099h,09Ah,09Ch
  db 09Eh,0A0h,0A2h,0A5h,0A7h,0A9h,0ABh,0AEh,0B0h,0B2h,0B5h,0B7h,0BAh,0BDh,0BFh,0C2h
  db 0C5h,0C7h,0CAh,0CDh,0D0h,0D3h,0D6h,0D9h,0DCh,0DFh,0E2h,0E5h,0E8h,0EBh,0EEh,0F1h
  db 0F4h,0F7h,0FAh,0FDh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,000h,000h,000h,078h,078h,078h,078h,078h,078h,078h,078h,078h,078h,078h,078h
  db 078h,078h,078h,078h,029h,023h,0BEh,084h,0E1h,06Ch,0D6h,0AEh,052h,090h,049h,0F1h
  db 0F1h,0BBh,0E9h,0EBh,0B3h,0A6h,0DBh,03Ch,087h,00Ch,03Eh,099h,024h,05Eh,00Dh,01Ch
  db 006h,0B7h,047h,0DEh,0B3h,012h,04Dh,0C8h,043h,0BBh,08Bh,0A6h,01Fh,003h,05Ah,07Dh
  db 009h,038h,025h,01Fh,05Dh,0D4h,0CBh,0FCh,096h,0F5h,045h,03Bh,013h,00Dh,089h,00Ah
  db 01Ch,0DBh,0AEh,032h,020h,09Ah,050h,0EEh,040h,078h,036h,0FDh,012h,049h,032h,0F6h
  db 09Eh,07Dh,049h,0DCh,0ADh,04Fh,014h,0F2h,044h,040h,066h,0D0h,06Bh,0C4h,030h,0B7h
  db 032h,03Bh,0A1h,022h,0F6h,022h,091h,09Dh,0E1h,08Bh,01Fh,0DAh,0B0h,0CAh,099h,002h
  db 0B9h,072h,09Dh,049h,02Ch,080h,07Eh,0C5h,099h,0D5h,0E9h,080h,0B2h,0EAh,0C9h,0CCh
  db 053h,0BFh,067h,0D6h,0BFh,014h,0D6h,07Eh,02Dh,0DCh,08Eh,066h,083h,0EFh,057h,049h
  db 061h,0FFh,069h,08Fh,061h,0CDh,0D1h,01Eh,09Dh,09Ch,016h,072h,072h,0E6h,01Dh,0F0h
  db 084h,04Fh,04Ah,077h,002h,0D7h,0E8h,039h,02Ch,053h,0CBh,0C9h,012h,01Eh,033h,074h
  db 09Eh,00Ch,0F4h,0D5h,0D4h,09Fh,0D4h,0A4h,059h,07Eh,035h,0CFh,032h,022h,0F4h,0CCh
  db 0CFh,0D3h,090h,02Dh,048h,0D3h,08Fh,075h,0E6h,0D9h,01Dh,02Ah,0E5h,0C0h,0F7h,02Bh
  db 078h,081h,087h,044h,00Eh,05Fh,050h,000h,0D4h,061h,08Dh,0BEh,07Bh,005h,015h,007h
  db 03Bh,033h,082h,01Fh,018h,070h,092h,0DAh,064h,054h,0CEh,0B1h,085h,03Eh,069h,015h
  db 0F8h,046h,06Ah,004h,096h,073h,00Eh,0D9h,016h,02Fh,067h,068h,0D4h,0F7h,04Ah,04Ah
  db 0D0h,057h,068h,076h,0FAh,016h,0BBh,011h,0ADh,0AEh,024h,088h,079h,0FEh,052h,0DBh
  db 025h,043h,0E5h,03Ch,0F4h,045h,0D3h,0D8h,028h,0CEh,00Bh,0F5h,0C5h,060h,059h,03Dh
  db 097h,027h,08Ah,059h,076h,02Dh,0D0h,0C2h,0C9h,0CDh,068h,0D4h,049h,06Ah,079h,025h
  db 008h,061h,040h,014h,0B1h,03Bh,06Ah,0A5h,011h,028h,0C1h,08Ch,0D6h,0A9h,00Bh,087h
  db 097h,08Ch,02Fh,0F1h,015h,01Dh,09Ah,095h,0C1h,09Bh,0E1h,0C0h,07Eh,0E9h,0A8h,09Ah
  db 0A7h,086h,0C2h,0B5h,054h,0BFh,09Ah,0E7h,0D9h,023h,0D1h,055h,090h,038h,028h,0D1h
  db 0D9h,06Ch,0A1h,066h,05Eh,04Eh,0E1h,030h,09Ch,0FEh,0D9h,071h,09Fh,0E2h,0A5h,0E2h
  db 00Ch,09Bh,0B4h,047h,065h,038h,02Ah,046h,089h,0A9h,082h,079h,07Ah,076h,078h,0C2h
  db 063h,0B1h,026h,0DFh,0DAh,029h,06Dh,03Eh,062h,0E0h,096h,012h,034h,0BFh,039h,0A6h
  db 03Fh,089h,05Eh,0F1h,06Dh,00Eh,0E3h,06Ch,028h,0A1h,01Eh,020h,01Dh,0CBh,0C2h,003h
  db 03Fh,041h,007h,084h,00Fh,014h,005h,065h,01Bh,028h,061h,0C9h,0C5h,0E7h,02Ch,08Eh
  db 046h,036h,008h,0DCh,0F3h,0A8h,08Dh,0FEh,0BEh,0F2h,0EBh,071h,0FFh,0A0h,0D0h,03Bh
  db 075h,006h,08Ch,07Eh,087h,078h,073h,04Dh,0D0h,0BEh,082h,0BEh,0DBh,0C2h,046h,041h
  db 02Bh,08Ch,0FAh,030h,07Fh,070h,0F0h,0A7h,054h,086h,032h,095h,0AAh,05Bh,068h,013h
  db 00Bh,0E6h,0FCh,0F5h,0CAh,0BEh,07Dh,09Fh,089h,08Ah,041h,01Bh,0FDh,0B8h,04Fh,068h
  db 0F6h,072h,07Bh,014h,099h,0CDh,0D3h,00Dh,0F0h,044h,03Ah,0B4h,0A6h,066h,053h,033h
  db 00Bh,0CBh,0A1h,010h,0FFh,00Ah,003h,000h,0FFh,004h,030h,075h,0FFh,01Ch,0E7h,006h
  db 0FFh,024h,000h,020h,0FFh,022h,010h,027h,0FFh,020h,010h,000h,0FFh,000h,01Ch,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,00Ch,000h,0FFh,00Ah,003h,000h,0FFh,004h,004h,010h
  db 0FFh,022h,098h,008h,0FFh,006h,010h,000h,0FFh,000h,02Ch,001h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,004h,010h,027h,0FFh,01Ch,0E7h,006h
  db 0FFh,024h,000h,020h,0FFh,022h,028h,023h,0FFh,020h,010h,000h,0FFh,000h,019h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,002h,000h,0FFh,00Ah,003h,000h,0FFh,004h,088h,013h
  db 0FFh,022h,0A0h,00Fh,0FFh,006h,02Ch,001h,0FFh,000h,050h,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,004h,0B8h,00Bh,0FFh,01Ch,0E7h,006h
  db 0FFh,024h,000h,020h,0FFh,022h,04Ch,004h,0FFh,020h,010h,000h,0FFh,000h,002h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,001h,000h,0FFh,00Ah,003h,000h,0FFh,004h,034h,008h
  db 0FFh,022h,0F4h,001h,0FFh,006h,09Ch,0FFh,0FFh,000h,01Eh,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,004h,040h,01Fh,0FFh,01Ch,0E7h,006h
  db 0FFh,024h,000h,020h,0FFh,022h,04Ch,004h,0FFh,020h,010h,000h,0FFh,000h,002h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,001h,000h,0FFh,00Ah,003h,000h,0FFh,004h,0D4h,017h
  db 0FFh,022h,0F4h,001h,0FFh,006h,09Ch,0FFh,0FFh,000h,050h,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,01Ch,0E7h,006h,0FFh,024h,000h,020h
  db 0FFh,022h,0E8h,003h,0FFh,020h,010h,000h,0FFh,006h,0CEh,0FFh,0FFh,026h,004h,000h
  db 0FFh,004h,010h,027h,0FFh,000h,004h,000h,0FFh,004h,020h,04Eh,0FFh,00Ah,000h,000h
  db 0FFh,000h,004h,000h,0FFh,00Ah,003h,000h,0FFh,000h,004h,000h,0FEh,026h,003h,00Ah
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,01Ch,0E7h,006h
  db 0FFh,024h,000h,020h,0FFh,022h,0E8h,003h,0FFh,020h,010h,000h,0FFh,006h,0CEh,0FFh
  db 0FFh,026h,014h,000h,0FFh,004h,088h,013h,0FFh,000h,001h,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,001h,000h,0FFh,00Ah,003h,000h,0FFh,004h,030h,075h,0FFh,000h,001h,000h
  db 0FEh,026h,047h,00Ah,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,003h,000h
  db 0FFh,004h,010h,027h,0FFh,01Ch,0E7h,006h,0FFh,024h,000h,020h,0FFh,022h,0F4h,001h
  db 0FFh,020h,010h,000h,0FFh,006h,0CEh,0FFh,0FFh,000h,01Ch,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,004h,020h,04Eh,0FFh,01Ch,0E7h,006h
  db 0FFh,024h,000h,020h,0FFh,022h,010h,027h,0FFh,020h,010h,000h,0FFh,000h,005h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,001h,000h,0FFh,00Ah,003h,000h,0FFh,004h,034h,008h
  db 0FFh,022h,098h,008h,0FFh,006h,064h,000h,0FFh,000h,064h,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,004h,0A0h,00Fh,0FFh,000h,005h,000h
  db 0FFh,004h,0E8h,003h,0FFh,000h,004h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,00Ah,003h,000h,0FFh,004h,0B0h,036h,0FFh,006h,0C8h,000h,0FFh,01Ch,0E7h,006h
  db 0FFh,024h,000h,020h,0FFh,022h,070h,017h,0FFh,020h,07Bh,000h,0FFh,000h,008h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,004h,0B4h,03Fh
  db 0FFh,026h,01Eh,000h,0FFh,006h,03Ch,0FEh,0FFh,000h,00Ch,000h,0FFh,006h,077h,002h
  db 0FFh,000h,008h,000h,0FEh,026h,027h,00Bh,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,00Ah,003h,000h,0FFh,01Ch,0E7h,006h,0FFh,024h,000h,020h,0FFh,022h,040h,006h
  db 0FFh,020h,09Bh,001h,0FFh,004h,0CCh,010h,0FFh,006h,00Ah,000h,0FFh,000h,01Eh,000h
  db 0FFh,022h,084h,003h,0FFh,004h,014h,005h,0FFh,006h,050h,000h,0FFh,000h,005h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,026h,005h,000h
  db 0FFh,004h,038h,018h,0FFh,006h,000h,000h,0FFh,000h,006h,000h,0FFh,028h,00Ch,000h
  db 0FFh,006h,05Eh,0FCh,0FFh,000h,001h,000h,0FFh,006h,084h,003h,0FFh,000h,001h,000h
  db 0FEh,028h,093h,00Bh,0FEh,026h,087h,00Bh,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,00Ah,003h,000h,0FFh,004h,07Bh,019h,0FFh,026h,00Ah,000h,0FFh,006h,0D3h,0FFh
  db 0FFh,000h,014h,000h,0FFh,006h,0F4h,001h,0FFh,000h,001h,000h,0FEh,026h,0BFh,00Bh
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,01Ch,0E7h,006h
  db 0FFh,024h,000h,020h,0FFh,022h,010h,027h,0FFh,020h,010h,000h,0FFh,004h,0E0h,02Eh
  db 0FFh,026h,02Ch,000h,0FFh,006h,0F0h,0F1h,0FFh,000h,002h,000h,0FFh,006h,088h,00Eh
  db 0FFh,000h,002h,000h,0FEh,026h,0F7h,00Bh,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,00Ah,003h,000h,0FFh,01Ch,0E7h,006h,0FFh,024h,000h,020h,0FFh,022h,028h,00Ah
  db 0FFh,020h,010h,000h,0FFh,004h,070h,017h,0FFh,006h,060h,0FFh,0FFh,000h,01Eh,000h
  db 0FFh,006h,046h,000h,0FFh,000h,023h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,004h,088h,013h
  db 0FFh,01Ch,0C7h,005h,0FFh,024h,000h,010h,0FFh,022h,0F4h,001h,0FFh,020h,04Eh,000h
  db 0FFh,026h,028h,000h,0FFh,006h,000h,000h,0FFh,000h,002h,000h,0FFh,006h,0ADh,0FDh
  db 0FFh,000h,001h,000h,0FFh,006h,000h,000h,0FFh,000h,002h,000h,0FFh,006h,0F4h,001h
  db 0FFh,000h,001h,000h,0FEh,026h,067h,00Ch,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,00Ah,003h,000h,0FFh,01Ch,0C7h,005h,0FFh,024h,000h,010h,0FFh,022h,0E8h,003h
  db 0FFh,020h,000h,001h,0FFh,004h,0E4h,00Ch,0FFh,006h,0ECh,0FFh,0FFh,000h,01Eh,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FCh,0C2h,00Ch,0FFh,000h,000h,000h,0FDh
  db 030h,000h,0FFh,012h,0E8h,0FFh,0FFh,016h,04Fh,00Dh,0FFh,01Ch,0C7h,005h,0FFh,024h
  db 000h,010h,0FFh,022h,028h,000h,0FFh,020h,02Ch,001h,0FDh,060h,000h,0FFh,012h,0E8h
  db 0FFh,0FFh,010h,005h,000h,0FFh,016h,037h,00Dh,0FFh,01Ch,0C7h,005h,0FFh,024h,000h
  db 010h,0FFh,022h,014h,000h,0FFh,020h,078h,000h,0FDh,000h,000h,0FFh,012h,0E8h,0FFh
  db 0FFh,016h,067h,00Dh,0FFh,01Ch,0C7h,005h,0FFh,024h,000h,010h,0FFh,022h,078h,000h
  db 0FFh,020h,0E4h,000h,0FDh,090h,000h,0FFh,012h,0E8h,0FFh,0FFh,016h,07Fh,00Dh,0FFh
  db 01Ch,0C7h,005h,0FFh,024h,000h,010h,0FFh,022h,078h,000h,0FFh,020h,0E4h,000h,0FFh
  db 00Eh,001h,000h,0FBh,003h,000h,0FFh,0FFh,000h,000h,000h,000h,000h,000h,0FFh,0FFh
  db 000h,000h,000h,000h,000h,000h,0FFh,0FFh,000h,000h,000h,000h,003h,000h,0FFh,0FFh
  db 000h,000h,010h,000h,000h,000h,0FFh,0FFh,000h,000h,000h,000h,000h,000h,01Eh,000h
  db 000h,000h,000h,000h,003h,000h,0FFh,0FFh,000h,000h,008h,000h,000h,000h,0FFh,0FFh
  db 000h,000h,000h,000h,000h,000h,01Eh,000h,000h,000h,000h,000h,003h,000h,0FFh,0FFh
  db 000h,000h,014h,000h,000h,000h,0FFh,0FFh,000h,000h,000h,000h,000h,000h,01Eh,000h
  db 000h,000h,000h,000h,0FFh,00Ah,003h,000h,0FFh,004h,0A0h,00Fh,0FFh,006h,014h,000h
  db 0FFh,000h,010h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,004h,0B8h,00Bh
  db 0FFh,000h,01Ch,000h,0FFh,004h,080h,03Eh,0FFh,006h,0E7h,0FFh,0FFh,000h,090h,001h
  db 0FFh,000h,000h,000h,0FFh,004h,0C0h,001h,0FFh,00Ah,060h,0EAh,0FFh,000h,01Ch,000h
  db 0FFh,00Ah,050h,0C3h,0FFh,00Ch,09Ch,0FFh,0FFh,000h,090h,001h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,004h,0B8h,00Bh,0FFh,000h,012h,000h,0FFh,004h,080h,03Eh
  db 0FFh,006h,0E7h,0FFh,0FFh,000h,064h,000h,0FFh,000h,000h,000h,0FFh,004h,0C0h,001h
  db 0FFh,00Ah,060h,0EAh,0FFh,000h,012h,000h,0FFh,00Ah,050h,0C3h,0FFh,00Ch,09Ch,0FFh
  db 0FFh,000h,064h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,004h,028h,023h
  db 0FFh,006h,0E7h,0FFh,0FFh,000h,019h,000h,0FFh,000h,000h,000h,0FFh,004h,0C0h,001h
  db 0FFh,00Ah,0D8h,0D6h,0FFh,00Ch,09Ch,0FFh,0FFh,000h,019h,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,004h,0A0h,00Fh,0FFh,00Ah,040h,09Ch,0FFh,00Ch,09Ch,0FFh
  db 0FFh,006h,09Ch,0FFh,0FFh,000h,019h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,004h,010h,027h,0FFh,006h,0E7h,0FFh,0FFh,000h,037h,000h,0FFh,000h,000h,000h
  db 0FFh,004h,0C0h,001h,0FFh,00Ah,060h,0EAh,0FFh,00Ch,09Ch,0FFh,0FFh,000h,037h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,004h,058h,01Bh,0FBh,00Ah,028h,0A0h
  db 0FFh,00Ch,09Ch,0FFh,0FFh,006h,09Ch,0FFh,0FFh,000h,037h,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,004h,040h,01Fh,0FFh,000h,028h,000h,0FFh,000h,000h,000h
  db 0FFh,004h,0C0h,001h,0FFh,026h,004h,000h,0FFh,00Ah,0D8h,0D6h,0FFh,000h,005h,000h
  db 0FFh,00Ah,001h,000h,0FFh,000h,005h,000h,0FEh,026h,0BBh,00Eh,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,026h,014h,000h,0FFh,004h,070h,017h,0FFh,00Ah,050h,0C3h
  db 0FFh,000h,001h,000h,0FFh,004h,088h,013h,0FFh,00Ah,001h,000h,0FFh,000h,001h,000h
  db 0FFh,004h,030h,075h,0FFh,00Ah,050h,0C3h,0FFh,000h,001h,000h,0FEh,026h,0DBh,00Eh
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,004h,0A0h,00Fh,0FFh,000h,01Ch,000h
  db 0FFh,000h,000h,000h,0FFh,004h,0C0h,001h,0FFh,00Ah,050h,0C3h,0FFh,000h,01Ch,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,004h,010h,027h,0FFh,000h,005h,000h
  db 0FFh,004h,0A0h,00Fh,0FFh,006h,064h,000h,0FFh,000h,064h,000h,0FFh,000h,000h,000h
  db 0FFh,004h,0C0h,001h,0FFh,00Ah,060h,0EAh,0FFh,000h,005h,000h,0FFh,00Ah,050h,0C3h
  db 0FFh,00Ch,09Ch,0FFh,0FFh,000h,064h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,004h,000h,001h,0FFh,00Ah,030h,075h,0FFh,00Ch,0E8h,003h,0FFh,000h,014h,000h
  db 0FFh,00Ch,018h,0FCh,0FFh,000h,028h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,004h,080h,001h,0FFh,00Ah,060h,0EAh,0FFh,00Ch,054h,0F2h,0FFh,000h,010h,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,000h,004h,000h,0FFh,00Ah,060h,0EAh
  db 0FFh,00Ch,09Ch,0FFh,0FFh,004h,0E8h,0FDh,0FFh,026h,01Eh,000h,0FFh,006h,08Ah,0FDh
  db 0FFh,000h,00Ch,000h,0FFh,006h,076h,002h,0FFh,000h,008h,000h,0FEh,026h,0AFh,00Fh
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,004h,0D0h,007h,0FFh,006h,05Ah,000h
  db 0FFh,000h,014h,000h,0FFh,000h,000h,000h,0FFh,004h,0C0h,001h,0FFh,00Ah,060h,0EAh
  db 0FFh,00Ch,030h,0F8h,0FFh,000h,014h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,004h,0C2h,009h,0FFh,00Ah,030h,075h,0FFh,026h,00Ch,000h,0FFh,006h,0F7h,0FFh
  db 0FFh,000h,00Ch,000h,0FFh,006h,009h,000h,0FFh,000h,008h,000h,0FEh,026h,0FFh,00Fh
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,000h,014h,000h,0FFh,000h,014h,000h
  db 0FFh,004h,0E3h,098h,0FFh,00Ah,060h,0EAh,0FFh,00Ch,038h,0FFh,0FFh,006h,04Eh,0FFh
  db 0FFh,000h,0C8h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,010h,027h
  db 0FFh,00Ch,0F4h,001h,0FFh,004h,000h,0FAh,0FFh,006h,010h,0FFh,0FFh,000h,050h,000h
  db 0FFh,00Ch,000h,000h,0FFh,026h,02Ch,000h,0FFh,006h,050h,0FBh,0FFh,000h,002h,000h
  db 0FFh,006h,0D8h,004h,0FFh,000h,002h,000h,0FEh,026h,05Bh,010h,0FFh,00Ch,061h,0FEh
  db 0FFh,006h,03Ch,000h,0FFh,000h,078h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,004h,030h,011h,0FFh,006h,00Bh,000h,0FFh,000h,0BCh,000h,0FFh,006h,0F5h,0FFh
  db 0FFh,000h,0BCh,000h,0FFh,000h,000h,000h,0FFh,004h,0C0h,001h,0FFh,00Ah,0A8h,061h
  db 0FFh,00Ch,09Fh,000h,0FFh,000h,0BCh,000h,0FFh,00Ch,061h,0FFh,0FFh,000h,0BCh,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ch,060h,009h,0FFh,004h,000h,001h
  db 0FFh,000h,019h,000h,0FFh,00Ch,0A0h,0F6h,0FFh,000h,019h,000h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,060h,0EAh
  db 0FFh,00Ch,015h,0FFh,0FFh,004h,0E0h,01Fh,0FFh,026h,006h,000h,0FFh,006h,01Eh,000h
  db 0FFh,000h,010h,000h,0FFh,006h,0E2h,0FFh,0FFh,000h,010h,000h,0FEh,026h,0EFh,010h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,050h,0C3h,0FFh,00Ch,038h,0FFh
  db 0FFh,004h,010h,040h,0FFh,026h,00Ah,000h,0FFh,006h,042h,000h,0FFh,000h,008h,000h
  db 0FFh,006h,0BEh,0FFh,0FFh,000h,008h,000h,0FEh,026h,01Bh,011h,0FFh,00Ah,000h,000h
  db 0FFh,000h,000h,000h,0FFh,00Ah,0E8h,0FDh,0FFh,00Ch,0D4h,0FEh,0FFh,004h,0B0h,036h
  db 0FFh,026h,008h,000h,0FFh,006h,052h,000h,0FFh,000h,00Ch,000h,0FFh,006h,0B2h,0FFh
  db 0FFh,000h,00Ch,000h,0FEh,026h,047h,011h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,00Ah,060h,0EAh,0FFh,00Ch,050h,0FBh,0FFh,004h,0D0h,034h,0FFh,000h,01Eh,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FFh,00Ah,060h,0EAh,0FFh,00Ch,050h,0FBh
  db 0FFh,004h,020h,080h,0FFh,000h,01Eh,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h
  db 0FFh,00Ah,060h,0EAh,0FFh,00Ch,050h,0FBh,0FFh,004h,070h,017h,0FFh,000h,00Ah,000h
  db 0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,0FCh,0B2h,011h,0FFh,000h,000h,000h,0FDh
  db 030h,000h,0FFh,010h,00Ch,000h,0FFh,012h,0D3h,0FFh,0FFh,016h,034h,012h,0FFh,01Ch
  db 0C7h,005h,0FFh,024h,000h,010h,0FFh,022h,028h,000h,0FFh,020h,02Ch,001h,0FDh,060h
  db 000h,0FFh,010h,007h,000h,0FFh,012h,0D3h,0FFh,0FFh,016h,014h,012h,0FFh,01Ch,0C7h
  db 005h,0FFh,024h,000h,010h,0FFh,022h,016h,000h,0FFh,020h,078h,000h,0FDh,000h,000h
  db 0FFh,010h,007h,000h,0FFh,012h,0D3h,0FFh,0FFh,016h,054h,012h,0FFh,01Ch,0C7h,006h
  db 0FFh,024h,000h,002h,0FFh,022h,0C8h,000h,0FFh,020h,010h,000h,0FFh,00Eh,006h,000h
  db 0FBh,050h,0C3h,0FFh,0FFh,0C4h,009h,004h,000h,030h,0F8h,006h,000h,000h,000h,000h
  db 000h,080h,0BBh,0FFh,0FFh,0C0h,0E0h,006h,000h,000h,000h,0FFh,0FFh,000h,000h,000h
  db 000h,040h,09Ch,0FFh,0FFh,0C4h,009h,008h,000h,048h,0F4h,005h,000h,000h,000h,000h
  db 000h,0C8h,0AFh,0FFh,0FFh,060h,0F0h,00Bh,000h,000h,000h,0FFh,0FFh,000h,000h,000h
  db 000h,0A8h,0DEh,0FFh,0FFh,024h,0FAh,006h,000h,000h,000h,000h,000h,000h,000h,000h
  db 000h,080h,0BBh,0FFh,0FFh,0C0h,0E0h,006h,000h,000h,000h,0FFh,0FFh,000h,000h,000h
  db 000h,0FFh,004h,040h,01Fh,0FFh,00Ah,030h,075h,0FFh,006h,014h,000h,0FFh,00Ch,09Ch
  db 0FFh,0FFh,000h,010h,000h,0FFh,00Ah,000h,000h,0FFh,000h,000h,000h,000h,000h,000h
  db 000h
; ---- code region ----
InstallSoundTimer:
	push	ds
	push	es
	mov	ax,CODE
	mov	ds,ax
	mov	ax,3508h
	int	21h
	mov	word ptr cs:[1290h],bx
	mov	word ptr cs:[1292h],es
	push	ds
	mov	dx,CODE
	mov	ds,dx
	mov	dx,1302h
	mov	ax,2508h
	int	21h
	pop	ds
	mov	al,0B6h
	out	43h,al
	mov	ax,13B1h
	out	40h,al
	mov	al,ah
	out	40h,al
	pop	es
	pop	ds
	retf
UninstallSoundTimer:
	push	ds
	mov	ax,CODE
	mov	ds,ax
	push	ds
	mov	dx,word ptr cs:[1290h]
	mov	ax,word ptr cs:[1292h]
	mov	ds,ax
	mov	ax,2508h
	int	21h
	pop	ds
	mov	ax,0FFFFh
	out	40h,al
	mov	al,ah
	out	40h,al
	in	al,61h
	and	al,0FCh
	out	61h,al
	mov	al,9Fh
	out	0C0h,al
	mov	al,0BFh
	out	0C0h,al
	mov	al,0DFh
	out	0C0h,al
	mov	al,0FFh
	out	0C0h,al
	pop	ds
	retf
	sti
	push	ax
	push	bx
	push	dx
	push	ds
	push	si
	mov	ax,CODE
	mov	ds,ax
	cmp	word ptr ds:[0F3h],0
	je	L126A
	dec	word ptr ds:[0F3h]
	jne	L126A
	mov	ah,0Fh
	int	10h
	mov	ah,0
	int	10h
	mov	bl,7
	mov	ah,7Fh
	mov	cx,21h
	mov	bx,CODE
	mov	es,bx
	mov	bx,0F5h
L1242:
	mov	al,byte ptr es:[bx]
	and	al,ah
	mov	byte ptr es:[bx],al
	inc	bx
	loop	L1242
	mov	bl,7
	mov	ah,13h
	mov	al,1
	mov	bh,0
	mov	cx,21h
	xor	dx,dx
	mov	bp,CODE
	mov	es,bp
	mov	bp,0F5h
	int	10h
	mov	ah,4Ch
	mov	al,0FFh
	int	21h
L126A:
	cmp	byte ptr ds:[0F0h],0
	jne	L1281
	mov	byte ptr ds:[0F0h],1
	call	L12A0
	call	L1315
	mov	byte ptr ds:[0F0h],0
L1281:
	dec	byte ptr ds:[0EFh]
	jne	L1296
	mov	byte ptr ds:[0EFh],0Dh
	pop	si
	pop	ds
	pop	dx
	pop	bx
	pop	ax
	jmp	dword ptr cs:[1290h]
L1296:
	mov	al,20h
	out	20h,al
	pop	si
	pop	ds
	pop	dx
	pop	bx
	pop	ax
	iret
L12A0:
	mov	bx,word ptr ds:[117h]
	cmp	bx,0
	je	L130C
	mov	word ptr ds:[2DDh],0
	mov	byte ptr ds:[0F1h],4
	mov	si,2C5h
	mov	word ptr ds:[11Dh],si
	mov	si,145h
	mov	word ptr ds:[11Bh],si
L12C2:
	cmp	word ptr [si],0
	je	L12E0
	call	L13A3
	cmp	word ptr ds:[2DDh],0
	jne	L12E0
	cmp	word ptr [si+0Ah],0
	je	L12E0
	cmp	word ptr [si],0
	je	L12E0
	mov	word ptr ds:[2DDh],si
L12E0:
	add	si,30h
	dec	byte ptr ds:[0F1h]
	jne	L12C2
	mov	bl,byte ptr ds:[125h]
	cmp	bl,0
	je	L130C
	mov	bx,word ptr ds:[2DDh]
	cmp	bx,0
	je	L130C
	mov	si,bx
	mov	ax,word ptr [si+8]
	out	42h,al
	mov	al,ah
	out	42h,al
	mov	bx,word ptr [si+0Ah]
	and	bl,3
L130C:
	in	al,61h
	and	al,0FCh
	or	al,bl
	out	61h,al
	ret
L1315:
	mov	bx,word ptr ds:[117h]
	cmp	bx,0
	je	L1392
	mov	byte ptr ds:[0F1h],4
	mov	si,45Fh
	mov	word ptr ds:[11Dh],si
	mov	si,2DFh
	mov	word ptr ds:[11Bh],si
L1331:
	cmp	word ptr [si],0
	je	L1339
	call	L13A3
L1339:
	add	si,30h
	dec	byte ptr ds:[0F1h]
	jne	L1331
	mov	al,byte ptr ds:[125h]
	cmp	al,0
	je	L1392
	mov	byte ptr ds:[0F1h],4
	mov	si,2DFh
	mov	dl,80h
L1353:
	mov	ax,word ptr [si+8]
	shr	ax,1
	shr	ax,1
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	xor	al,dl
	out	0C0h,al
	cmp	dl,0E0h
	je	L136F
	mov	al,ah
	out	0C0h,al
L136F:
	mov	ax,0FFFFh
	sub	ax,word ptr [si+0Ah]
	shr	ah,1
	shr	ah,1
	shr	ah,1
	shr	ah,1
	mov	al,ah
	xor	al,dl
	add	al,10h
	out	0C0h,al
	add	dl,20h
	add	si,30h
	dec	byte ptr ds:[0F1h]
	jne	L1353
	ret
L1392:
	mov	al,9Fh
	out	0C0h,al
	mov	al,0BFh
	out	0C0h,al
	mov	al,0DFh
	out	0C0h,al
	mov	al,0FFh
	out	0C0h,al
	ret
L13A3:
	push	cx
	push	di
	mov	ax,word ptr [si+0Ch]
	add	word ptr [si+0Ah],ax
	mov	ax,word ptr [si+6]
	add	word ptr [si+4],ax
	sub	dx,dx
	mov	ax,word ptr [si+1Eh]
	add	ax,word ptr [si+20h]
	je	L13D6
	cmp	ax,word ptr [si+24h]
	jb	L13C3
	sub	ax,word ptr [si+24h]
L13C3:
	mov	word ptr [si+1Eh],ax
	mov	cl,4
	sar	ax,cl
	add	ax,word ptr [si+1Ch]
	mov	di,ax
	mov	ah,byte ptr [di]
	mov	al,0
	imul	word ptr [si+22h]
L13D6:
	add	dx,word ptr [si+4]
	mov	word ptr [si+8],dx
	cmp	word ptr [si+14h],0
	je	L13F1
	dec	word ptr [si+14h]
	jne	L13F1
	mov	word ptr [si+18h],10h
	mov	word ptr [si+1Ah],1
L13F1:
	dec	word ptr [si]
	jne	L13F8
	call	L1434
L13F8:
	cmp	word ptr [si+1Ah],0
	je	L1431
	dec	word ptr [si+1Ah]
	jne	L1431
L1403:
	mov	bx,word ptr [si+16h]
	add	bx,word ptr [si+18h]
	cmp	word ptr [bx+2],-1
	jne	L1422
	mov	ax,word ptr [bx]
	mov	word ptr [si+0Ah],ax
	cmp	ax,0
	jne	L141C
	mov	word ptr [si+0Ch],ax
L141C:
	add	word ptr [si+18h],4
	jmp	short L1403
L1422:
	mov	ax,word ptr [bx]
	mov	word ptr [si+0Ch],ax
	mov	ax,word ptr [bx+2]
	mov	word ptr [si+1Ah],ax
	add	word ptr [si+18h],4
L1431:
	pop	di
	pop	cx
	ret
L1434:
	mov	di,word ptr [si+2]
	cmp	di,0
	jne	L143D
	ret
L143D:
	mov	word ptr ds:[119h],si
L1441:
	mov	bl,byte ptr [di]
	inc	di
	cmp	bl,0FAh
	jae	L144C
	jmp	L14ED
L144C:
	sub	bh,bh
	sub	bl,0FAh
	add	bl,bl
	jmp	word ptr [bx+139h]
	mov	bl,byte ptr [di]
	inc	di
	mov	bh,0
	mov	ax,word ptr [di]
	add	di,2
	cmp	word ptr [bx+si],0
	je	L146A
	dec	word ptr [bx+si]
	je	L1441
L146A:
	mov	di,ax
	jmp	short L1441
	mov	si,word ptr [di]
	add	di,2
	add	si,word ptr ds:[11Bh]
	sub	bx,bx
	mov	word ptr [si+4],bx
	mov	word ptr [si+6],bx
	mov	word ptr [si+8],bx
	mov	word ptr [si+0Ah],bx
	mov	word ptr [si+0Ch],bx
	mov	word ptr [si+10h],bx
	mov	word ptr [si+12h],bx
	mov	word ptr [si+16h],bx
	mov	word ptr [si+18h],bx
	mov	word ptr [si+1Ah],bx
	mov	word ptr [si+1Ch],bx
	mov	word ptr [si+1Eh],bx
	mov	word ptr [si+20h],bx
	mov	word ptr [si+22h],bx
	mov	word ptr [si+24h],bx
	jmp	short L1441
	mov	bl,byte ptr [di]
	inc	di
	mov	bh,0
	mov	ax,word ptr [di]
	inc	di
	inc	di
	mov	word ptr [bx+si],ax
	cmp	bl,0
	jne	L1441
L14B8:
	mov	si,word ptr ds:[119h]
	cmp	word ptr [si],0
	jne	L14D1
	mov	bl,4
	sub	bl,byte ptr ds:[0F1h]
	sub	bh,bh
	mov	byte ptr [bx+121h],0
	mov	di,0
L14D1:
	mov	word ptr [si+2],di
	ret
	mov	di,word ptr ds:[11Fh]
	jmp	L1441
	mov	ax,word ptr [di]
	add	di,2
	mov	word ptr ds:[11Fh],di
	mov	di,ax
	jmp	L1441
L14EA:
	mov	bl,byte ptr [di]
	inc	di
L14ED:
	push	di
	mov	al,bl
	mov	cl,5
	shr	al,cl
	mov	cl,al
	mul	byte ptr ds:[0F2h]
	add	ax,word ptr ds:[11Bh]
	mov	di,ax
	pop	bx
	push	bx
	mov	ax,word ptr [si+0Eh]
	cmp	al,1
	ja	L1510
	xor	ah,ah
	mov	al,byte ptr [bx+1]
	jmp	short L1513
L1510:
	mul	byte ptr [bx+1]
L1513:
	mov	word ptr [si],ax
	mov	al,byte ptr [bx]
	and	ax,7Fh
	cmp	ax,7Fh
	je	L155D
	cmp	cl,0
	ja	L155D
	mov	cx,word ptr [si]
	mov	word ptr [di],cx
	mov	word ptr [di+14h],cx
	add	ax,word ptr [di+12h]
	mov	word ptr [di+18h],0
	mov	word ptr [di+1Ah],1
	mov	cx,0FFh
L153B:
	inc	cl
	sub	ax,0Ch
	jae	L153B
	add	ax,0Ch
	mov	bx,ax
	add	bx,bx
	cmp	di,36Fh
	jne	L154F
L154F:
	add	bx,word ptr ds:[11Dh]
	mov	ax,word ptr [bx]
	shr	ax,cl
	mov	word ptr [di+4],ax
	mov	word ptr [di+8],ax
L155D:
	pop	di
	mov	al,byte ptr [di]
	inc	di
	inc	di
	and	al,80h
	jne	L1568
	jmp	short L14EA
L1568:
	jmp	L14B8
VoiceWriteA:
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	di
	push	si
	push	ds
	mov	si,CODE
	mov	ds,si
	mov	si,word ptr [bp+6]
	mov	word ptr ds:[117h],si
	add	si,si
	add	si,si
	add	si,si
	mov	byte ptr ds:[0F0h],1
	mov	byte ptr ds:[0F1h],4
	mov	di,145h
L1592:
	mov	ax,word ptr [si+477h]
	cmp	ax,0
	je	L15BD
	mov	bx,2Eh
L159E:
	mov	word ptr [bx+di],0
	sub	bx,2
	jge	L159E
	mov	word ptr [di+2],ax
	mov	bl,4
	sub	bl,byte ptr ds:[0F1h]
	sub	bh,bh
	mov	ax,word ptr ds:[117h]
	mov	byte ptr [bx+121h],al
	mov	word ptr [di],1
L15BD:
	add	di,30h
	add	si,2
	dec	byte ptr ds:[0F1h]
	jne	L1592
	mov	byte ptr ds:[0F0h],0
	pop	ds
	pop	si
	pop	di
	pop	bx
	pop	ax
	pop	bp
	retf	2
VoiceWriteB:
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	di
	push	si
	push	ds
	mov	si,CODE
	mov	ds,si
	mov	si,word ptr [bp+6]
	mov	word ptr ds:[117h],si
	add	si,si
	add	si,si
	add	si,si
	mov	byte ptr ds:[0F0h],1
	mov	byte ptr ds:[0F1h],4
	mov	di,2DFh
L15FE:
	mov	ax,word ptr [si+51Fh]
	cmp	ax,0
	je	L1629
	mov	bx,2Eh
L160A:
	mov	word ptr [bx+di],0
	sub	bx,2
	jge	L160A
	mov	word ptr [di+2],ax
	mov	bl,4
	sub	bl,byte ptr ds:[0F1h]
	sub	bh,bh
	mov	ax,word ptr ds:[117h]
	mov	byte ptr [bx+121h],al
	mov	word ptr [di],1
L1629:
	add	di,30h
	add	si,2
	dec	byte ptr ds:[0F1h]
	jne	L15FE
	mov	byte ptr ds:[0F0h],0
	pop	ds
	pop	si
	pop	di
	pop	bx
	pop	ax
	pop	bp
	retf	2
SetVoiceByte:
	push	bp
	mov	bp,sp
	push	ax
	push	ds
	mov	ax,CODE
	mov	ds,ax
	mov	ax,word ptr [bp+6]
	mov	byte ptr ds:[125h],al
	pop	ds
	pop	ax
	pop	bp
	retf	2
; trailing alignment bytes -- not code
	db 0h,0h,0h,0h,0h,0h,0h,0h
CODE	ENDS
	END
