Files here should be for purposes of demonstrating to users how to use the different tools.
(Files for automated tests should go in `spec/data`. Files for testing during development should go in `playspace`.)

To run the demos:
  1. `workbook_builder.rb demo_workbook_builder_config.rb`  (This will overwrite `demo_empty_workbook.xlsx`.)
  2.  `gh_progress_report.rb demo_report_generator_config.rb`
      * Add `--create` the first time to create the necessary output directories.
      * Add `--suppress` to suppress the calls to git (because this dummy data does not 
        have real GitHub accounts).


