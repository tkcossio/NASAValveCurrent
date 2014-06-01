function detectSalientFeatures(hObject, eventData)
%Function to detect salient temporal features in a reference time series.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');
plottingInfo = getappdata(hParent, 'plottingInfo');

if (isempty(dataHandler.idx_reference))
   warndlg(sprintf('No reference defined! \n Right-click on a trace to define a reference.'))   
   return
else
    dataHandler.detectSalientFeaturesInReference(plottingInfo.h_auxiliary);    
end

setappdata(hParent, 'dataHandler', dataHandler);

end