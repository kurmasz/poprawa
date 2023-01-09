Poprawa (Polish for "improvement") is a Ruby library for generating progress reports from 
Excel-based gradebooks.  

The idea is that this code can serve as a starting point for writing your own progress reports.  
But, if you don't mind using our conventions to format your spreadsheet and progress report, you can 
use this code "out of the box".



Note: The automated tests make use of a submodule (https://github.com/kurmasz/poprawa_test).  If you plan to run the automated tests, you'll need to run these two commands after cloning the repository:
* `git submodule init`
* `git submodule update`

One of the programs in this repo writes progress reports to a git repo than updates that repo. In order to 
avoid a lot of "noise" in our commit history, we created a submodule for testing the git aspects of the project.