% Data preparation for microrheology with QPD. Imports data from multiple QPD
% signals (csv files from PicoScope).
% Output format: 
% - size*2*n matrix (size is number of timesteps, n is number
%   of series)
% - First n columns are X signal, last n columns are Y signal

% Clear everything
clear all; 
close all;
clc;

%Input: enter directory name
folder_name=uigetdir('L:\Microrheology\DNA_Hydrogels\1,0%_DNA\25C\1MHz');
listings=dir([folder_name,'/','*.csv']);
numFiles = length(listings);

%Add imports to a cell array
dataTot = cell(1,numFiles);

parfor fileNum = 1:numFiles
    fileName = listings(fileNum).name;
    dataTot{fileNum} = QPD_import_PicoScope([folder_name,'/',fileName],3);
end


%Get minimum array size (if there are different lengths)
%Resize the array
dataSize = min(cellfun('length',dataTot));
for k=1:length(dataTot)
    dataTot{k} = dataTot{k}(1:dataSize,:);
end


%Convert to array & shuffle to account for indexing
dataTot = cell2mat(dataTot);
dataTot = [dataTot(:,1:2:end),dataTot(:,2:2:end)];

disp('Data imported. Saving...')

%Save array in mat form in parent directory
[path,name]=fileparts(folder_name);
save([path,'/',name,'.mat'],'dataTot','-v6')


disp('Done!');

