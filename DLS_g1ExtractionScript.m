%Extract correlation curves from DLS data file
%Batch version
%Assumes that field names are:
%   - t
%   - data
%   - SNR

%Assumes decreasing temperatures

clear variables

NM = 5; %Number of measurements for each temperature
NT = 9; %Number of temperatures
Tin = 50;
Tstep = 3;

uiopen

if size(data,1) ~= NM*NT
    error('Wrong datafile length!');
end

for i=1:NT
    for j=1:NM
        [tau,MSD,ACF]=DLS_Analysis(t((i-1)*NM + j,:)',data((i-1)*NM +j,:)','T',273 + Tin - (i-1)*Tstep);
        save(['T_',num2str(Tin - (i-1)*Tstep),'_',num2str(j)],'tau','ACF','MSD');
    end
end
