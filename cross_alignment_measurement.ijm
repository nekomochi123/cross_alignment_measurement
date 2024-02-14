
function main(){
	j = 0;
	//測定結果を保存用のROiを起動
	run("ROI Manager...");
	//結果格納用plot起動
	Plot.create("AllResults", "distancePixels", "Y0");
	
	run("Set Measurements...", "area mean min center display redirect=None decimal=3");
	//
	ImageDir = getDirectory("choose a images directory:");		
	FileList = getFileList(ImageDir);	
	for(i=0; i<FileList.length; i++){
		open(ImageDir+FileList[i]);
		//画像を45度回転、画像の複製、2値化
		ConvertImage();		
		PlotPoints();
		PlotLines(i, j, FileList);
		j = j + 2;
	}
	close("Roi Manager");
	ResultsName(FileList);
	AllResults = ResultsCalculation(FileList);
	close("*");
	run("Clear Results");
	AllResultsCalculation(FileList, AllResults)
}

function ConvertImage(){
	//45度回転処理
	RotateImage();
	//縦横を測定するための画像の複製
	DuplicatedImage = DuplicateImage();
	//2値化処理
	MaskImage();
}

function RotateImage(){
	run("Rotate... ", "angle=45 grid=1 interpolation=Bilinear");
}

function DuplicateImage(){
	run("Duplicate...", " ");
	return getTitle;
}

function MaskImage(){
	run("Convert to Mask", "");
	run("Invert", "");
}

function PlotPoints(){
	HeightPlotPoints();
	WidthPlotPoint();
	run("Clear Results");
}

function HeightPlotPoints(){
	run("Analyze Particles...", "size=5000.00-10000.00 show=Nothing display exclude composite");	
	xLineStart = getResult("XM",0) - 250;
	yLineStart = getResult("YM",0) - 15;
	xLineEnd = 500;
	yLineEnd = 30;
	makeRectangle(xLineStart, yLineStart, xLineEnd, yLineEnd);
	roiManager("Add");
	run("Select None");
}
function WidthPlotPoint(){
	run("Rotate... ", "angle=90 grid=1 interpolation=Bilinear");
	run("Analyze Particles...", "size=5000.00-10000.00 show=Nothing display exclude composite");
	xLineStart = getResult("XM",1) - 250;
	yLineStart = getResult("YM",1) - 15;
	xLineEnd = 500;
	yLineEnd = 30;
	makeRectangle(xLineStart, yLineStart, xLineEnd, yLineEnd);
	roiManager("Add");
	run("Select None");
	close();
}

function PlotLines(i, j, FileList){
	FileListName = split(FileList[i], ".");
	FileListDup = FileListName[0] + "-1";
	PlotFileListName = "Plot of " + FileListName[0];
	PlotFileListDup = "Plot of " + FileListDup;
	roiManager("select", j);
	run("Plot Profile");
	selectWindow(FileList[i]);
	run("Select None");
	run("Duplicate...", "ignore");
	run("Rotate... ", "angle=90 grid=1 interpolation=Bilinear");
	roiManager("select", j + 1);
	run("Plot Profile");
	run("Select None");
	Plot.addFromPlot(PlotFileListName, 0);
	Plot.addFromPlot(PlotFileListDup, 0);
	close("*");	
}

function ResultsName(FileList){	
	j = 0;
	Plot.show();
	Plot.showValues();
	Table.renameColumn("X0", "pixels")
	for(i = 0; i < FileList.length; i++) {
		FileListName = split(FileList[i], ".");
		GetRenameVertical = "Y" + j;
		RenameVertical = FileListName[0] + "_ver";
		Table.renameColumn(GetRenameVertical, RenameVertical);
		RenameWidth = FileListName[0] + "_wid";
		j = j + 1;
		GetRenameWidth = "Y" + j;
		Table.renameColumn(GetRenameWidth,	RenameWidth);
		j = j + 1;
	}
}

function ResultsCalculation(FileList){
	ResultsWid = newArray();
	ResultsVer = newArray();
	AllResults = newArray();
	DistanceResults = newArray();
	root2 = Math.sqrt(2);
	l = 0;
	j = 0;
	jadge = 0;
	for (i = 0; i < FileList.length; i++){
//テーブルの列ラベル取得
		FileListName = split(FileList[i], ".");
		RenameWidth = FileListName[0] + "_wid";
		RenameVertical = FileListName[0] + "_ver";
//データ処理
		ResultsVer[i] = WidVerCalculation(l, jadge, RenameWidth, DistanceResults);
		ResultsWid[i] = WidVerCalculation(l, jadge, RenameVertical, DistanceResults);
		AllResults[j] = (-ResultsWid[i] + ResultsVer[i]) / root2;
		j = j + 1;
		AllResults[j] = (-ResultsWid[i] - ResultsVer[i]) / root2;
		j = j + 1;
	}
	return AllResults;
}

function WidVerCalculation(l, jadge, RenameWidth, DistanceResults){
//列のデータを取得
	ColumnData = Table.getColumn(RenameWidth);
	ResultsData = Array.getStatistics(ColumnData, min, max);
	ResultsAve = (max + min) / 2;
//閾値(最大と最小の平均)をもとに計算
	for (j = 0; j < ColumnData.length; j++) {
		if (ColumnData[j] > ResultsAve && jadge == 0){
			ResultsPixelsBF = j - 1;
			ResultsValuesBF = ColumnData[j - 1];
			ResultsPixelsAF = j;
			ResultsValuesAF = ColumnData[j];
			LargeHeight = ResultsValuesAF - ResultsValuesBF;
			SmallHeight = ResultsAve - ResultsValuesBF;
			Distance =  SmallHeight / LargeHeight;
			DistanceResults[l] = Distance + ResultsPixelsBF;
			l = l + 1;
			jadge = jadge + 1;
		}
		else if(ColumnData[j] < ResultsAve && jadge == 1){
			ResultsPixelsBF = j - 1;
			ResultsValuesBF = ColumnData[j - 1];
			ResultsPixelsAF = j;
			ResultsValuesAF = ColumnData[j];
			LargeHeight = ResultsValuesAF - ResultsValuesBF;
			SmallHeitht = ResultsAve - ResultsValuesBF;
			Distance =  SmallHeitht / LargeHeight;
			DistanceResults[l] = Distance + ResultsPixelsBF;
			l = l + 1;
			jadge = jadge - 1;
		}
	}
	l = 0;
	LeftLength = DistanceResults[3] - DistanceResults[2];
	RightLength = DistanceResults[5] - DistanceResults[4];
	MisAlignmentImages = LeftLength - RightLength;
//ピクセルの値に応じて数値を変更してください
	MisAlignmentPixels = MisAlignmentImages * 0.63;
	return MisAlignmentPixels;
}

function AllResultsCalculation(FileList, AllResults){
	j = 0;
	FileListRename = newArray();
	for (i = 0; i < FileList.length ; i++) {
		FileListName = split(FileList[i], ".");
		FileListRename[j] = FileListName[0] + "_wid";
		j = j + 1;
		FileListRename[j] = FileListName[0] + "_ver";
		j = j + 1;
	}
	Table.setColumn("ファイル名", FileListRename);
	Table.setColumn("結果", AllResults);
}
main()