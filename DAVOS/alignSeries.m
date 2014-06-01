function alignSeries(hObject, eventData)
%Function to detect salient temporal features in a reference time series.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');
plottingInfo = getappdata(hParent, 'plottingInfo');

if (isempty(dataHandler.temporalFeatureList))
   warndlg(sprintf('No temporal features have been extracted! \n Select a reference and detect salient features.'))   
   return
else
    dataHandler.alignSeriesToReference();
end

setappdata(hParent, 'dataHandler', dataHandler);

updatePlots(hObject, eventData);

end