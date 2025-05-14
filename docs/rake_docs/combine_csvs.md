# combine_csvs

`rake combine_csvs` allows you to read every CSV file in a directory, extract specified fields, and output in a combined CSV.
This is handy for collecting a few fields out of a bulk export of metadata or other spreadsheets.

Using defaults: 

- Put all your CSVs (they should be UTF-8 encoded) into a folder named "csvs".
- Open terminal and type `rake combine_csvs`
- The task will read all the CSVs, by default it will grab the fields "objectid", "title", and "cdmid". The combined data will be output as "combined.csv".

## Options

The options can be changed by passing arguments with the rake command.

| option | description | default value |
| --- | --- | --- |
| input_dir | the name of the folder containing all the CSVs | 'csvs' |
| field_list | semicolon separated list of field names to extract | 'objectid;title;cdmid' |
| output_csv | the filename for new CSV containing the combined data | 'combined.csv' |


The order follows [:input_dir,:field_list,:output_csv].
For example, 

`rake combine_csvs['example_folder','subjects;type;format;series','example.csv']`
