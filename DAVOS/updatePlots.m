function updatePlots( hObject, eventData)
%Function to update plots after a reset.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');
plottingInfo = getappdata(hParent, 'plottingInfo');

dataHandler.plotSeries(plottingInfo.h_timeseries);

setappdata(hParent, 'dataHandler', dataHandler);

end

