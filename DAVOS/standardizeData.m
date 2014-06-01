function standardizeData( hObject, eventData)
%Function to standardize data in each time series.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');

dataHandler.standardizeAllSeries();

setappdata(hParent, 'dataHandler', dataHandler);

updatePlots(hObject, eventData);

end