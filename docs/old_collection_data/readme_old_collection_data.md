# Old Collection Data

All collections migrated from CONTENTdm in Dec 2023. 
The original Harvester was built with logic based on CDM collections, using the json files in "_data/digcoll".
These were all updated to the [migrated metadata json](https://github.com/uidaholib/spec-lumber/commit/585165cb85a48f82074f0d8acf5bbd9a9fda4c87).

Unfortunately, the logic is a bit of a mess, and some of the old objectid's do not in fact match up correctly to the new ones...
So you may encounter issues!

Known issues:

- postcards collection objectid changed completely. The old structure did not have parent/child objects so doesn't match new collection metadata very well. The old collection "postcards.json" is in this folder so you can look up the old reference, and then use the title to look up it's new objectid in the current "_data/digcoll/postcards.json".
