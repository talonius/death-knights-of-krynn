@ECHO OFF
REM Death Knights of Krynn v1.1 -- THE BUILD.
REM
REM Runs under DOS. TASM, TPC and Microsoft's EXEPACK write every byte of the
REM two files SSI shipped, and they are left under their shipped names:
REM START.EXE (linked as FIXMAIN.EXE, then packed) and GAME.OVR (written as
REM FIXMAIN.OVR, then renamed). FIXMAIN.EXE and FIXMAIN.MAP stay beside them.
REM Compiler and assembler outputs go to E:\OBJ. TPC reads the compiler
REM settings in E:\SRC\TPC.CFG from its working directory.
REM
REM build.sh mounts the drives, clears E:\OBJ and reads the logs:
REM     C:  drive_c                        E:  this repository
REM     D:  TPC.EXE and TURBO.TPL          F:  TASM      G:  EXEPACK
E:
CD \SRC
PATH D:\

REM Assemble the source leaves linked by Pascal units through {$L}.
REM Keep this list in step with src/*.asm.
F:\TASM BLIT,..\OBJ\BLIT          > E:\BUILD\LOGS\TASM.OUT
F:\TASM JOYSTICK,..\OBJ\JOYSTICK >> E:\BUILD\LOGS\TASM.OUT
F:\TASM SOUNDDRV,..\OBJ\SOUNDDRV       >> E:\BUILD\LOGS\TASM.OUT
F:\TASM TEXTREND,..\OBJ\TEXTREND >> E:\BUILD\LOGS\TASM.OUT

REM Precompile these dependencies before FIXMAIN to avoid TPC's
REM nested-source limit. After the clean purge, /M builds remaining units.
REM /E sets the output directory; /O sets the linked-object search directory.
REM GDConsts and GDVars hold DGROUP's storage.
REM Compile in this dependency order to avoid TPC's nested-source limit.
REM Recheck the uses graph and byte gate before changing the order.
TPC GDCONSTS.PAS /M /E..\OBJ /O..\OBJ >> E:\BUILD\LOGS\TPC.OUT
TPC GDVARS.PAS /M /E..\OBJ /O..\OBJ >> E:\BUILD\LOGS\TPC.OUT
TPC FIXMAIN.PAS /M /E..\OBJ /O..\OBJ >> E:\BUILD\LOGS\TPC.OUT

REM TPC names the overlay after the root; SSI shipped it as GAME.OVR.
REN E:\OBJ\FIXMAIN.OVR GAME.OVR
G:\EXEPACK E:\OBJ\FIXMAIN.EXE E:\OBJ\START.EXE > E:\BUILD\LOGS\PACK.OUT
