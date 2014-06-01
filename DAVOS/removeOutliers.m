function removeOutliers( hObject, eventData)
%Function to remove outliers from time series data.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');

dataHandler.removeOutliersAllSeries();

setappdata(hParent, 'dataHandler', dataHandler);

updatePlots(hObject, eventData);

end