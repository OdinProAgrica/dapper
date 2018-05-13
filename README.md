# hpcctools
Functions and macros that make HPCC easier and faster to code in. Currently broken down into transform tools for data transformation and string tools for standard string tidying. 

## Documentation
The package's github is available at: https://github.com/OdinProAgrica/hpcctools

This package is released under GNU GPLv3 Licence: https://www.gnu.org/licenses/gpl-3.0.en.html

## Installation
Copy the hpcctools folder into an ECL repository (or add the folder to your IDE's environment), you can then import the relevent modules.

**Do note that the standard nomenclature for importing the modules should be respected.** This is because each module references its own functions, requiring a known import name. Modules should always be imported as:

* TransformTools: tt
* StringTools: st

For example: 
IMPORT hpcctools.TransformTools as tt;

## Transform Tools

### Data Transformations
![](./docs/img/DataTransformations.PNG)

### Duplicates
![](./docs/img/DupsDedups.PNG)

### Column Transforms
![](./docs/img/Columns.PNG)

### Filters
![](./docs/img/Filters.PNG)

### Arrangement
![](./docs/img/Arrange.PNG)

### Outputs
![](./docs/img/Outputs.PNG)

### Summaries
![](./docs/img/Summaries.PNG)

## String Tools
![](./docs/img/StringTools.PNG)

### Regex Loop
![](./docs/img/RegexLoop.PNG)

## Issues, Bugs, Comments? 
Please use the package's github: https://github.com/OdinProAgrica/hpcctools

Any contributions are also welcome.