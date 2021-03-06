function [tau,MSD,ACF,tau_Long,ACF_Long,MSD_vec,ACF_vec,I_vec]=DLS_CRIEAnalysis_Simple(t,data,varargin)
% DLS_CRIEAnalysis_Simple
% Estimation of g1 and MSD from DLS autocorrelation
% data using a Constrained Regularization of Integral Equations (CRIE)
% method
%
% [tau,MSD,ACF,MSD_vec,ACF_vec]=DLS_CRIEAnalysis_Simple(t,data) calculates the
%   autocorrelation function g1 and the MSD from the autocorrelation
%   function ICF obtained in a DLS experiment, using the inversion relation.
%   The measurement setup is assumed to be a ZetaSizer APS Nano (Malvern).
%
%  DATA can be a matrix containing several signals (one per column, all the same length).
%  MSD_vec is the set of all the calculated MSDs.
%  ACF_vec is the set of all the calculated ACFs.
%  I_vec is the set of all the calculated g(s) coefficients. 

% [tau,MSD,ACF,MSD_vec,ACF_vec]=DLS_CRIEAnalysi_Simple(t,data,'PropertyName',PropertyValue)
%  permits to set the value of PropertyName to PropertyValue.
%  Admissible Properties are:
%       T       -   Temperature (default = 298 K)
%       eta     -   Solvent viscosity (default = 0.8872 cP)
%       n       -   Solvent refractive index (default = 1.33)
%       R       -   Bead radius (default = 115 nm)
%       beta    -   Calculation of coherence factor (default = 1)
%       Ng      -   Number of grid points for CRIE routine (default = 161)
%       cut     -   ACF cut value for fit (0<cut<1) (default = 0.1)
%       Nnoise  -   Number of initial noisy points (default = 6)
%       tail    -   Fit times for tail characterization (default =
%                   [0,0] i.e. no tail correction)
%       tExt    -   Max time lag for tail extension of the g1 (default =
%                   10*t_end)

%   ADVANCED:
%       gLims       -   Limits of g for CRIE routine
%       AlphaLims   -   Limits of Alpha for CRIE routine
%       LLims       -   Limits of L-curve corner for CRIE routine



% CREATED: Alessio Caciagli, University of Cambridge, October 2017
n = 1.33;
for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'n')
        n = varargin{i+1};
    end
end
R = 115e-9;
for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'R')
        R = varargin{i+1};
    end
end
beta = 1;
for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'beta')
        beta = varargin{i+1};
    end
end
Ng = 161;
for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'Ng')
        Ng = varargin{i+1};
    end
end
cut = 0.1;
for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'cut')
        cut = varargin{i+1};
    end
end
Nnoise = 6;
for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'Nnoise')
        Nnoise = varargin{i+1};
    end
end
tail = [0,0];
for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'tail')
        tail = varargin{i+1};
    end
end

%% Constants
kB = 1.38*10^(-23);
lambda = 633*10^(-9);
theta = 173*2*pi/360;
q = 4*pi*n*sin(theta/2)/lambda;

%% g1(tau) calc. and fit to g1(tau) (for smoothness)

I_vec = ones(Ng,size(data,2));
ACF_vec = zeros(size(t,1),size(data,2));
ACF_vec_Long = zeros(size(t,1),size(data,2));
for j = 1:size(data,2)
    
    %Delete first Nnoise points (usually noise) & format data
    Time_ToFit = t(Nnoise+1:end);
    ACF_ToFit = data(Nnoise+1:end,j);
    if all(tail)
        tailFit = ACF_ToFit(Time_ToFit > tail(1) & Time_ToFit < tail(2));
        tailFit = mean(tailFit);
        ACF_ToFit = (ACF_ToFit - tailFit)/(1+tailFit);
    end
    CritPts = find(ACF_ToFit< cut*ACF_ToFit(1));
    tTemp = Time_ToFit(1:CritPts(1));
    
    %g1(tau) calculation with  optional head treatment (least-Squares)
    switch beta
        case 1
            dataTempLog = log(ACF_ToFit(1:10));
            A = [ones(length(tTemp(1:10)),1),tTemp(1:10),tTemp(1:10).^2];
            Coeff = A\dataTempLog;
            beta = exp(Coeff(1));
            
        case 0
            beta = 1;
            
        otherwise
            error('Error: Unrecognized value for beta.');
            
    end
    dataTemp = sqrt(ACF_ToFit(1:CritPts(1)))/sqrt(beta);
    
    clear DLS_Input
    %Input parameters for CRIE run
    DLS_Input.Iquad = 2;
    DLS_Input.Igrid = 2;
    DLS_Input.Kernel = 1;
    DLS_Input.Nnq = 0;
    DLS_Input.Anq = 0;
    DLS_Input.Neq = 0;
    DLS_Input.Aeq = 0;
    DLS_Input.Nneg = 1;
    DLS_Input.Ny0 = 1;
    %DLS_Input.iwt = 1;        % No weights
    DLS_Input.iwt = 4;       % User weights
    DLS_Input.wt = dataTemp.^2;
    DLS_Input.Nalpha = 40;
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i},'g_lims')
            DLS_Input.g_lims = varargin{i+1};
        end
    end
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i},'alpha_lims')
            DLS_Input.alpha_lims = varargin{i+1};
        end
    end
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i},'l_lims')
            DLS_Input.l_lims = varargin{i+1};
        end
    end
    
    %CRIE run
    [s,~,yfit,~,info] = CRIE(tTemp*1e-6,dataTemp,Ng,0,DLS_Input);
    I_vec(:,j) = s;
    ACF_vec(1:length(yfit),j) = yfit;

    %Tail prolungation
    tExt = 10*tTemp(end);
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i},'tExt')
            tExt = varargin{i+1};
        end
    end
    tLong = logspace(log10(tTemp(1)),log10(tExt),length(tTemp))';
    ALong = CRIE_Kernel(tLong*1e-6,info.g,info.c,info.Kernel,info.grid);
    yLong = ALong * s;
    ACF_vec_Long(1:length(yLong),j) = yLong;
    
    
end
ACF_vec(size(tTemp)+1:end,:) = [];
ACF_vec_Long(size(tLong)+1:end,:) = [];
ACF = mean(ACF_vec,2);
ACF_Long = mean(ACF_vec_Long,2);

%% MSD calculation
tau = tTemp;
tau_Long = tLong;
MSD_vec = (6/q^2)*(-log(ACF_vec));
MSD = mean(MSD_vec,2);