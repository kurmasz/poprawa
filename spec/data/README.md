Notes on data files:

testWorkbook_noNil.xlsx: 
testWorkbook_nilItems:
    Deleting a row or cell in Excel does not necessarily remove the underlying object from the RubyXL object tree.
    Thus, if a user deletes a row from an Excel worksheet and then we iterate over the rows using RubyXL, an iteration
    of the loop may return a nil object.  Similarly, if a user deletes a grade from a worksheet, iterating over the cells
    may return a nil Cell, or a Cell with a nil value.

    testWorkbook_noNil.xlsx was created without deleting any rows or cells.
    testWorkbook_nilItems.xlsx was created by deleting rows and cells (and thus should generate nil items the code
    must navigate around).