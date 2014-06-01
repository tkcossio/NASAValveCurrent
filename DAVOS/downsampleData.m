function downsampleData( hObject, eventData)
%Function to downsample time series data.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');

dataHandler.downsampleAllSeries(20);

setappdata(hParent, 'dataHandler', dataHandler);

updatePlots(hObject, eventData);

end
