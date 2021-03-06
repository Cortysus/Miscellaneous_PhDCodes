function [acf,tau,acf_err,acf_vec]=CoarseGrainACFfile(file,dt,S,varargin)

% CoarseGrainACF   Autocorrelation function with coarse-graining, file
% version
%
% [ACF,TAU,ACFerr,ACFvec]=CoarseGrainACFfile(file,DT,S) calculates the 
%   auto-correlation function (ACF) of a 2D data series using a
%   multiple-tau correlator, a method for the calculation of time correlaton
%   functions with coarse graining (Ramirez et al., 2010). It reads a file
%   line-by-line (useful for large files for which loading could be
%   significatively expensive)
%
%   FILE is a csv text file containing one time series and two signals (one per column, all the same length).
%       N.B! The first column is supposed to be reserved for the time
%       signal and it is thus ignored!
%   DT is the time interval at which the signal is sampled.
%   S is the number of arrays in the correlator (see Ramirez et al. (2010))
%   TAU are the values of the time delays.
%   ACFerr is the error calculated as standard deviation of the ACF value.
%   ACFvec is the set of all ACF calculated.
%
% [ACF,TAU,ACFerr,ACFvec]=CoarseGrainACFfile(file,DT,S,'PropertyName',PropertyValue) permits
%   to set the value of PropertyName to PropertyValue.
%   Admissible Properties are:
%       P           -   Block size for coarse-graining (default = 16)   
%       M           -   Coarse-graining factor (default = 2)
%       TauMax      -   Maximum delay to be calcualted (default = +Inf)

% CREATED: Alessio Caciagli, University of Cambridge, February 2017


%%%%%% Main %%%%%%


%Coarse-graining parameter (to be defined in the sampling stage)
P=16;
M=2;
for n = 1:2:length(varargin)
    if strcmpi(varargin{n},'P')
        P = varargin{n+1};
    elseif strcmpi(varargin{n},'M')
        M = varargin{n+1};
    end
end

%Initialize
if mod(P,M)~=0
    error('Ratio P/M is not an integer!')
end

%Array initialization
Level = zeros(S,P,2);
CorrGL = zeros(S,P,2);
Accum = zeros(S,2);

Count = zeros(S,P);
CountAccum = zeros(S,1);
TimesGL=zeros(S,P);

% Open the file & check on emptiness 
fid = fopen(file);
finfo = dir(file);
fsize = finfo.bytes;
if fsize == 0
    error('Error when reading file: file is empty.');
end

%Sample: update base level with data points
VX = fscanf(fid, '%*f, %f, %f',[1,2]);
while ~feof(fid)    
    UpdateLevel(1,VX);
    UpdateCorrCount(1);
    UpdateAccum(1,VX);
    VX = fscanf(fid, '%*f, %f, %f',[1,2]);
end

%Finalize: normalize and calculate times
for i=1:S
    %Calculate times
    CalculateTimes(i);
end

%Scaled autocorrelations on number of observations
CorrGL=(CorrGL./repmat(Count,[1,1,2]));

%Discard empty levels & condense levels into a single array
id=~isnan(CorrGL(:,:,1));
tau=TimesGL(id);
acf_vec = zeros(length(tau),2);
for i=1:2
    tempCorr=squeeze(CorrGL(:,:,i));
    acf_vec(:,i)=tempCorr(id);
end

%Apply correct sorting
[tau,id]=sort(tau);
acf_vec=acf_vec(id,:);

% Maximum delay (to be defined in the finalize stage)
taumax = +Inf;
for n = 1:2:length(varargin)
    if strcmpi(varargin{n},'taumax')
        taumax = varargin{n+1};
    end
end

if isfinite(taumax)
    tau=tau(tau<taumax);
    acf_vec = acf_vec(1:length(tau),:);
end


%Normalization
acf_vec=acf_vec./acf_vec(1,:);
acf = mean(acf_vec,2);
acf_err = std(acf_vec,0,2);

%Close the file
fclose(fid);


%%%%%% Subroutines %%%%%%

%1. UpdateLevel:
%   Enter a new data points in the array i
    function UpdateLevel(i,x)
        %i is the level to be updated
        %x is the element to insert
        
        Level(i,2:P,:) = Level(i,1:P-1,:);
        Level(i,1,:) = x;
        
    end

%2. UpdateCorrCount:
%   Updates the corr function of level i
    function UpdateCorrCount(i)
        %i is the level to be updated
        
        if i == 1
            start=1;
        else
            start=P/M + 1;
        end
        
        CorrGL(i,start:end,:) = CorrGL(i,start:end,:) + Level(i,1,:).*Level(i,start:end,:);
        Count(i,start:end) = Count(i,start:end) + 1;
        
        
    end

%3. UpdateAccum:
%   Updates the accumulator of level i
    function UpdateAccum(i,x)
        %i is the level to be updated
        %x is the element to insert
        Accum(i,:) = Accum(i,:) + x;
        CountAccum(i) = CountAccum(i) + 1;
        
        if CountAccum(i) == M
            %Push coarse-grained data to the next level
            UpdateLevel(i+1,Accum(i,:)/M);
            UpdateCorrCount(i+1);
            UpdateAccum(i+1,Accum(i,:)/M);
            %Reset counters of current level
            Accum(i,:)=0;
            CountAccum(i)=0;
        end
    end

%4. CalculateTimes:
%   Calculate the time values of level i according to the coarse-graining procedure
    function CalculateTimes(i)
        %i is the level of interest
        if i == 1
            start=1;
        else
            start=P/M + 1;
        end
        
        TimesGL(i,start:end) = dt*M^(i-1)*(start-1:P-1);
    end
end