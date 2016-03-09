# RIF-CS spatial coverage

## Representing points and rectangles on a map in RDA

A simple way of representing points and rectangles on a map in Research Data Australia (RDA) is to obtain GPS coordinates (ie. a WGS84 projection) of the point or rectangular-borders and represent them in ReDBox under dcmiPoint or iso19139dcmiBox in the Coverage tab when creating or editing a dataset.

You can obtain the WGS84 coordinates (given by east and north values) as follows. Note that __negative signs__ are important (to represent west and south) so must be used where applicable.

- Use OpenStreetMap in the ReDBox Coverage tab; the coordinates pointed to with your mouse are shown at the bottom right (east first, then north).
- Use http://www.openstreetmap.org:
  * navigate to the desired area
  * click the top Export button
  * click "Manually select a different area" in the left pane
  * select a rectangle in the map
  * the grey rectangle in the left pane will show the northlimit, southlimit, westlimit and eastlimit (no need to click left Export button)
- Use Google Maps as described by "Get the coordinates of a place" [here](https://support.google.com/maps/answer/18539?hl=en). Google Maps gives north first, then east.

Once your dataset is published in ReDBox and harvested into RDA, you should see a map with your point or rectangle shown on the corresponding page.

### Point example in ReDBox

- __Type:__ DCMI Point notation
- __Value:__ east=138.5998; north=-34.9284; projection=WGS84

### Rectangle example in ReDBox

- __Type:__ DCMI Box notation (iso19139)
- __Value:__ northlimit=-34.9215; southlimit=-34.9353; westlimit=138.5872; eastlimit=138.6182; projection=WGS84

### References

- OpenStreetMap: http://openstreetmapdata.com/info/projections
- OpenStreetMap: http://www.openstreetmap.org
- RIF-CS: http://guides.ands.org.au/rda-cpg/coverage
- RIF-CS: http://guides.ands.org.au/rda-cpg/spatial
- RIF-CS: http://services.ands.org.au/documentation/rifcs/1.6.1/vocabs/vocabularies.html#Spatial_Type
- DCMI point: http://dublincore.org/documents/dcmi-point/
- DCMI box: http://dublincore.org/documents/dcmi-box/
- Get coordinates from Google Maps: https://support.google.com/maps/answer/18539?hl=en

