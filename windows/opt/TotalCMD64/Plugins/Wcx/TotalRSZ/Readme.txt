关于Total Resizer
Total Resizer (TotalRSZ)是一个Total Commander的Paker/unpacker插件。其主要功能是批量修改图形大小。
TotalRSZ利用ImageMagick来修改图形大小或者剪裁，支持多种图形格式。


安装：
在TotalCommander中打开TotalRSZ.zip可以自动安装该插件。另外，用户也可以手动安装TotalRSZ：把TotalRSZ.zip解压缩，
把得到的TotalRSZ.wcx放到Total Commander所在的目录，或者其他你觉得适合的地方。然后打开Total Commander，选择菜单：
	Configuration-->Options...-->Packer
	点击按钮"Configure packer Extension WCXs", 
	然后在出来的对话框中，在“All files with extension (ending with)"
	所对应的那个框中写入rsz，然后点击"New type"按钮。选择TotalRSZ.wcx。
	然后点击Ok，就算搞定了。


使用：
在TC里，选择一个或者多个图形文件，比如JPEG文件，按下"Alt+F5"。在压缩格式那里选rsz，
然后点击OK，然后在TotalRSZ的对话框中选择合适的参数。TotalRSZ将会按照这些参数，对原
图形进行缩放。新文件的路径则是当前TC的另外一个目录树所显示的路径。

TotalRSZ也可以对目录进行操作，如果选中目录的话，TotalRSZ会遍历其中所有的子目录。


一些说明： 
1。关于目标文件名，那个$(FileNameNoExt)是缺省填入的，代表源文件的文件名，你可以就用
这个缺省设置，也可以加上前后缀比如AAA$(FileNameNoExt)BBB等。但是$(FileNameNoExt)必须
存在，否则程序会提 示你文件名不正确。 

2。关于目标文件格式，你可以选择选项1，也就是和源文件格式相同。比如你是对目录操作，
如果目录中的文件格式有多种，如果选中这个选项的话，目标文件格式和源文件的分别相同。
你也可以选择选项2，也就是统一目标输出格式。 

3。关于目标图形大小，同样有两种选择：一是给定大小，二是给定百分比。不管是那种方式，
目标图形将保持源文件的宽、高比例。如果给定大小，比如像下图中的宽为500，高为400，
如果原图的比例正好是5:4，则会按照设定的大小缩放；如果原图不是5:4 的比例，则以在和
原图相同的宽、高比的前提下，取其中一边的设置，而所需的另一边小于设定的原则来确定最
终目标图形的大小。举例，如果原图的比例是1:1，则目标图形大小为400x400；如果原图比例
是5:3，则目标图形为500x300；如果原图比例 为3:4，则目标图形大小为300x400。


版权
Copyright (C) 2004-2012 W. Dong, taohe@hotmail.com
本软件可免费使用于任何用途。但请在文档中保留这段。 
对可能由于使用这个软件而造成的任何损伤，本作者将不负任何责任。 


鸣谢
GraphicsMagick的版权归GraphicsMagick Group. 关于GraphicsMagick的版权，
请阅读Copyright.txt。
