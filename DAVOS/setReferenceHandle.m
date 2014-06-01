function setReferenceHandle( hObject, eventData)
%Function to remove outliers from time series data.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');

dataHandler.setReference(gco);

setappdata(hParent, 'dataHandler', dataHandler);

end