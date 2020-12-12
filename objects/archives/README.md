# Archives Directory

This folder (and the Objects folder) are git ignored! 
Files should not be committed to the project or uploaded to GitHub.

- Put full resolution TIFF image files from scans in this directory, plus any other file type (pdf, jpg, png).
- Run the Rake task `rake generate_derivatives` to create access derivatives. The task will convert TIFF into jpg, and copy all other file types into "objects", then create small and thumb images for all image and PDF files. It will skip any file that has already been processed.
