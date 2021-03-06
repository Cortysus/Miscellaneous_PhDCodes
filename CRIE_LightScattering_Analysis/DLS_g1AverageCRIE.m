%% DLS_g1AverageCRIE

%Script to select the ACF with best SNR or average the ACFs from the data from DLS_Analysis if multiple
%files are present.

%Input data are variables with names
% - tau (output from DLS_Analysis)
% - ACF (output from DLS_Analysis)
% - tau_Long (output from DLS_Analysis)
% - ACF_Long (output from DLS_Analysis)
% - SNR (raw from acquisition data)

%Assumes decreasing temperatures with Trend = -1
%Assumes increasing temperatures with Trend = +1

clear variables
close all

NM = 1; %Number of measurements for each temperature
NT = 8; %Number of temperatures
Tin = 60;
Tstep = 5;

Trend = -1;
Avg = 0;

[FileName,PathName] = uigetfile;
load([PathName,FileName]);

if size(data,1) ~= NM*NT
    error('Wrong datafile length!');
end

C = cell(NT,NM);
%% Matrix building
for i=1:NT
    for j=1:NM
        load([PathName,'T_',num2str(Tin + Trend*(i-1)*Tstep),'_',num2str(j)]);
        C{i,j} = [tau,ACF];
    end
end
if Avg == 1
    % Extraction of min and max times
    minT = cellfun(@(x) min(x(:,1)),C);
    minT = max(minT,[],2);
    maxT = cellfun(@(x) max(x(:,1)),C);
    maxT = min(maxT,[],2);
    
    tFit = struct;
    for i = 1:NT
        for j=1:NM
            tFit(i,j).time = logspace(log10(minT(i)),log10(maxT(i)),100)';
        end
    end
    % Data spline interpolations
    data_spline=cellfun(@(x) csape(x(:,1)',x(:,2)'),C);
    ACF_vec=arrayfun(@(x,y) fnval(x.time,y),tFit,data_spline,'UniformOutput',false);
    ACF_vec = permute(reshape([ACF_vec{:}], [], size(ACF_vec, 1), size(ACF_vec, 2)), [1 2 3]);
    SNR_mat = reshape(SNR,[NM,NT])';
    SNR_mat = permute(repmat(SNR_mat,1,1,100),[3,1,2]);
    ACF_avg = sum(ACF_vec.*SNR_mat,3)./sum(SNR_mat,3);
    % Fitting the weighted average ACF
    for i = 1:NT
        [tau,MSD,ACF]=DLS_CRIEAnalysis(tFit(i,1).time*1e6,ACF_avg(:,i).^2,'T',273 + Tin + Trend*(i-1)*Tstep,'Ng',161,'beta',0,'batch',0);
        save([PathName,'Avg_T_',num2str(Tin + Trend*(i-1)*Tstep)],'tau','ACF','MSD');
    end
else
    for i = 1:NT
        ACF_T = C(i,:);
        SNR_T = SNR((i-1)*NM + (1:NM));
        [~,I] = max(SNR_T);
        load([PathName,'T_',num2str(Tin + Trend*(i-1)*Tstep),'_',num2str(I)]);
        save([PathName,'SNR_T_',num2str(Tin + Trend*(i-1)*Tstep)],'tau','ACF','tau_Long','ACF_Long','MSD');
    end
end





