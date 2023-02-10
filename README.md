Poprawa (Polish for "improvement") is a Ruby library for generating progress reports from 
Excel-based gradebooks. It is designed for instructors who use mastery-based grading (or other
forms of alternative grading) and find that their LMS's gradebook doesn't meet their needs. ()

The idea is that this code can serve as a starting point for writing your own progress reports. But, 
if you don't mind using our conventions to format your spreadsheet and progress report, you can 
use this code "out of the box".



Note: Some automated tests need to push generated reports to a GitHub repo. We didn't want those
test reports pushed to this repo, because it would severely clutter the repo's commit logs.
So, each user that wants to run tests that push to github must 
1. Choose/Create a separate repo to which she has write permissions
2. Place that repo in `spec/output/poprawa-github-tests` 
   * You can specify the desired directory name when cloning a repo:  `git clone repo_url poprawa-github-tests`