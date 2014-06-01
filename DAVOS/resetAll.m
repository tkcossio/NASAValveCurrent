function resetAll( hObject, eventData)
%Function to update plots after a reset.
hParent = getParentFigure(hObject);

dataHandler = getappdata(hParent, 'dataHandler');
fileInfo = getappdata(hParent, 'fileInfo');

delete(dataHandler)
dataHandler = [];

set(fileInfo.h_dataDirectoryInfo, 'String', '<Data Directory>...');
set(fileInfo.h_dataInfo, 'String', '<Information on the data...>');

setappdata(hParent, 'dataHandler', dataHandler);

end

