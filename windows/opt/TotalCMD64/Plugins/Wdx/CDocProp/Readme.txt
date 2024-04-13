-------------------------------------------------------------------------------
  CDocProp 
-------------------------------------------------------------------------------
CDocProp is the content plugin for properties of Compound Documents (like old MS
Office documents)
Plugin allows to add to the TC custom view standard and custom document properties.
Custom properties should be confugured in the CDocProp.ini file in the section 
[Config], i.e.

[Config]
Title=PropertyName

where "Title" is the string to display in TC header and "PropertyName" is the 
property name in the file.
File CDocProp.ini should be in the same directory where CDocProp.wdx file.

-------------------------------------------------------------------------------    
  Changes History                                                                  
-------------------------------------------------------------------------------
Version 1.10
- Added 64-bit version

Version 1.9
- Fixed bug in custom fields editing when field content in non-default encoding.
- Added key CreateNewProps in CDocProp.ini. If CreateNewProps = 1 and the user 
tries to edit the missing property, this property will be added to the document 
automatically.
   
Version 1.7
- Added Unicode support (for TC 7.5 only)
- Added field editing for all custom and the following list of standard properties
  Title
	Subject
	Author
	Keywords
	Comments
	Template
	AppName
	Category
	Target
	Manager
	Company

Version 1.2
- Added fields for Document summary properties.

Version 1.1
- Plugin shows fields for Basic summary properties.
- Plugin shows fields for custom properties.


-------------------------------------------------------------------------------
Autor: MGP Software Ltd.
Email: support@mgpsoft.com