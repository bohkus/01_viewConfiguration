ECHO OFF

REM #DON'T USE THE -v (verbose) option for viewConfiguration.pl
sde_perl viewConfiguration.pl -L CRH1090921_R1C028  > viewConfiguration_tmp
SET /p VIEWCONGIGURATION= < viewConfiguration_tmp
del /F viewConfiguration_tmp

ECHO END OF SCRIPT
ECHO DO YOU WANT TO DELETE THE CME VIEW  ( %VIEWCONGIGURATION% ) 
ECHO IF SO, THEN TYPE YES AND ENTER
SET /P INPUT=
IF "%INPUT%"=="YES" cme rmview %VIEWCONGIGURATION%

