@echo off
copy src\buddy\tests\index.html bin >nul
copy src\buddy\tests\buddy.phantomjs.js bin >nul
cd bin
phantomjs buddy.phantomjs.js
cd ..
pause
