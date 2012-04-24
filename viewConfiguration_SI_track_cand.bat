@echo off

rem Label
SET THORIUM_LABEL=LUD_ICP_THORIUM_SI_R1C_120415_0109


rem ------------------------------------------------------------------------

SET SUFFIX=_cand

REM Make sure that the view is configured with the correct label
SET USED_CC_VIEW_NAME_WO_USERNAME=%COMPUTERNAME%_SI_track%SUFFIX%
SET USED_CC_VIEW=%USERNAME%_%USED_CC_VIEW_NAME_WO_USERNAME%

REM Perl script to generate CC view automatically
sde_perl viewConfiguration.pl -v -f -V %USED_CC_VIEW_NAME_WO_USERNAME% -L %THORIUM_LABEL% -X Modules_SI_Track_cand.txt -m

@echo on