function scatterPlot( hObject, eventData)
%Function to standardize data in each time series.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');
plottingInfo = getappdata(hParent, 'plottingInfo');
resultsInfo = getappdata(hParent, 'resultsInfo');

if (isempty(dataHandler.idx_reference))
   warndlg(sprintf('No reference defined! \n Right-click on a trace to define a reference.'))   
   return
else
    dataHandler.drawScatter(plottingInfo.h_auxiliary, resultsInfo.h_resultsText);
end

setappdata(hParent, 'dataHandler', dataHandler);

end