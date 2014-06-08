@echo off
copy src\buddy\tests\index.html bin >nul
copy src\buddy\tests\buddy.phantomjs.js bin >nul
d:\program\misc\phantomjs\phantomjs bin\buddy.phantomjs.js
pause
