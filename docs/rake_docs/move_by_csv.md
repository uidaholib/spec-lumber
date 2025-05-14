# move_by_csv

This task allows you to move a batch of files using a spreadsheet list.

It does not rename the files, just puts them into a new folder (a simple version of rename_by_csv).
This is handy for selecting some items out of a larger group for organization.

Using defaults:

- Create a CSV named "move.csv" with the column "filename" (the exact matching current filename, not including directory).
- Put your files into the "objects" folder.
- Put your "move.csv" into the root of this repository (i.e. same place as the Rakefile).
- Open terminal and type `rake move_by_csv`
- Items included in the "move.csv" will be copied and output in the new folder "moved/". (nothing will be deleted!)

The options can be changed by passing arguments with the rake command.

| option | description | default value |
| --- | --- | --- |
| csv_file | the filename of the CSV file used to move | "move.csv" |
| filename_current | the column name of the old filename | "filename" |
| input_dir | the name of the folder containing the files to be moved | "objects/" |
| output_dir | the name of the new folder to put the files | "moved/" |


The order follows [:csv_file,:filename_current,:input_dir,:output_dir].
For example, 

`rake move_by_csv["other_list.csv","old_name","raw_folder","new_folder"]`
