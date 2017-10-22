function [tau,MSD,MSD_vec]=DWS_Analysis(t,data,varargin)
% DWS_Analysis Estimation of MSD and G* from DWS autocorrelation
% data
%
% [MSD,G,MSD_vec,G_vec]=DWS_Analysis(t,data) calculates the MSD and complex
%   modulus G* from the autocorrelation function ICF obtained in a DWS
%   experiment, using the inversion relation and Evans scheme for inverting
%   the MSD into the complex modulus G. The measurement setup is assumed to 
%   be a DWS Rheolab (LS instruments)
%  
%  DATA can be a matrix containing several signals (one per column, all the same length).
%  MSD_vec is the set of all the calculated MSDs.
%  G_vec is the set of all the calculated Gs.

% [MSD,G,MSD_vec,G_vec]=DWS_Analysis(t,data,'PropertyName',PropertyValue)
%  permits to set the value of PropertyName to PropertyValue.
%  Admissible Properties are:
%       T       -   Temperature (default = 298 K)
%       eta     -   Solvent viscosity (default = 0.8872 cP)
%       n       -   Solvent refractive index (default = 1.33)
%       tail    -   Fit times for tail characterization (default =
%       [0,0] i.e. no tail correction)


% CREATED: Alessio Caciagli, University of Cambridge, October 2017
 T = 298;
for n = 1:2:length(varargin)
    if strcmpi(varargin{n},'T')
        T = varargin{n+1};
    end
end
 eta = 0.0008872;
for n = 1:2:length(varargin)
    if strcmpi(varargin{n},'eta')
        eta = varargin{n+1};
    end
end
 n = 1.33;
for i = 1:2:length(varargin)
    if strcmpi(varargin{i},'n')
        n = varargin{i+1};
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
lambda = 685*10^(-9); %Laser wavelength
L = 2e-3; %Cuvette thickness
l_star = 401.87e-6; %Transport mean free path
k0 = 2*pi*n/lambda;
R = 115e-9; %Bead radius

%% g1(tau) calc. and multiexponential fit to g1(tau) (for smoothness)

alpha = 1e-2;
I_vec = zeros(100,size(data,2));

for j = 1:size(data,2)
    
    %Delete first 2 points (usually noise) & format data
    Time_ToFit = t(3:end);
    ACF_ToFit = data(3:end,j);
    if all(tail)
        tailFit = ACF_ToFit(Time_ToFit > tail(1) & Time_ToFit < tail(2));
        tailFit = mean(tailFit);
        ACF_ToFit = ACF_ToFit - tailFit;
    end
    CritPts = find(ACF_ToFit< 0.1*ACF_ToFit(1));
    tTemp = Time_ToFit(1:CritPts(1));
    
    %g1(tau) calculation with  optional tail treatment (least-Squares)
    if all(tail)
        dataTempLog = log(ACF_ToFit(1:CritPts));
        A = [ones(length(tTemp),1),tTemp,tTemp.^2];
        Coeff = A\dataTempLog;
        beta = exp(Coeff(1));
    else
        beta = 1;
    end
    dataTemp = sqrt(ACF_ToFit(1:CritPts))/sqrt(beta);

    %CONTIN loop run
    coarse_s = logspace(-6,-1,10)';
    coarse_g = ones(size(coarse_s));
    [coarse_g,~,~] = CONTIN_Rilt(tTemp,dataTemp,coarse_s,coarse_g,alpha,'logarithmic',100,[],[],[],[],[]);
    for i = 2:10
        s = logspace(-6,-1,i*10)';
        g0 = interp1(coarse_s,coarse_g,s,'linear');
        [g,~,~] = CONTIN_Rilt(tTemp,dataTemp,s,g0,alpha,'logarithmic',100,[],[],[],[],[]);
        coarse_g = g;
        coarse_s = s;
    end
    I_vec(:,j) = g;
end
close all
I_vec = I_vec./sum(I_vec,1);
%%
tFit = logspace(-6,-1)';
dataFit = zeros(length(tFit),size(data,2));
for i = 1:length(tFit)
    dataFit(i,:) = sum(I_vec.*exp(-tFit(i)./s),1);
end
%% MSD calculation
g1_an = @(x) (L/l_star + 4/3)/(5/3) * (sinh(x) + (2/3)*x*cosh(x)) / ...
    ((1 + (4/9)*x^2)*sinh((L/l_star)*x) + (4/3)*x*cosh((L/l_star)*x));
x0 = sqrt(-3*log(dataFit))./(L/l_star);
xAcc = zeros(size(x0));

for i = 1:length(x0)
    for j = 1:size(x0,2)
        fun = @(x) g1_an(x) - dataFit(i,j);
        xAcc(i,j) = fzero(fun,x0(i,j));
    end
end

tau = tFit;
MSD_vec = 0.33 * (xAcc + x0).^2/k0^2;
MSD = mean(MSD_vec,2);
%MSDFit_Spl = csape(tFit',MSD_vec');
% %% Microrheology
% t_Micro = (1e-6:1e-6:1)';
% MSD_Micro = fnval(t_Micro,MSDFit_Spl)';
% if size(MSD_Micro,1)==1
%     MSD_Micro=MSD_Micro';
% end
% Jfactor = 1 / (kB*T/(pi*R));
% [omega,G,~,G_vec]=MSDtoG_Evans_oversampling(t_Micro,MSD_Micro,1e+6,'Jfactor',Jfactor);



