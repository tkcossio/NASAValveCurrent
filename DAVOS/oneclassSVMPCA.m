function oneclassSVMPCA( hObject, eventData)
%Function to standardize data in each time series.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');
plottingInfo = getappdata(hParent, 'plottingInfo');
resultsInfo = getappdata(hParent, 'resultsInfo');

dataHandler.runOneClassSVM('PCA', plottingInfo.h_auxiliary, resultsInfo.h_resultsText);

setappdata(hParent, 'dataHandler', dataHandler);

end