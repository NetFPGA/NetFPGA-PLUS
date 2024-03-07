RUnning "Generate Registers" from the Spreadsheet will produce a python script regs_gen.py

You may need to edit this to add the following two lines:
def create_mems_list():
    return []

Add them just before the line
def create_regs_list()

Then execute the script (% python regs_gen.py)
This generates three .v files.
Move them to the hdl directory

$ mv *.v ../hdl/

Now you should be able to run synthesis/sims
