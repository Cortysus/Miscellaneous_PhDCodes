%Script to plot the ACFs and MSDs data from DLS_Analysis 
%Input data are variables with names
% - tau
% - tau_Long
% - ACF
% - ACF_Long
% - MSD

%Assumes decreasing temperatures with Trend = -1
%Assumes increasing temperatures with Trend = +1

clear variables
close all

NT = 8; %Number of temperatures
Tin = 60;
Tstep = 5;
Id = 'SNR';

Trend = -1;

PathName = uigetdir;
PathName = [PathName,'/'];
FileList = dir([PathName,Id,'_T*']);
if size(FileList,1) ~= NT
    error('Wrong datafile length!');
end
%% Constants 
n = 1.33;
lambda = 633*10^(-9);
theta = 173*2*pi/360;
q = 4*pi*n*sin(theta/2)/lambda;
kB = 1.38*10^(-23);
A = 2.414e-5;
B = 247.8;
C = 140;
eta = @(x) A * 10.^(B/((x+273.15) - C));
D = @(x) kB*(x + 273.15)/(3*pi*230e-9*eta(x));

%% Preliminary: renormalization & colormaps
fP = ones(NT,1);
fM = ones(NT,1);
for i=1:NT
    load([PathName,Id,'_T_',num2str(Tin + Trend*(i-1)*Tstep)]);
    %fP(i) = 6*D(Tin + Trend*(i-1)*Tstep)*tau(1)/(sqrt(i));
    %fP(i) = -fP(i)*(q^2/6)/log(ACF(1));
end
initialColorOrder = get(gca,'ColorOrder');
newDefaultColors = flip(cool(NT));
%fP(2) = fP(2)*1.2;
%fP(4) = fP(4)*0.85;
%fP = 0.5*fP;
%% ACF plot
figure(1)
subplot(1,2,1)
set(gca, 'ColorOrder', newDefaultColors, 'NextPlot', 'replacechildren');
hold on

for i=1:NT
    load([PathName,Id,'_T_',num2str(Tin + Trend*(i-1)*Tstep)]);
    semilogx(tau_Long*1e-6,fM(i)*ACF_Long.^fP(i));
end
hold off
h=gca;
h.XScale='log';
xlabel('Time [s]')
ylabel('g_1 (\tau)')
legend(cellstr(int2str(linspace(Tin,Tin + Trend*(NT-1)*Tstep,NT)')))

%% MSD plot
figure(1)
subplot(1,2,2)
set(gca, 'ColorOrder', newDefaultColors, 'NextPlot', 'replacechildren');
hold on
for i=1:NT
    load([PathName,Id,'_T_',num2str(Tin + Trend*(i-1)*Tstep)]);
    loglog(tau*1e-6,1e+12*(6/q^2)*(-log(fM(i).*ACF.^fP(i))),'*');
end
loglog(tau*1e-6,1e+12*6*D(Tin)*tau*1e-6,'k--')
hold off
h=gca;
h.XScale='log';
h.YScale='log';
xlabel('Time [s]')
ylabel('MSD [um^2]')
legend(cellstr(int2str(linspace(Tin,Tin + Trend*(NT-1)*Tstep,NT)')),'Location','southeast')
