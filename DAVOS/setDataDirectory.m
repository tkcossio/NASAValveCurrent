function setDataDirectory( hObject, eventData)
%Function to set data directory for GUI.
hParent = getParentFigure(hObject);

%Get appdata
dataHandler = getappdata(hParent, 'dataHandler');
fileInfo = getappdata(hParent, 'fileInfo');

%Reset GUI if some data has been previously loaded.
if (~isempty(dataHandler))
    resetAll(hObject, eventData);
end

%Get data directory
targetfolder = 'C:\Users\cossitk1\Documents\MATLAB\TCpersonal\NASA_ValveCurrentData\';
if (~exist(targetfolder, 'dir'))
    targetfolder = uigetdir('C:\Users\cossitk1\Documents\MATLAB\TCpersonal\');
    if (targetfolder == 0)
        return
    end
end

%Initialize dataHandler
dataHandler = dataObjectHandler(targetfolder);

%Update text displays
set(fileInfo.h_dataDirectoryInfo, 'String', dataHandler.data_dir);
set(fileInfo.h_dataInfo, 'String', dataHandler.textDescription);

%Store appdata
setappdata(hParent, 'dataHandler', dataHandler);

%Show time series in main plot
updatePlots(hObject, eventData);

end