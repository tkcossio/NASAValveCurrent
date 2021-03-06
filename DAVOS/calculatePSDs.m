function calculatePSDs( hObject, eventData)
%Function to standardize data in each time series.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');
plottingInfo = getappdata(hParent, 'plottingInfo');

dataHandler.calculateSeriesPSDs(plottingInfo.h_auxiliary);

setappdata(hParent, 'dataHandler', dataHandler);

end