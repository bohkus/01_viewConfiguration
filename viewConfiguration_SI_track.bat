@echo off

rem Label
SET THORIUM_LABEL=CRH1090921_R1C037


rem ------------------------------------------------------------------------

SET SUFFIX=

REM Make sure that the view is configured with the correct label
SET USED_CC_VIEW_NAME_WO_USERNAME=%COMPUTERNAME%_SI_track%SUFFIX%
SET USED_CC_VIEW=%USERNAME%_%USED_CC_VIEW_NAME_WO_USERNAME%

REM Perl script to generate CC view automatically
sde_perl viewConfiguration.pl -v -f -V %USED_CC_VIEW_NAME_WO_USERNAME% -L %THORIUM_LABEL% -X Modules_SI_Track.txt -m


@echo on