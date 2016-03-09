# RIF-CS spatial coverage

## Representing points and rectangles on a map in RDA

A simple way of representing points and rectangles on a map in Research Data Australia (RDA) is to obtain GPS coordinates (ie. a WGS84 projection) of the point or rectangular-borders and represent them in ReDBox under dcmiPoint or iso19139dcmiBox in the Coverage tab when creating or editing a dataset.

You can obtain the WGS84 coordinates (given by east and north values) as follows.

- Use OpenStreetMap in the ReDBox Coverage tab; the coordinates pointed to with your mouse are shown at the bottom right (east first, then north).
- Use http://www.openstreetmap.org:
  * navigate to the desired area
  * click the top Export button
  * click "Manually select a different area" in the left pane
  * select a rectangle in the map
  * the grey rectangle in the left pane will show the northlimit, southlimit, westlimit and eastlimit (no need to click left Export button)

Once your dataset is published in ReDBox and harvested into RDA, you should see a map with your point or rectangle shown on the corresponding page.

### Point example in ReDBox

- __Type:__ DCMI Point notation
- __Value:__ east=138.5998; north=-34.9284; projection=WGS84

### Rectangle example in ReDBox

- __Type:__ DCMI Box notation (iso19139)
- __Value:__ northlimit=-34.9215; southlimit=-34.9353; westlimit=138.5872; eastlimit=138.6182; projection=WGS84

### References

- http://openstreetmapdata.com/info/projections
- http://www.openstreetmap.org

- http://guides.ands.org.au/rda-cpg/coverage
- http://guides.ands.org.au/rda-cpg/spatial
- http://services.ands.org.au/documentation/rifcs/1.6.1/vocabs/vocabularies.html#Spatial_Type
- http://dublincore.org/documents/dcmi-point/
- http://dublincore.org/documents/dcmi-box/

- http://www.pgc.umn.edu/tools/conversion
